require('dotenv').config();
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const { createClient } = require('@supabase/supabase-js');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { requireUser, getSupabaseAdmin } = require('./middlewares/auth');
const requireAdmin = require('./middlewares/adminAuth');

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;
const supabaseAuth = SUPABASE_URL && SUPABASE_ANON_KEY ? createClient(SUPABASE_URL, SUPABASE_ANON_KEY) : null;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const genAI = GEMINI_API_KEY ? new GoogleGenerativeAI(GEMINI_API_KEY) : null;

function requireConfig(res) {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    res.status(503).json({ error: 'اتصال Supabase روی سرور تنظیم نشده است.' });
    return false;
  }
  return true;
}

app.get('/', (_, res) => res.json({ message: 'Bazarek backend is running', version: '2.0.0' }));
app.get('/api/health', (_, res) => res.json({ ok: true }));

app.post('/api/auth/register', async (req, res) => {
  try {
    if (!requireConfig(res)) return;
    const { email, password, full_name = '', shop_name = '', phone = '' } = req.body || {};
    if (!email || !password) return res.status(400).json({ error: 'ایمیل و رمز عبور الزامی است.' });
    if (password.length < 8) return res.status(400).json({ error: 'رمز عبور باید حداقل ۸ کاراکتر باشد.' });
    const { data, error } = await supabaseAuth.auth.signUp({
      email: email.trim().toLowerCase(),
      password,
      options: { data: { full_name: full_name.trim(), shop_name: shop_name.trim(), phone: phone.trim() } }
    });
    if (error) return res.status(400).json({ error: error.message });
    if (!data.session) return res.json({ requiresEmailConfirmation: true, message: 'حساب ساخته شد. اگر تأیید ایمیل فعال باشد، ایمیل تأیید را باز کنید.' });
    res.status(201).json({ token: data.session.access_token, user: data.user });
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در ساخت حساب.' }); }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    if (!requireConfig(res)) return;
    const { email, password } = req.body || {};
    if (!email || !password) return res.status(400).json({ error: 'ایمیل و رمز عبور الزامی است.' });
    const { data, error } = await supabaseAuth.auth.signInWithPassword({ email: email.trim().toLowerCase(), password });
    if (error || !data.session) return res.status(401).json({ error: 'ایمیل یا رمز عبور اشتباه است.' });
    res.json({ token: data.session.access_token, user: data.user });
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در ورود.' }); }
});

app.get('/api/me', requireUser, async (req, res) => {
  try {
    const db = getSupabaseAdmin();
    const { data, error } = await db.from('profiles').select('*').eq('id', req.user.id).single();
    if (error) throw error;
    res.json(data);
  } catch (e) { res.status(500).json({ error: 'خطا در دریافت پروفایل.' }); }
});

app.patch('/api/me', requireUser, async (req, res) => {
  try {
    const { full_name, shop_name, phone, city } = req.body || {};
    const db = getSupabaseAdmin();
    const { data, error } = await db.from('profiles').update({ full_name, shop_name, phone, city, updated_at: new Date().toISOString() }).eq('id', req.user.id).select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { res.status(500).json({ error: 'خطا در ذخیره پروفایل.' }); }
});

app.post('/api/admin/login', (req, res) => {
  const { email, password } = req.body || {};
  if (!process.env.ADMIN_EMAIL || !process.env.ADMIN_PASSWORD || !process.env.ADMIN_SESSION_SECRET) return res.status(503).json({ error: 'تنظیمات امن پنل مدیریت روی سرور کامل نیست.' });
  if (String(email).trim().toLowerCase() !== String(process.env.ADMIN_EMAIL).trim().toLowerCase() || password !== process.env.ADMIN_PASSWORD) return res.status(401).json({ error: 'ایمیل یا رمز عبور ادمین اشتباه است.' });
  const token = jwt.sign({ role: 'admin', email }, process.env.ADMIN_SESSION_SECRET, { expiresIn: '8h' });
  res.json({ token });
});

app.get('/api/admin/products', requireAdmin, async (_, res) => {
  try {
    const db = getSupabaseAdmin();
    const { data, error } = await db.from('products').select('id,vendor_id,title,description,price,stock,category,image_url,is_active,created_at,updated_at').order('created_at', { ascending: false });
    if (error) throw error;
    res.json(data || []);
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در دریافت آگهی‌ها.' }); }
});

app.patch('/api/admin/products/:id/status', requireAdmin, async (req, res) => {
  try {
    const isActive = Boolean(req.body?.is_active);
    const db = getSupabaseAdmin();
    const { data, error } = await db.from('products').update({ is_active: isActive, updated_at: new Date().toISOString() }).eq('id', req.params.id).select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در تغییر وضعیت آگهی.' }); }
});

app.delete('/api/admin/products/:id', requireAdmin, async (req, res) => {
  try {
    const db = getSupabaseAdmin();
    const { error } = await db.from('products').delete().eq('id', req.params.id);
    if (error) throw error;
    res.json({ ok: true });
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در حذف آگهی.' }); }
});

app.get('/api/listings', async (req, res) => {
  try {
    const db = getSupabaseAdmin();
    let query = db.from('products').select('id,title,description,price,stock,category,image_url,created_at,vendor_id').eq('is_active', true).order('created_at', { ascending: false }).limit(100);
    const q = String(req.query.q || '').trim();
    const category = String(req.query.category || '').trim();
    if (q) query = query.or(`title.ilike.%${q}%,description.ilike.%${q}%`);
    if (category) query = query.eq('category', category);
    const { data, error } = await query;
    if (error) throw error;
    res.json(data || []);
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در دریافت آگهی‌ها.' }); }
});

app.get('/api/admin/stats', requireAdmin, async (_, res) => {
  try {
    const db = getSupabaseAdmin();
    const [{ count: users }, { count: products }] = await Promise.all([
      db.from('profiles').select('*', { count: 'exact', head: true }),
      db.from('products').select('*', { count: 'exact', head: true })
    ]);
    res.json({ users: users || 0, products: products || 0 });
  } catch (e) { res.status(500).json({ error: 'خطا در دریافت آمار.' }); }
});

app.get('/api/products', requireUser, async (req, res) => {
  try {
    const db = getSupabaseAdmin();
    const { data, error } = await db.from('products').select('*').eq('vendor_id', req.user.id).order('created_at', { ascending: false });
    if (error) throw error;
    res.json(data || []);
  } catch (e) { res.status(500).json({ error: 'خطا در دریافت محصولات.' }); }
});

app.post('/api/products', requireUser, async (req, res) => {
  try {
    const { title, price, cost_price = 0, description = '', category = '', image_url = '', stock = 0 } = req.body || {};
    if (!title || typeof title !== 'string') return res.status(400).json({ error: 'نام محصول الزامی است.' });
    const db = getSupabaseAdmin();
    const payload = { vendor_id: req.user.id, title: title.trim(), price: Math.max(0, Number(price) || 0), cost_price: Math.max(0, Number(cost_price) || 0), description: String(description), category: String(category), image_url: String(image_url), stock: Math.max(0, Math.trunc(Number(stock) || 0)) };
    const { data, error } = await db.from('products').insert([payload]).select().single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در ثبت محصول.' }); }
});

app.patch('/api/products/:id', requireUser, async (req, res) => {
  try {
    const allowed = ['title', 'price', 'cost_price', 'description', 'category', 'image_url', 'stock'];
    const payload = {};
    for (const key of allowed) if (req.body[key] !== undefined) payload[key] = req.body[key];
    if (payload.price !== undefined) payload.price = Math.max(0, Number(payload.price) || 0);
    if (payload.cost_price !== undefined) payload.cost_price = Math.max(0, Number(payload.cost_price) || 0);
    if (payload.stock !== undefined) payload.stock = Math.max(0, Math.trunc(Number(payload.stock) || 0));
    payload.updated_at = new Date().toISOString();
    const db = getSupabaseAdmin();
    const { data, error } = await db.from('products').update(payload).eq('id', req.params.id).eq('vendor_id', req.user.id).select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { res.status(500).json({ error: 'خطا در ویرایش محصول.' }); }
});

app.delete('/api/products/:id', requireUser, async (req, res) => {
  try {
    const db = getSupabaseAdmin();
    const { error } = await db.from('products').delete().eq('id', req.params.id).eq('vendor_id', req.user.id);
    if (error) throw error;
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: 'خطا در حذف محصول.' }); }
});

app.post('/api/generate-ad', requireUser, async (req, res) => {
  try {
    if (!genAI) return res.status(503).json({ error: 'سرویس هوش مصنوعی روی سرور تنظیم نشده است.' });
    const { productName, description, language = 'fa' } = req.body || {};
    if (!productName) return res.status(400).json({ error: 'نام محصول الزامی است.' });
    const languageName = language === 'ps' ? 'پشتو افغانستان' : language === 'en' ? 'English' : 'دری افغانستان';
    const model = genAI.getGenerativeModel({ model: process.env.GEMINI_MODEL || 'gemini-1.5-flash' });
    const prompt = `برای یک فروشنده در افغانستان یک آگهی کوتاه، واقعی و جذاب به ${languageName} بنویس. نام محصول: ${productName}. توضیحات: ${description || 'بدون توضیح'}. ادعای دروغ و اغراق نکن.`;
    const result = await model.generateContent(prompt);
    res.json({ adText: result.response.text() });
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در تولید آگهی.' }); }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Bazarek backend running on ${PORT}`));
