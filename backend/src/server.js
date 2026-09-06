require('dotenv').config();
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const { createClient } = require('@supabase/supabase-js');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const multer = require('multer');
const crypto = require('crypto');
const { requireUser, getSupabaseAdmin } = require('./middlewares/auth');
const requireAdmin = require('./middlewares/adminAuth');

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });
const IMAGE_BUCKET = 'listing-images';

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
    const db = getSupabaseAdmin();
    const normalizedEmail = email.trim().toLowerCase();
    const { data: created, error } = await db.auth.admin.createUser({
      email: normalizedEmail,
      password,
      email_confirm: true,
      user_metadata: { full_name: full_name.trim(), shop_name: shop_name.trim(), phone: phone.trim() }
    });
    if (error) return res.status(400).json({ error: error.message });
    const user = created.user;
    await db.from('profiles').upsert({ id: user.id, full_name: full_name.trim(), shop_name: shop_name.trim(), phone: phone.trim() }, { onConflict: 'id' });
    const { data: signedIn, error: loginError } = await supabaseAuth.auth.signInWithPassword({ email: normalizedEmail, password });
    if (loginError || !signedIn.session) return res.status(500).json({ error: 'حساب ساخته شد اما ورود خودکار انجام نشد. دوباره وارد شوید.' });
    res.status(201).json({ token: signedIn.session.access_token, user });
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در ساخت حساب.' }); }
});

app.post('/api/upload-images', requireUser, upload.array('images', 3), async (req, res) => {
  try {
    const files = Array.isArray(req.files) ? req.files : [];
    if (!files.length) return res.status(400).json({ error: 'حداقل یک عکس انتخاب کنید.' });
    if (files.length > 3) return res.status(400).json({ error: 'حداکثر ۳ عکس مجاز است.' });
    if (files.some(f => !f.mimetype.startsWith('image/'))) return res.status(400).json({ error: 'فقط فایل تصویری مجاز است.' });
    const db = getSupabaseAdmin();
    const buckets = await db.storage.listBuckets();
    if (!buckets.data?.some(b => b.name === IMAGE_BUCKET)) {
      const { error: bucketError } = await db.storage.createBucket(IMAGE_BUCKET, { public: true, fileSizeLimit: '5MB', allowedMimeTypes: ['image/jpeg','image/png','image/webp','image/gif'] });
      if (bucketError && !String(bucketError.message || '').toLowerCase().includes('already')) throw bucketError;
    }
    const urls = [];
    for (const file of files) {
      const ext = (file.originalname.split('.').pop() || 'jpg').toLowerCase().replace(/[^a-z0-9]/g, '') || 'jpg';
      const path = `${req.user.id}/${crypto.randomUUID()}.${ext}`;
      const { error } = await db.storage.from(IMAGE_BUCKET).upload(path, file.buffer, { contentType: file.mimetype, upsert: false });
      if (error) throw error;
      const { data } = db.storage.from(IMAGE_BUCKET).getPublicUrl(path);
      urls.push(data.publicUrl);
    }
    res.status(201).json({ urls });
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در آپلود عکس‌ها.' }); }
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

app.get('/api/admin/users', requireAdmin, async (_, res) => {
  try {
    const db = getSupabaseAdmin();
    const { data, error } = await db.from('profiles').select('id,full_name,shop_name,phone,city,is_blocked,blocked_until,block_reason,created_at,updated_at').order('created_at', { ascending: false });
    if (error) throw error;
    res.json(data || []);
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در دریافت کاربران.' }); }
});

app.patch('/api/admin/users/:id/block', requireAdmin, async (req, res) => {
  try {
    const blocked = Boolean(req.body?.blocked);
    const durationDays = Number(req.body?.duration_days || 0);
    const reason = String(req.body?.reason || '').trim().slice(0, 500);
    const blockedUntil = blocked && durationDays > 0 ? new Date(Date.now() + durationDays * 86400000).toISOString() : null;
    const db = getSupabaseAdmin();
    const { data, error } = await db.from('profiles').update({
      is_blocked: blocked,
      blocked_until: blockedUntil,
      block_reason: blocked ? reason : null,
      updated_at: new Date().toISOString()
    }).eq('id', req.params.id).select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در تغییر وضعیت کاربر.' }); }
});

app.get('/api/admin/products', requireAdmin, async (_, res) => {
  try {
    const db = getSupabaseAdmin();
    const { data, error } = await db.from('products').select('id,vendor_id,title,description,price,stock,category,image_url,is_active,is_featured,is_pinned,featured_until,pinned_until,created_at,updated_at').order('created_at', { ascending: false });
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

app.patch('/api/admin/products/:id/promotion', requireAdmin, async (req, res) => {
  try {
    const featureDays = Math.max(0, Math.trunc(Number(req.body?.feature_days || 0)));
    const pinDays = Math.max(0, Math.trunc(Number(req.body?.pin_days || 0)));
    const db = getSupabaseAdmin();
    const now = Date.now();
    const payload = {
      is_featured: featureDays > 0,
      is_pinned: pinDays > 0,
      featured_until: featureDays > 0 ? new Date(now + featureDays * 86400000).toISOString() : null,
      pinned_until: pinDays > 0 ? new Date(now + pinDays * 86400000).toISOString() : null,
      updated_at: new Date().toISOString()
    };
    const { data, error } = await db.from('products').update(payload).eq('id', req.params.id).select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در ویژه/پین کردن آگهی.' }); }
});

app.get('/api/listings', async (req, res) => {
  try {
    const db = getSupabaseAdmin();
    let query = db.from('products').select('id,title,description,price,stock,category,image_url,created_at,vendor_id,is_featured,is_pinned,featured_until,pinned_until').eq('is_active', true).order('is_pinned', { ascending: false }).order('is_featured', { ascending: false }).order('created_at', { ascending: false }).limit(100);
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
