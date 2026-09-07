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
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024, files: 6 } });
const IMAGE_BUCKET = 'listing-images';
const AVATAR_BUCKET = 'profile-avatars';

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

app.get('/', (_, res) => res.json({ message: 'Bazarek backend is running', version: '2.1.0' }));
app.get('/api/health', (_, res) => res.json({ ok: true, version: '2.1.0' }));
app.get('/api/version', (_, res) => res.json({ version: '2.1.0', features: ['warnings','reports','image-upload','wallet','promotions','favorites','listing-views','contact-phone'] }));

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
    res.status(201).json({ token: signedIn.session.access_token, refresh_token: signedIn.session.refresh_token, user });
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در ساخت حساب.' }); }
});

app.post('/api/upload-images', requireUser, upload.array('images', 6), async (req, res) => {
  try {
    const files = Array.isArray(req.files) ? req.files : [];
    if (!files.length) return res.status(400).json({ error: 'حداقل یک عکس انتخاب کنید.' });
    if (files.length > 6) return res.status(400).json({ error: 'حداکثر ۶ عکس مجاز است.' });
    if (files.some(f => !f.mimetype.startsWith('image/'))) return res.status(400).json({ error: 'فقط فایل تصویری مجاز است.' });
    const db = getSupabaseAdmin();
    const buckets = await db.storage.listBuckets();
    if (!buckets.data?.some(b => b.name === IMAGE_BUCKET)) {
      const { error: bucketError } = await db.storage.createBucket(IMAGE_BUCKET, { public: true, fileSizeLimit: '10MB', allowedMimeTypes: ['image/jpeg','image/png','image/webp','image/gif','image/heic','image/heif'] });
      if (bucketError && !String(bucketError.message || '').toLowerCase().includes('already')) throw bucketError;
    } else {
      const { error: bucketUpdateError } = await db.storage.updateBucket(IMAGE_BUCKET, { public: true, fileSizeLimit: '10MB', allowedMimeTypes: ['image/jpeg','image/png','image/webp','image/gif','image/heic','image/heif'] });
      if (bucketUpdateError) console.warn('Could not update image bucket settings:', bucketUpdateError.message);
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
  } catch (e) {
    console.error('Listing image upload error:', e);
    const detail = String(e?.message || '').trim();
    res.status(500).json({ error: detail ? `خطا در آپلود عکس‌ها: ${detail}` : 'خطا در آپلود عکس‌ها.' });
  }
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

app.post('/api/auth/refresh', async (req, res) => {
  try {
    if (!requireConfig(res)) return;
    const refreshToken = String(req.body?.refresh_token || '').trim();
    if (!refreshToken) return res.status(400).json({ error: 'توکن تمدید ارسال نشده است.' });
    const { data, error } = await supabaseAuth.auth.refreshSession({ refresh_token: refreshToken });
    if (error || !data.session) return res.status(401).json({ error: 'نشست شما منقضی شده است. لطفاً دوباره وارد شوید.' });
    res.json({ token: data.session.access_token, refresh_token: data.session.refresh_token, user: data.user });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'خطا در تمدید نشست.' });
  }
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



app.post('/api/profile/avatar', requireUser, upload.single('avatar'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'تصویر پروفایل انتخاب نشده است.' });
    if (!req.file.mimetype.startsWith('image/')) return res.status(400).json({ error: 'فقط فایل تصویری مجاز است.' });
    const db=getSupabaseAdmin();
    const buckets=await db.storage.listBuckets();
    if(!buckets.data?.some(b=>b.name===AVATAR_BUCKET)){
      const {error}=await db.storage.createBucket(AVATAR_BUCKET,{public:true,fileSizeLimit:'10MB',allowedMimeTypes:['image/jpeg','image/png','image/webp']});
      if(error && !String(error.message||'').toLowerCase().includes('already')) throw error;
    }
    const ext=(req.file.originalname.split('.').pop()||'jpg').toLowerCase().replace(/[^a-z0-9]/g,'')||'jpg';
    const path=`${req.user.id}/avatar.${ext}`;
    const {error}=await db.storage.from(AVATAR_BUCKET).upload(path,req.file.buffer,{contentType:req.file.mimetype,upsert:true});
    if(error)throw error;
    const {data}=db.storage.from(AVATAR_BUCKET).getPublicUrl(path);
    await db.from('profiles').update({avatar_url:data.publicUrl,updated_at:new Date().toISOString()}).eq('id',req.user.id);
    res.status(201).json({url:data.publicUrl});
  } catch(e){console.error(e);res.status(500).json({error:'خطا در آپلود تصویر پروفایل.'});}
});

app.post('/api/conversations', requireUser, async (req, res) => {
  try {
    const listingId = String(req.body?.listing_id || '').trim();
    if (!listingId) return res.status(400).json({ error: 'آگهی مشخص نیست.' });
    const db = getSupabaseAdmin();
    const { data: listing, error: listingError } = await db.from('products').select('id,title,vendor_id,is_active,allow_chat').eq('id', listingId).single();
    if (listingError || !listing) return res.status(404).json({ error: 'آگهی پیدا نشد.' });
    if (listing.is_active === false) return res.status(400).json({ error: 'این آگهی دیگر فعال نیست.' });
    if (listing.allow_chat === false) return res.status(403).json({ error: 'فروشنده چت را برای این آگهی فعال نکرده است.' });
    if (listing.vendor_id === req.user.id) return res.status(400).json({ error: 'شما فروشنده این آگهی هستید.' });
    const { data: existing } = await db.from('conversations').select('*').eq('listing_id', listingId).eq('buyer_id', req.user.id).eq('seller_id', listing.vendor_id).maybeSingle();
    if (existing) return res.json(existing);
    const { data, error } = await db.from('conversations').insert([{ listing_id: listingId, buyer_id: req.user.id, seller_id: listing.vendor_id }]).select().single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در شروع گفتگو.' }); }
});

app.get('/api/conversations', requireUser, async (req, res) => {
  try {
    const db = getSupabaseAdmin();
    const { data: rows, error } = await db.from('conversations').select('id,listing_id,buyer_id,seller_id,last_message_at,created_at').or(`buyer_id.eq.${req.user.id},seller_id.eq.${req.user.id}`).order('last_message_at', { ascending: false, nullsFirst: false }).order('created_at', { ascending: false });
    if (error) throw error;
    const list = rows || [];
    const listingIds=[...new Set(list.map(x=>x.listing_id).filter(Boolean))];
    const userIds=[...new Set(list.flatMap(x=>[x.buyer_id,x.seller_id]).filter(Boolean))];
    const [{data:listings},{data:profiles}] = await Promise.all([
      listingIds.length ? db.from('products').select('id,title,image_url').in('id',listingIds) : Promise.resolve({data:[]}),
      userIds.length ? db.from('profiles').select('id,full_name,shop_name').in('id',userIds) : Promise.resolve({data:[]})
    ]);
    const lm=Object.fromEntries((listings||[]).map(x=>[x.id,x]));
    const pm=Object.fromEntries((profiles||[]).map(x=>[x.id,x]));
    const result=list.map(x=>({ ...x, listing_title: lm[x.listing_id]?.title || 'آگهی', listing_image_url: lm[x.listing_id]?.image_url || '', other_user_id: x.buyer_id===req.user.id?x.seller_id:x.buyer_id, other_user_name: (pm[x.buyer_id===req.user.id?x.seller_id:x.buyer_id]?.shop_name || pm[x.buyer_id===req.user.id?x.seller_id:x.buyer_id]?.full_name || 'کاربر بازارک') }));
    res.json(result);
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در دریافت گفتگوها.' }); }
});

app.get('/api/conversations/:id/messages', requireUser, async (req, res) => {
  try {
    const db=getSupabaseAdmin();
    const {data:conv,error:ce}=await db.from('conversations').select('id,buyer_id,seller_id,listing_id').eq('id',req.params.id).single();
    if(ce||!conv) return res.status(404).json({error:'گفتگو پیدا نشد.'});
    if(conv.buyer_id!==req.user.id&&conv.seller_id!==req.user.id) return res.status(403).json({error:'دسترسی به این گفتگو مجاز نیست.'});
    const {data,error}=await db.from('messages').select('id,conversation_id,sender_id,message,created_at,is_read').eq('conversation_id',req.params.id).order('created_at',{ascending:true});
    if(error)throw error;
    await db.from('messages').update({is_read:true}).eq('conversation_id',req.params.id).neq('sender_id',req.user.id).eq('is_read',false);
    res.json(data||[]);
  }catch(e){console.error(e);res.status(500).json({error:'خطا در دریافت پیام‌ها.'});}
});

app.post('/api/conversations/:id/messages', requireUser, async (req, res) => {
  try {
    const message=String(req.body?.message||'').trim();
    if(!message)return res.status(400).json({error:'متن پیام خالی است.'});
    if(message.length>2000)return res.status(400).json({error:'پیام بیش از حد طولانی است.'});
    const db=getSupabaseAdmin();
    const {data:conv,error:ce}=await db.from('conversations').select('id,buyer_id,seller_id').eq('id',req.params.id).single();
    if(ce||!conv)return res.status(404).json({error:'گفتگو پیدا نشد.'});
    if(conv.buyer_id!==req.user.id&&conv.seller_id!==req.user.id)return res.status(403).json({error:'دسترسی به این گفتگو مجاز نیست.'});
    const {data,error}=await db.from('messages').insert([{conversation_id:req.params.id,sender_id:req.user.id,message}]).select().single();
    if(error)throw error;
    await db.from('conversations').update({last_message_at:new Date().toISOString()}).eq('id',req.params.id);
    res.status(201).json(data);
  }catch(e){console.error(e);res.status(500).json({error:'خطا در ارسال پیام.'});}
});

app.get('/api/me/warnings', requireUser, async (req,res)=>{
  try{const db=getSupabaseAdmin();const {data,error}=await db.from('user_warnings').select('id,message,created_at,is_read').eq('user_id',req.user.id).order('created_at',{ascending:false}).limit(50);if(error)throw error;res.json(data||[]);}catch(e){console.error(e);res.status(500).json({error:'خطا در دریافت هشدارها.'});}
});

app.post('/api/reports', requireUser, async (req,res)=>{
  try{const listingId=String(req.body?.listing_id||'').trim();const reason=String(req.body?.reason||'').trim().slice(0,500);if(!listingId||!reason)return res.status(400).json({error:'آگهی و دلیل گزارش الزامی است.'});const db=getSupabaseAdmin();const {data:listing}=await db.from('products').select('id').eq('id',listingId).maybeSingle();if(!listing)return res.status(404).json({error:'آگهی پیدا نشد.'});const {data,error}=await db.from('reports').insert([{listing_id:listingId,reporter_id:req.user.id,reason}]).select().single();if(error)throw error;res.status(201).json(data);}catch(e){console.error(e);res.status(500).json({error:'خطا در ثبت گزارش.'});}
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
    let query = db.from('products').select('id,title,description,price,stock,category,image_url,created_at,vendor_id,is_featured,is_pinned,featured_until,pinned_until,allow_chat,show_phone,contact_phone,location_text,is_negotiable,views_count').eq('is_active', true).order('is_pinned', { ascending: false }).order('is_featured', { ascending: false }).order('created_at', { ascending: false }).limit(100);
    const q = String(req.query.q || '').trim();
    const category = String(req.query.category || '').trim();
    if (q) query = query.or(`title.ilike.%${q}%,description.ilike.%${q}%`);
    if (category) query = query.eq('category', category);
    const { data, error } = await query;
    if (error) throw error;
    const rows = data || [];
    const vendorIds = [...new Set(rows.map(x => x.vendor_id).filter(Boolean))];
    const { data: profiles } = vendorIds.length ? await db.from('profiles').select('id,full_name,shop_name,phone').in('id', vendorIds) : { data: [] };
    const pm = Object.fromEntries((profiles || []).map(x => [x.id, x]));
    res.json(rows.map(x => ({ ...x, seller_phone: x.show_phone ? (x.contact_phone || pm[x.vendor_id]?.phone || '') : '', seller_name: pm[x.vendor_id]?.shop_name || pm[x.vendor_id]?.full_name || 'فروشنده بازارک' })));
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در دریافت آگهی‌ها.' }); }
});

app.post('/api/listings/:id/view', async (req,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.rpc('bazarek_increment_listing_view',{p_listing_id:req.params.id});if(error)throw error;res.json({views_count:Number(data||0)});}catch(e){console.error(e);res.status(500).json({error:'خطا در ثبت بازدید.'});}});
app.get('/api/favorites', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('favorites').select('listing_id,created_at,products(id,title,price,image_url,category,is_featured,is_pinned)').eq('user_id',req.user.id).order('created_at',{ascending:false});if(error)throw error;res.json(data||[]);}catch(e){console.error(e);res.status(500).json({error:'خطا در دریافت علاقه‌مندی‌ها.'});}});
app.post('/api/favorites/:id', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {data:existing}=await db.from('favorites').select('listing_id').eq('user_id',req.user.id).eq('listing_id',req.params.id).maybeSingle();if(existing){await db.from('favorites').delete().eq('user_id',req.user.id).eq('listing_id',req.params.id);return res.json({favorite:false});}const {error}=await db.from('favorites').insert([{user_id:req.user.id,listing_id:req.params.id}]);if(error)throw error;res.status(201).json({favorite:true});}catch(e){console.error(e);res.status(500).json({error:'خطا در تغییر علاقه‌مندی.'});}});

app.post('/api/admin/users/:id/warnings', requireAdmin, async (req,res)=>{try{const message=String(req.body?.message||'').trim().slice(0,1000);if(!message)return res.status(400).json({error:'متن هشدار الزامی است.'});const db=getSupabaseAdmin();const {data,error}=await db.from('user_warnings').insert([{user_id:req.params.id,message}]).select().single();if(error)throw error;res.status(201).json(data);}catch(e){console.error(e);res.status(500).json({error:'خطا در ثبت هشدار.'});}});
app.get('/api/admin/warnings', requireAdmin, async (_,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('user_warnings').select('*').order('created_at',{ascending:false}).limit(200);if(error)throw error;res.json(data||[]);}catch(e){res.status(500).json({error:'خطا در دریافت هشدارها.'});}});
app.get('/api/admin/reports', requireAdmin, async (_,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('reports').select('*').order('created_at',{ascending:false}).limit(200);if(error)throw error;res.json(data||[]);}catch(e){res.status(500).json({error:'خطا در دریافت گزارش‌ها.'});}});
app.patch('/api/admin/reports/:id', requireAdmin, async (req,res)=>{try{const status=String(req.body?.status||'reviewed');if(!['open','reviewed','dismissed'].includes(status))return res.status(400).json({error:'وضعیت گزارش نامعتبر است.'});const db=getSupabaseAdmin();const {data,error}=await db.from('reports').update({status,updated_at:new Date().toISOString()}).eq('id',req.params.id).select().single();if(error)throw error;res.json(data);}catch(e){res.status(500).json({error:'خطا در تغییر گزارش.'});}});

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


app.get('/api/monetization/packages', requireUser, async (_,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('promotion_packages').select('*').eq('is_active',true).order('price_afn');if(error)throw error;res.json(data||[]);}catch(e){res.status(500).json({error:'خطا در دریافت بسته‌های تبلیغاتی.'});}});
app.get('/api/wallet', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();await db.rpc('bazarek_grant_welcome_credit',{p_user_id:req.user.id,p_amount:100});const [{data:w,error:we},{data:tx,error:te}]=await Promise.all([db.from('wallets').select('*').eq('user_id',req.user.id).maybeSingle(),db.from('wallet_transactions').select('*').eq('user_id',req.user.id).order('created_at',{ascending:false}).limit(100)]);if(we)throw we;if(te)throw te;res.json({wallet:w||{user_id:req.user.id,balance_afn:0},transactions:tx||[]});}catch(e){console.error(e);res.status(500).json({error:'خطا در دریافت کیف پول.'});}});
app.get('/api/promotions/orders', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('promotion_orders').select('*,promotion_packages(title),products(title)').eq('user_id',req.user.id).order('created_at',{ascending:false}).limit(100);if(error)throw error;res.json(data||[]);}catch(e){res.status(500).json({error:'خطا در دریافت سفارش‌ها.'});}});
app.post('/api/promotions/orders', requireUser, async (req,res)=>{try{const {listing_id,package_id,payment_method='wallet',payment_reference=''}=req.body||{};if(!listing_id||!package_id)return res.status(400).json({error:'آگهی و بسته تبلیغاتی الزامی است.'});const db=getSupabaseAdmin();const {data:pkg,error:pe}=await db.from('promotion_packages').select('*').eq('id',package_id).eq('is_active',true).maybeSingle();if(pe)throw pe;if(!pkg)return res.status(404).json({error:'بسته تبلیغاتی پیدا نشد.'});const {data:listing,error:le}=await db.from('products').select('id,vendor_id').eq('id',listing_id).maybeSingle();if(le)throw le;if(!listing||listing.vendor_id!==req.user.id)return res.status(403).json({error:'این آگهی متعلق به شما نیست.'});
let status='pending';if(payment_method==='wallet'){try{await db.rpc('bazarek_wallet_debit',{p_user_id:req.user.id,p_amount:pkg.price_afn,p_description:`خرید ${pkg.title}`,p_reference:package_id});status='paid';}catch(e){return res.status(400).json({error:'موجودی کیف پول کافی نیست.'});}}
const {data:order,error}=await db.from('promotion_orders').insert([{user_id:req.user.id,listing_id,package_id,amount_afn:pkg.price_afn,payment_method,payment_reference:String(payment_reference).slice(0,200),status}]).select().single();if(error)throw error;
if(status==='paid'){const now=Date.now();const {error:ue}=await db.from('products').update({is_featured:pkg.feature_days>0,is_pinned:pkg.pin_days>0,featured_until:pkg.feature_days>0?new Date(now+pkg.feature_days*86400000).toISOString():null,pinned_until:pkg.pin_days>0?new Date(now+pkg.pin_days*86400000).toISOString():null,updated_at:new Date().toISOString()}).eq('id',listing_id);if(ue)throw ue;}res.status(201).json(order);}catch(e){console.error(e);res.status(500).json({error:'خطا در ثبت سفارش ارتقای آگهی.'});}});
app.get('/api/subscriptions', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('seller_subscriptions').select('*').eq('user_id',req.user.id).order('created_at',{ascending:false}).limit(20);if(error)throw error;res.json(data||[]);}catch(e){res.status(500).json({error:'خطا در دریافت اشتراک‌ها.'});}});
app.post('/api/subscriptions', requireUser, async (req,res)=>{try{const plans={basic:{price:500,days:30},pro:{price:900,days:30},business:{price:1500,days:30}};const plan=String(req.body?.plan||'');if(!plans[plan])return res.status(400).json({error:'پلن نامعتبر است.'});const p=plans[plan];const db=getSupabaseAdmin();try{await db.rpc('bazarek_wallet_debit',{p_user_id:req.user.id,p_amount:p.price,p_description:`اشتراک ${plan}`,p_reference:plan});}catch(e){return res.status(400).json({error:'موجودی کیف پول کافی نیست.'});}const now=new Date();const end=new Date(now.getTime()+p.days*86400000);const {data,error}=await db.from('seller_subscriptions').insert([{user_id:req.user.id,plan,price_afn:p.price,starts_at:now.toISOString(),ends_at:end.toISOString(),status:'active'}]).select().single();if(error)throw error;await db.from('profiles').update({plan}).eq('id',req.user.id);res.status(201).json(data);}catch(e){console.error(e);res.status(500).json({error:'خطا در فعال‌سازی اشتراک.'});}});
app.get('/api/admin/monetization', requireAdmin, async (_,res)=>{try{const db=getSupabaseAdmin();const [{data:orders,error:oe},{data:tx,error:te},{data:subs,error:se}]=await Promise.all([db.from('promotion_orders').select('id,user_id,listing_id,package_id,amount_afn,payment_method,status,created_at').order('created_at',{ascending:false}).limit(300),db.from('wallet_transactions').select('id,user_id,type,amount_afn,description,reference_id,created_at').order('created_at',{ascending:false}).limit(300),db.from('seller_subscriptions').select('*').order('created_at',{ascending:false}).limit(100)]);if(oe)throw oe;if(te)throw te;if(se)throw se;const paid=(orders||[]).filter(x=>x.status==='paid').reduce((a,x)=>a+Number(x.amount_afn||0),0);res.json({revenue_afn:paid,orders:orders||[],transactions:tx||[],subscriptions:subs||[]});}catch(e){console.error(e);res.status(500).json({error:'خطا در دریافت آمار درآمد.'});}});
app.post('/api/admin/wallets/:id/credit', requireAdmin, async (req,res)=>{try{const amount=Math.trunc(Number(req.body?.amount_afn||0));if(amount<=0)return res.status(400).json({error:'مبلغ نامعتبر است.'});const db=getSupabaseAdmin();const balance=await db.rpc('bazarek_wallet_credit',{p_user_id:req.params.id,p_amount:amount,p_type:'credit',p_description:String(req.body?.description||'شارژ کیف پول توسط مدیریت').slice(0,200),p_reference:'admin'});res.status(201).json({balance_afn:balance.data});}catch(e){console.error(e);res.status(500).json({error:'خطا در شارژ کیف پول.'});}});
app.patch('/api/admin/promotions/orders/:id', requireAdmin, async (req,res)=>{try{const status=String(req.body?.status||'paid');if(!['paid','rejected','cancelled'].includes(status))return res.status(400).json({error:'وضعیت نامعتبر است.'});const db=getSupabaseAdmin();const {data:order,error:oe}=await db.from('promotion_orders').select('*,promotion_packages(*)').eq('id',req.params.id).maybeSingle();if(oe)throw oe;if(!order)return res.status(404).json({error:'سفارش پیدا نشد.'});const {data:updated,error}=await db.from('promotion_orders').update({status,updated_at:new Date().toISOString()}).eq('id',req.params.id).select().single();if(error)throw error;if(status==='paid'&&order.status!=='paid'){const pkg=order.promotion_packages;const now=Date.now();await db.from('products').update({is_featured:pkg.feature_days>0,is_pinned:pkg.pin_days>0,featured_until:pkg.feature_days>0?new Date(now+pkg.feature_days*86400000).toISOString():null,pinned_until:pkg.pin_days>0?new Date(now+pkg.pin_days*86400000).toISOString():null,updated_at:new Date().toISOString()}).eq('id',order.listing_id);}res.json(updated);}catch(e){console.error(e);res.status(500).json({error:'خطا در تغییر سفارش.'});}});
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
    const { title, price, cost_price = 0, description = '', category = '', image_url = '', stock = 0, allow_chat = true, show_phone = false, contact_phone = '', location_text = '', is_negotiable = false } = req.body || {};
    if (!title || typeof title !== 'string') return res.status(400).json({ error: 'نام محصول الزامی است.' });
    const db = getSupabaseAdmin();
    const payload = { vendor_id: req.user.id, title: title.trim(), price: Math.max(0, Number(price) || 0), cost_price: Math.max(0, Number(cost_price) || 0), description: String(description), category: String(category), image_url: String(image_url), allow_chat: Boolean(allow_chat), show_phone: Boolean(show_phone), contact_phone: String(contact_phone).trim().slice(0,30), location_text: String(location_text).trim().slice(0,160), is_negotiable: Boolean(is_negotiable), stock: Math.max(0, Math.trunc(Number(stock) || 0)) };
    const { data, error } = await db.from('products').insert([payload]).select().single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در ثبت محصول.' }); }
});

app.patch('/api/products/:id', requireUser, async (req, res) => {
  try {
    const allowed = ['title', 'price', 'cost_price', 'description', 'category', 'image_url', 'stock', 'allow_chat', 'show_phone', 'contact_phone', 'location_text', 'is_negotiable'];
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

app.use((err, req, res, next) => {
  console.error('Unhandled API error:', err);
  if (err instanceof multer.MulterError) {
    const msg = err.code === 'LIMIT_FILE_SIZE' ? 'حجم هر عکس بیش از ۱۰ مگابایت است.' : 'خطا در ارسال فایل.';
    return res.status(400).json({ error: msg });
  }
  if (!res.headersSent) return res.status(500).json({ error: 'خطای داخلی سرور.' });
  next(err);
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Bazarek backend running on ${PORT}`));
