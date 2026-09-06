require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
app.use(cors());
app.use(express.json({ limit: '1mb' }));

const SUPABASE_URL = (process.env.SUPABASE_URL || '').trim();
const SUPABASE_KEY = (process.env.SUPABASE_KEY || '').trim();
const GEMINI_API_KEY = (process.env.GEMINI_API_KEY || '').trim();

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_KEY. Copy backend/.env.example to backend/.env.');
  process.exit(1);
}

const supabaseAdminClient = createClient(SUPABASE_URL, SUPABASE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const genAI = GEMINI_API_KEY ? new GoogleGenerativeAI(GEMINI_API_KEY) : null;

function jsonError(res, status, message) {
  return res.status(status).json({ error: message });
}

function bearerToken(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return null;
  return header.slice(7).trim() || null;
}

function userClient(token) {
  return createClient(SUPABASE_URL, SUPABASE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
}

async function requireUser(req, res, next) {
  try {
    const token = bearerToken(req);
    if (!token) return jsonError(res, 401, 'لطفاً وارد حساب فروشنده شوید.');

    const { data, error } = await supabaseAdminClient.auth.getUser(token);
    if (error || !data.user) return jsonError(res, 401, 'نشست شما معتبر نیست. دوباره وارد شوید.');

    req.accessToken = token;
    req.user = data.user;
    req.supabase = userClient(token);
    next();
  } catch (error) {
    console.error('Auth middleware:', error);
    return jsonError(res, 401, 'احراز هویت انجام نشد.');
  }
}

app.get('/', (req, res) => {
  res.json({ name: 'Bazarek API', status: 'ok', version: '2.0.0' });
});

app.get('/api/health', (req, res) => res.json({ ok: true }));

// Supabase Auth: passwords never reach or get stored by this server.
app.post('/api/auth/signup', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const password = String(req.body.password || '');
    const fullName = String(req.body.fullName || '').trim();
    const shopName = String(req.body.shopName || '').trim();

    if (!email || !password || !fullName || !shopName) {
      return jsonError(res, 400, 'نام، نام دکان، ایمیل و رمز عبور الزامی است.');
    }
    if (password.length < 8) return jsonError(res, 400, 'رمز عبور باید حداقل ۸ کاراکتر باشد.');

    const { data, error } = await supabaseAdminClient.auth.signUp({
      email,
      password,
      options: { data: { full_name: fullName, shop_name: shopName } },
    });
    if (error) return jsonError(res, 400, error.message);

    return res.status(201).json({
      user: data.user,
      session: data.session,
      requiresEmailConfirmation: !data.session,
      message: data.session ? 'ثبت‌نام با موفقیت انجام شد.' : 'حساب ساخته شد. ایمیل خود را تأیید کنید و سپس وارد شوید.',
    });
  } catch (error) {
    console.error('Signup:', error);
    return jsonError(res, 500, 'ثبت‌نام انجام نشد.');
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const password = String(req.body.password || '');
    if (!email || !password) return jsonError(res, 400, 'ایمیل و رمز عبور الزامی است.');

    const { data, error } = await supabaseAdminClient.auth.signInWithPassword({ email, password });
    if (error || !data.session) return jsonError(res, 401, error?.message || 'ایمیل یا رمز عبور نادرست است.');

    return res.json({ user: data.user, session: data.session });
  } catch (error) {
    console.error('Login:', error);
    return jsonError(res, 500, 'ورود انجام نشد.');
  }
});

app.get('/api/auth/me', requireUser, async (req, res) => {
  const { data, error } = await req.supabase
    .from('vendors')
    .select('id, full_name, shop_name, phone, city, plan, created_at')
    .eq('id', req.user.id)
    .maybeSingle();

  if (error) return jsonError(res, 500, error.message);
  res.json({ user: req.user, vendor: data });
});

app.post('/api/auth/logout', requireUser, async (req, res) => {
  // Sign-out is primarily handled locally by the mobile app. This endpoint is kept
  // for clients that want an explicit server-side sign-out request.
  const { error } = await supabaseAdminClient.auth.admin.signOut(req.accessToken);
  if (error && !/not found|invalid/i.test(error.message)) {
    return jsonError(res, 400, error.message);
  }
  res.json({ ok: true });
});

app.get('/api/dashboard', requireUser, async (req, res) => {
  try {
    const [{ count: productCount, error: productError }, { data: products, error: productsError }] = await Promise.all([
      req.supabase.from('products').select('id', { count: 'exact', head: true }),
      req.supabase.from('products').select('id, title, price, stock, created_at').order('created_at', { ascending: false }).limit(5),
    ]);
    if (productError) throw productError;
    if (productsError) throw productsError;

    const { data: orders, error: orderError } = await req.supabase
      .from('orders')
      .select('id, total_amount, status, created_at')
      .order('created_at', { ascending: false })
      .limit(100);
    if (orderError) throw orderError;

    const totalSales = (orders || [])
      .filter((o) => o.status !== 'cancelled')
      .reduce((sum, o) => sum + Number(o.total_amount || 0), 0);
    const pendingOrders = (orders || []).filter((o) => o.status === 'pending').length;

    res.json({
      productCount: productCount || 0,
      orderCount: orders?.length || 0,
      pendingOrders,
      totalSales,
      recentProducts: products || [],
    });
  } catch (error) {
    console.error('Dashboard:', error);
    return jsonError(res, 500, 'دریافت داشبورد انجام نشد.');
  }
});

app.get('/api/products', requireUser, async (req, res) => {
  try {
    const { data, error } = await req.supabase.from('products').select('*').order('created_at', { ascending: false });
    if (error) throw error;
    res.json(data || []);
  } catch (error) {
    return jsonError(res, 500, error.message);
  }
});

app.post('/api/products', requireUser, async (req, res) => {
  try {
    const title = String(req.body.title || '').trim();
    const price = Number(req.body.price);
    const description = String(req.body.description || '').trim();
    const stock = Number.isFinite(Number(req.body.stock)) ? Number(req.body.stock) : 0;
    if (!title || !Number.isFinite(price) || price < 0) return jsonError(res, 400, 'نام محصول و قیمت معتبر الزامی است.');

    const { data, error } = await req.supabase
      .from('products')
      .insert([{ title, price, description, stock, vendor_id: req.user.id }])
      .select()
      .single();
    if (error) throw error;
    res.status(201).json({ message: 'محصول با موفقیت ثبت شد.', data });
  } catch (error) {
    return jsonError(res, 500, error.message);
  }
});

app.post('/api/generate-ad', requireUser, async (req, res) => {
  try {
    if (!genAI) return jsonError(res, 503, 'سرویس هوش مصنوعی هنوز تنظیم نشده است.');
    const productName = String(req.body.productName || '').trim();
    const description = String(req.body.description || '').trim();
    if (!productName) return jsonError(res, 400, 'نام محصول الزامی است.');

    const model = genAI.getGenerativeModel({ model: process.env.GEMINI_MODEL || 'gemini-1.5-flash' });
    const prompt = `برای یک فروشنده در افغانستان یک متن تبلیغاتی کوتاه و حرفه‌ای به دری افغانستان بنویس.\nنام محصول: ${productName}\nتوضیحات: ${description || 'بدون توضیح'}\nاز ادعاهای غیرواقعی خودداری کن و در پایان یک دعوت کوتاه به تماس/سفارش بنویس.`;
    const result = await model.generateContent(prompt);
    const adText = result.response.text();
    res.json({ adText });
  } catch (error) {
    console.error('Gemini:', error);
    return jsonError(res, 500, 'خطا در تولید متن آگهی.');
  }
});

const PORT = Number(process.env.PORT || 5000);
app.listen(PORT, () => console.log(`Bazarek API running on port ${PORT}`));
