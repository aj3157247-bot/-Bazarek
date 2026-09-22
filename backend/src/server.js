require('dotenv').config();
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const { createClient } = require('@supabase/supabase-js');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const multer = require('multer');
const crypto = require('crypto');
const sharp = require('sharp');
const { requireUser, getSupabaseAdmin } = require('./middlewares/auth');
const requireAdmin = require('./middlewares/adminAuth');

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024, files: 20 } });
const IMAGE_BUCKET = 'listing-images';
const AVATAR_BUCKET = 'profile-avatars';

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;
const supabaseAuth = SUPABASE_URL && SUPABASE_ANON_KEY ? createClient(SUPABASE_URL, SUPABASE_ANON_KEY) : null;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const genAI = GEMINI_API_KEY ? new GoogleGenerativeAI(GEMINI_API_KEY) : null;


// Expire time-based Boosts automatically. The UI also checks the *_until timestamps,
// so an expired Boost stops ranking immediately; this worker keeps the database flags
// in sync as well (and acts as a fallback if the database scheduler is unavailable).
async function expireTimeBasedBoosts() {
  try {
    const db = getSupabaseAdmin();
    const now = new Date().toISOString();

    const { data: expiredBoosts, error: boostError } = await db
      .from('products')
      .select('id')
      .not('boost_until', 'is', null)
      .lte('boost_until', now)
      .limit(500);
    if (boostError) throw boostError;

    if (expiredBoosts?.length) {
      const ids = expiredBoosts.map(x => x.id).filter(Boolean);
      const { error } = await db
        .from('products')
        .update({
          boost_level: 0,
          boost_until: null,
          updated_at: now,
        })
        .in('id', ids);
      if (error) throw error;
    }

    const { data: expiredFeatured, error: featuredError } = await db
      .from('products')
      .select('id')
      .eq('is_featured', true)
      .not('featured_until', 'is', null)
      .lte('featured_until', now)
      .limit(500);
    if (featuredError) throw featuredError;
    if (expiredFeatured?.length) {
      const ids = expiredFeatured.map(x => x.id).filter(Boolean);
      const { error } = await db
        .from('products')
        .update({ is_featured: false, featured_until: null, updated_at: now })
        .in('id', ids);
      if (error) throw error;
    }

    const { data: expiredPinned, error: pinnedError } = await db
      .from('products')
      .select('id')
      .eq('is_pinned', true)
      .not('pinned_until', 'is', null)
      .lte('pinned_until', now)
      .limit(500);
    if (pinnedError) throw pinnedError;
    if (expiredPinned?.length) {
      const ids = expiredPinned.map(x => x.id).filter(Boolean);
      const { error } = await db
        .from('products')
        .update({ is_pinned: false, pinned_until: null, updated_at: now })
        .in('id', ids);
      if (error) throw error;
    }

    // Monthly/yearly seller Boost subscriptions also expire automatically.
    const { error: subscriptionError } = await db
      .from('seller_subscriptions')
      .update({ status: 'expired' })
      .eq('status', 'active')
      .lte('ends_at', now);
    if (subscriptionError) throw subscriptionError;
  } catch (e) {
    console.error('Boost expiry worker error:', e?.message || e);
  }
}

function requireConfig(res) {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    res.status(503).json({ error: 'اتصال Supabase روی سرور تنظیم نشده است.' });
    return false;
  }
  return true;
}

app.get('/', (_, res) => res.json({ message: 'Bazarek backend is running', version: '2.2.0' }));
app.get('/api/health', (_, res) => res.json({ ok: true, version: '2.2.0' }));
app.get('/api/version', (_, res) => res.json({ version: '2.5.0', features: ['warnings','reports','image-upload','wallet','promotions','boost-ranking','boost-badges','subscriptions','favorites','listing-views','contact-phone'] }));

// Phone numbers are stored as a private, deterministic Supabase email alias so
// phone registration/login works without enabling Supabase SMS/OTP. Gmail/email
// accounts continue to use their real email address.
function normalizePhone(value) {
  let v = String(value || '').trim().replace(/[\s\-()]/g, '');
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  for (let i = 0; i < 10; i++) {
    v = v.replaceAll(fa[i], String(i)).replaceAll(ar[i], String(i));
  }
  if (v.startsWith('00')) v = '+' + v.slice(2);
  if (v.startsWith('0')) v = '+93' + v.slice(1);
  if (/^93\d{9}$/.test(v)) v = '+' + v;
  return v;
}

function isPhone(value) {
  return /^\+93\d{9}$/.test(normalizePhone(value));
}

function phoneAuthEmail(phone) {
  return `phone_${normalizePhone(phone).slice(1)}@phone.bazarek.app`;
}

function isEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value || '').trim());
}

app.post('/api/auth/register', async (req, res) => {
  try {
    if (!requireConfig(res)) return;
    const { email = '', password, full_name = '', shop_name = '', phone = '' } = req.body || {};
    const contact = String(email || phone || '').trim();
    if (!contact || !password) return res.status(400).json({ error: 'شماره تلفن یا ایمیل و رمز عبور الزامی است.' });
    if (password.length < 8) return res.status(400).json({ error: 'رمز عبور باید حداقل ۸ کاراکتر باشد.' });

    const phoneAccount = isPhone(contact);
    const normalizedPhone = phoneAccount ? normalizePhone(contact) : (String(phone || '').trim() || '');
    const normalizedEmail = phoneAccount ? phoneAuthEmail(normalizedPhone) : contact.toLowerCase();
    if (!phoneAccount && !isEmail(normalizedEmail)) {
      return res.status(400).json({ error: 'ایمیل یا شماره تلفن معتبر وارد کنید.' });
    }

    const db = getSupabaseAdmin();
    const { data: created, error } = await db.auth.admin.createUser({
      email: normalizedEmail,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: String(full_name).trim(),
        shop_name: String(shop_name).trim(),
        phone: normalizedPhone
      }
    });
    if (error) return res.status(400).json({ error: error.message });

    const user = created.user;
    const { error: profileError } = await db.from('profiles').upsert({
      id: user.id,
      full_name: String(full_name).trim(),
      shop_name: String(shop_name).trim(),
      phone: normalizedPhone
    }, { onConflict: 'id' });
    if (profileError) console.warn('Profile creation warning:', profileError.message);

    const { data: signedIn, error: loginError } = await supabaseAuth.auth.signInWithPassword({
      email: normalizedEmail,
      password
    });
    if (loginError || !signedIn.session) {
      return res.status(500).json({ error: 'حساب ساخته شد اما ورود خودکار انجام نشد. دوباره وارد شوید.' });
    }
    res.status(201).json({ token: signedIn.session.access_token, refresh_token: signedIn.session.refresh_token, user });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'خطا در ساخت حساب.' });
  }
});

app.post('/api/upload-images', requireUser, upload.array('images', 20), async (req, res) => {
  try {
    const files = Array.isArray(req.files) ? req.files : [];
    if (!files.length) return res.status(400).json({ error: 'حداقل یک عکس انتخاب کنید.' });
    if (files.length > 20) return res.status(400).json({ error: 'حداکثر ۲۰ عکس مجاز است.' });
    const imageExts = new Set(['jpg','jpeg','png','webp','gif','heic','heif']);
    for (const file of files) {
      const ext = (file.originalname.split('.').pop() || '').toLowerCase();
      if (!file.mimetype.startsWith('image/') && !imageExts.has(ext)) {
        return res.status(400).json({ error: 'فقط فایل تصویری مجاز است.' });
      }
      if (!file.mimetype.startsWith('image/')) {
        const inferred = ext === 'jpg' || ext === 'jpeg' ? 'jpeg' : ext;
        file.mimetype = `image/${inferred}`;
      }
    }
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
      const { error } = await db.storage.from(IMAGE_BUCKET).upload(path, file.buffer, { contentType: file.mimetype || 'image/jpeg', cacheControl: '31536000', upsert: false });
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
    const { email = '', password } = req.body || {};
    const contact = String(email || '').trim();
    if (!contact || !password) return res.status(400).json({ error: 'ایمیل یا شماره تلفن و رمز عبور الزامی است.' });

    const phoneAccount = isPhone(contact);
    const normalizedEmail = phoneAccount ? phoneAuthEmail(contact) : contact.toLowerCase();
    if (!phoneAccount && !isEmail(normalizedEmail)) {
      return res.status(400).json({ error: 'ایمیل یا شماره تلفن معتبر وارد کنید.' });
    }

    const { data, error } = await supabaseAuth.auth.signInWithPassword({ email: normalizedEmail, password });
    if (error || !data.session) return res.status(401).json({ error: 'ایمیل/شماره تلفن یا رمز عبور اشتباه است.' });
    res.json({ token: data.session.access_token, refresh_token: data.session.refresh_token, user: data.user });
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
    const { data: ads } = await db.from('products').select('id,is_active,views_count').eq('vendor_id', req.user.id);
    const list=ads||[];
    data.active_ads=list.filter(a=>a.is_active===true).length;
    data.total_ads=list.length;
    data.total_views=list.reduce((n,a)=>n+Number(a.views_count||0),0);

    // Social/profile statistics. Keep these optional so an older database
    // without the social tables does not break the whole account screen.
    try {
      const listingIds=list.map(a=>a.id).filter(Boolean);
      const [{count:followersCount},{count:followingCount},{data:ratings},{count:commentsCount},{count:likesReceivedCount}] = await Promise.all([
        db.from('seller_follows').select('*',{count:'exact',head:true}).eq('seller_id',req.user.id),
        db.from('seller_follows').select('*',{count:'exact',head:true}).eq('user_id',req.user.id),
        db.from('seller_ratings').select('rating').eq('seller_id',req.user.id),
        db.from('seller_comments').select('*',{count:'exact',head:true}).eq('seller_id',req.user.id),
        listingIds.length ? db.from('listing_likes').select('*',{count:'exact',head:true}).in('listing_id',listingIds) : Promise.resolve({count:0}),
      ]);
      const values=(ratings||[]).map(x=>Number(x.rating)).filter(x=>Number.isFinite(x));
      data.followers_count=followersCount||0;
      data.following_count=followingCount||0;
      data.rating=values.length ? values.reduce((a,x)=>a+x,0)/values.length : 0;
      data.ratings_count=values.length;
      data.comments_count=commentsCount||0;
      data.likes_received_count=likesReceivedCount||0;
    } catch (socialError) {
      console.warn('Profile social statistics unavailable:', socialError?.message || socialError);
      data.followers_count=0; data.following_count=0; data.rating=0; data.ratings_count=0; data.comments_count=0; data.likes_received_count=0;
    }
    res.json(data);
  } catch (e) { res.status(500).json({ error: 'خطا در دریافت پروفایل.' }); }
});

app.patch('/api/me', requireUser, async (req, res) => {
  try {
    const { full_name, shop_name, phone, city, bio } = req.body || {};
    const db = getSupabaseAdmin();
    const { data, error } = await db.from('profiles').update({ full_name: String(full_name||'').trim().slice(0,120), shop_name: String(shop_name||'').trim().slice(0,120), phone: String(phone||'').trim().slice(0,30), city: String(city||'').trim().slice(0,120), bio: String(bio||'').trim().slice(0,500), updated_at: new Date().toISOString() }).eq('id', req.user.id).select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { res.status(500).json({ error: 'خطا در ذخیره پروفایل.' }); }
});

app.post('/api/profile/avatar', requireUser, upload.single('avatar'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'تصویر پروفایل انتخاب نشده است.' });

    const db = getSupabaseAdmin();
    const buckets = await db.storage.listBuckets();
    const exists = buckets.data?.some(b => b.name === AVATAR_BUCKET);
    if (!exists) {
      const { error } = await db.storage.createBucket(AVATAR_BUCKET, {
        public: true,
        fileSizeLimit: '10MB',
        allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic', 'image/heif', 'image/avif'],
      });
      if (error && !String(error.message || '').toLowerCase().includes('already')) throw error;
    } else {
      const { error } = await db.storage.updateBucket(AVATAR_BUCKET, {
        public: true,
        fileSizeLimit: '10MB',
        allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic', 'image/heif', 'image/avif'],
      });
      if (error) console.warn('Could not update avatar bucket settings:', error.message);
    }

    // پردازش فایل با sharp جهت رفع چرخش EXIF عکس‌های عمودی موبایل و جلوگیری از زوم شدن
    const processedBuffer = await sharp(req.file.buffer)
      .rotate()
      .resize(400, 400, {
        fit: 'contain',
        background: { r: 255, g: 255, b: 255, alpha: 1 }
      })
      .jpeg({ quality: 85 })
      .toBuffer();

    const path = `${req.user.id}/avatar-${Date.now()}-${crypto.randomUUID()}.jpg`;
    const { error } = await db.storage.from(AVATAR_BUCKET).upload(path, processedBuffer, {
      contentType: 'image/jpeg',
      cacheControl: '31536000',
      upsert: false,
    });
    if (error) throw error;

    const { data } = db.storage.from(AVATAR_BUCKET).getPublicUrl(path);
    if (!data?.publicUrl) throw new Error('آدرس تصویر عمومی ساخته نشد.');

    const { error: profileError } = await db.from('profiles').update({
      avatar_url: data.publicUrl,
      updated_at: new Date().toISOString(),
    }).eq('id', req.user.id);
    if (profileError) throw profileError;

    res.status(201).json({ url: data.publicUrl });
  } catch (e) {
    console.error('Profile avatar upload error:', e);
    const detail = String(e?.message || '').trim();
    res.status(500).json({ error: detail ? `خطا در آپلود تصویر پروفایل: ${detail}` : 'خطا در آپلود تصویر پروفایل.' });
  }
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

app.get('/api/me/notifications', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('user_notifications').select('id,type,title,message,is_read,created_at').eq('user_id',req.user.id).order('created_at',{ascending:false}).limit(100);if(error)throw error;res.json(data||[]);}catch(e){console.error(e);res.status(500).json({error:'خطا در دریافت اعلان‌ها.'});}});
app.patch('/api/me/notifications/:id/read', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('user_notifications').update({is_read:true}).eq('id',req.params.id).eq('user_id',req.user.id).select().single();if(error)throw error;res.json(data);}catch(e){res.status(500).json({error:'خطا در خواندن اعلان.'});}});
app.delete('/api/me/notifications/:id', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {error}=await db.from('user_notifications').delete().eq('id',req.params.id).eq('user_id',req.user.id);if(error)throw error;res.json({ok:true});}catch(e){res.status(500).json({error:'خطا در حذف اعلان.'});}});

app.post('/api/reports', requireUser, async (req,res)=>{
  try{
    const listingId=String(req.body?.listing_id||'').trim();
    const reason=String(req.body?.reason||'').trim().slice(0,500);
    if(!listingId||!reason)return res.status(400).json({error:'آگهی و دلیل گزارش الزامی است.'});
    const db=getSupabaseAdmin();
    const {data:listing,error:listingError}=await db.from('products').select('id,vendor_id').eq('id',listingId).maybeSingle();
    if(listingError)throw listingError;
    if(!listing)return res.status(404).json({error:'آگهی پیدا نشد.'});
    if(listing.vendor_id===req.user.id)return res.status(400).json({error:'نمی‌توانید آگهی خودتان را گزارش کنید.'});
    const {data:existing,error:existingError}=await db.from('reports').select('id').eq('listing_id',listingId).eq('reporter_id',req.user.id).eq('status','open').maybeSingle();
    if(existingError)throw existingError;
    if(existing)return res.status(409).json({error:'این آگهی را قبلاً گزارش کرده‌اید؛ گزارش شما در انتظار بررسی است.'});
    const {data,error}=await db.from('reports').insert([{listing_id:listingId,reporter_id:req.user.id,reason}]).select().single();
    if(error)throw error;
    res.status(201).json(data);
  }catch(e){console.error(e);res.status(500).json({error:'خطا در ثبت گزارش.'});}
});

app.post('/api/admin/login', async (req, res) => {
  const { email, password } = req.body || {};
  const normalizedEmail = String(email || '').trim().toLowerCase();
  const db = getSupabaseAdmin();
  const logLogin = async (success) => {
    try {
      await db.from('admin_login_events').insert([{
        email: normalizedEmail || 'unknown',
        success,
        ip_address: req.headers['cf-connecting-ip'] || req.headers['x-forwarded-for'] || req.socket?.remoteAddress || null,
        user_agent: String(req.headers['user-agent'] || '').slice(0, 500)
      }]);
    } catch (e) { console.warn('Could not record admin login event:', e?.message || e); }
  };
  if (!process.env.ADMIN_EMAIL || !process.env.ADMIN_PASSWORD || !process.env.ADMIN_SESSION_SECRET) {
    await logLogin(false);
    return res.status(503).json({ error: 'تنظیمات امن پنل مدیریت روی سرور کامل نیست.' });
  }
  if (normalizedEmail !== String(process.env.ADMIN_EMAIL).trim().toLowerCase() || password !== process.env.ADMIN_PASSWORD) {
    await logLogin(false);
    return res.status(401).json({ error: 'ایمیل یا رمز عبور ادمین اشتباه است.' });
  }
  await logLogin(true);
  const token = jwt.sign({ role: 'admin', email: normalizedEmail }, process.env.ADMIN_SESSION_SECRET, { expiresIn: '8h' });
  res.json({ token, security_notice: 'ورود مدیریت ثبت شد.' });
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
    await db.from('user_notifications').insert([{
      user_id: req.params.id, type: blocked ? 'warning' : 'system',
      title: blocked ? 'حساب شما محدود شد' : 'مسدودی حساب برداشته شد',
      message: blocked ? `حساب شما توسط مدیریت بازارک مسدود شد. دلیل: ${reason || 'نقض قوانین بازارک'}` : 'دسترسی حساب شما دوباره فعال شد.'
    }]);
    res.json(data);
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در تغییر وضعیت کاربر.' }); }
});

app.get('/api/admin/products', requireAdmin, async (_, res) => {
  try {
    const db = getSupabaseAdmin();
    const { data, error } = await db.from('products').select('id,vendor_id,title,description,price,stock,category,subcategory,province,image_url,is_active,moderation_disabled,moderation_reason,is_featured,is_pinned,featured_until,pinned_until,boost_level,boost_until,created_at,updated_at,currency').order('created_at', { ascending: false });
    if (error) throw error;
    res.json(data || []);
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در دریافت آگهی‌ها.' }); }
});

app.patch('/api/admin/products/:id/status', requireAdmin, async (req, res) => {
  try {
    const isActive = Boolean(req.body?.is_active);
    const reason = String(req.body?.reason || '').trim().slice(0, 500);
    const db = getSupabaseAdmin();
    const patch = { is_active: isActive, moderation_disabled: !isActive, moderation_reason: !isActive ? (reason || 'آگهی توسط مدیریت بازارک غیرفعال شد.') : null, updated_at: new Date().toISOString() };
    const { data, error } = await db.from('products').update(patch).eq('id', req.params.id).select().single();
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
    const { data: listing } = await db.from('products').select('is_store_product').eq('id', req.params.id).maybeSingle();
    if (listing?.is_store_product === true) return res.status(400).json({ error: 'محصول فروشگاهی قابل بوست یا ارتقای آگهی نیست.' });
    const now = Date.now();
    const payload = {
      is_featured: featureDays > 0,
      is_pinned: pinDays > 0,
      featured_until: featureDays > 0 ? new Date(now + featureDays * 86400000).toISOString() : null,
      pinned_until: pinDays > 0 ? new Date(now + pinDays * 86400000).toISOString() : null,
      boost_level: 0,
      boost_until: null,
      updated_at: new Date().toISOString()
    };
    const { data, error } = await db.from('products').update(payload).eq('id', req.params.id).select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در ویژه/پین کردن آگهی.' }); }
});

app.get('/api/translate', async (req, res) => {
  try {
    const text = String(req.query.text || '').trim().slice(0, 1200);
    const target = String(req.query.target || 'ps').trim();
    if (!text) return res.json({ text: '' });
    if (target !== 'ps') return res.json({ text });
    const url = new URL('https://api.mymemory.translated.net/get');
    url.searchParams.set('q', text);
    url.searchParams.set('langpair', 'fa|ps');
    const r = await fetch(url);
    if (!r.ok) return res.json({ text });
    const d = await r.json();
    const translated = d?.responseData?.translatedText;
    res.json({ text: translated && String(translated).trim() ? String(translated).trim() : text });
  } catch (_) { res.json({ text: String(req.query.text || '') }); }
});

app.get('/api/listings', async (req, res) => {
  try {
    const db = getSupabaseAdmin();
    let query = db.from('products').select('id,title,description,price,stock,category,subcategory,image_url,created_at,vendor_id,is_featured,is_pinned,featured_until,pinned_until,boost_level,boost_until,allow_chat,show_phone,contact_phone,location_text,external_link,is_negotiable,currency,views_count,province,brand,model,sizes,colors,material,condition,product_code,specifications,discount_percent,is_store_product').eq('is_active', true).eq('is_store_product', false).order('created_at', { ascending: false }).limit(100);
    const q = String(req.query.q || '').trim();
    const category = String(req.query.category || '').trim();
    const province = String(req.query.province || '').trim();
    const subcategory = String(req.query.subcategory || '').trim();
    if (q) query = query.or(`title.ilike.%${q}%,description.ilike.%${q}%`);
    if (category) query = query.eq('category', category);
    if (subcategory) query = query.eq('subcategory', subcategory);
    if (province) query = query.eq('province', province);
    const { data, error } = await query;
    if (error) throw error;
    const now = Date.now();
    const vendorIds = [...new Set((data || []).map(x => x.vendor_id).filter(Boolean))];
    const [{ data: profiles }, { data: globalSubs }, { data: storeSubs }] = await Promise.all([
      vendorIds.length ? db.from('profiles').select('id,full_name,shop_name,phone,bio').in('id', vendorIds) : Promise.resolve({ data: [] }),
      vendorIds.length ? db.from('seller_subscriptions').select('user_id,plan,starts_at,ends_at,status').in('user_id', vendorIds).in('status', ['active']).in('plan', ['boost_weekly','boost_monthly','boost_yearly']) : Promise.resolve({ data: [] }),
      vendorIds.length ? db.from('seller_subscriptions').select('user_id,plan,starts_at,ends_at,status').in('user_id', vendorIds).in('status', ['active']).in('plan', ['store_monthly','store_yearly']) : Promise.resolve({ data: [] }),
    ]);
    const pm = Object.fromEntries((profiles || []).map(x => [x.id, x]));
    const storeStatus = {};
    for (const sub of (storeSubs || [])) {
      const end = new Date(sub.ends_at || 0).getTime();
      const start = new Date(sub.starts_at || 0).getTime();
      if (end > now && (!sub.starts_at || start <= now)) {
        const current = storeStatus[sub.user_id];
        const currentEnd = current ? new Date(current.ends_at || 0).getTime() : 0;
        if (!current || end > currentEnd) {
          storeStatus[sub.user_id] = sub;
        }
      }
    }
    const globalLevel = {};
    for (const sub of (globalSubs || [])) {
      const end = new Date(sub.ends_at || 0).getTime();
      if (end <= now) continue;
      const level = sub.plan === 'boost_yearly' ? 5 : sub.plan === 'boost_monthly' ? 4 : sub.plan === 'boost_weekly' ? 3 : 0;
      if (level > (globalLevel[sub.user_id] || 0)) globalLevel[sub.user_id] = level;
    }
    const rows = (data || []).map(x => {
      const featured = x.is_featured === true && (!x.featured_until || new Date(x.featured_until).getTime() > now);
      const pinned = x.is_pinned === true && (!x.pinned_until || new Date(x.pinned_until).getTime() > now);
      const ownBoost = x.boost_level && (!x.boost_until || new Date(x.boost_until).getTime() > now) ? Number(x.boost_level) : 0;
      const level = Math.max(ownBoost, globalLevel[x.vendor_id] || 0);
      const boostUntil = level === globalLevel[x.vendor_id] ? (globalSubs || []).filter(s => s.user_id === x.vendor_id && new Date(s.ends_at || 0).getTime() > now).sort((a,b)=>new Date(b.ends_at).getTime()-new Date(a.ends_at).getTime())[0]?.ends_at || x.boost_until : x.boost_until;
      const turboSub = (globalSubs || []).filter(s => s.user_id === x.vendor_id && new Date(s.ends_at || 0).getTime() > now).sort((a,b)=>new Date(b.ends_at).getTime()-new Date(a.ends_at).getTime())[0];
      const storeSub = storeStatus[x.vendor_id];
      return {
        ...x,
        is_featured: featured,
        is_pinned: pinned,
        effective_boost_level: level,
        boost_until: boostUntil,
        turbo_active: Boolean(turboSub),
        turbo_plan: turboSub?.plan || null,
        turbo_starts_at: turboSub?.starts_at || null,
        turbo_until: turboSub?.ends_at || null,
        store_active: Boolean(storeSub),
        store_plan: storeSub?.plan || null,
        store_starts_at: storeSub?.starts_at || null,
        store_until: storeSub?.ends_at || null,
        store_description: pm[x.vendor_id]?.bio || '',
      };
    }).sort((a,b) => Number(b.is_pinned) - Number(a.is_pinned) || Number(b.is_featured) - Number(a.is_featured) || Number(b.effective_boost_level || 0) - Number(a.effective_boost_level || 0) || new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
    res.json(rows.map(x => {
      const level = Number(x.effective_boost_level || 0);
      const labels = {1:'⚡ توربو',2:'🔥 انفجاری',3:'💥 قدرتی',4:'👑 فروشنده ویژه',5:'🏆 فروشنده طلایی'};
      return { ...x, boost_label: x.turbo_active ? '⚡ توربو' : (labels[level] || ''), seller_phone: x.show_phone ? (x.contact_phone || pm[x.vendor_id]?.phone || '') : '', seller_name: pm[x.vendor_id]?.shop_name || pm[x.vendor_id]?.full_name || 'فروشنده بازارک' };
    }));
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در دریافت آگهی‌ها.' }); }
});

app.get('/api/listings/:id', async (req,res)=>{
  try {
    const db=getSupabaseAdmin();
    const {data,error}=await db.from('products')
      .select('*')
      .eq('id', req.params.id)
      .eq('is_active', true)
      .maybeSingle();
    if (error) throw error;
    if (!data) return res.status(404).json({error:'آگهی پیدا نشد.'});
    const storeSub = await getActiveStoreSubscription(db, data.vendor_id);
    if (data.is_store_product === true && !storeSub) return res.status(404).json({error:'این محصول فروشگاهی در حال حاضر نمایش داده نمی‌شود.'});

    let seller = {};
    if (data.vendor_id) {
      const {data:profile,error:profileError} = await db.from('profiles')
        .select('id,full_name,shop_name,phone,bio')
        .eq('id', data.vendor_id)
        .maybeSingle();
      if (profileError) console.error('listing seller lookup:', profileError);
      seller = profile || {};
    }

    res.set('Cache-Control', 'no-store');
    res.json({
      ...data,
      seller_name: seller.shop_name || seller.full_name || 'فروشنده بازارک',
      seller_phone: data.show_phone ? (data.contact_phone || seller.phone || '') : '',
      store_description: seller.bio || '',
      store_active: Boolean(storeSub),
      store_plan: storeSub?.plan || null,
      store_starts_at: storeSub?.starts_at || null,
      store_until: storeSub?.ends_at || null,
    });
  } catch (e) {
    console.error('GET /api/listings/:id failed:', e);
    res.status(500).json({error:'خطا در دریافت آگهی.', details: process.env.NODE_ENV === 'production' ? undefined : String(e?.message || e)});
  }
});

app.post('/api/listings/:id/view', async (req,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.rpc('bazarek_increment_listing_view',{p_listing_id:req.params.id});if(error)throw error;res.json({views_count:Number(data||0)});}catch(e){console.error(e);res.status(500).json({error:'خطا در ثبت بازدید.'});}});
app.get('/api/favorites', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('favorites').select('listing_id,created_at,products(id,title,price,image_url,category,is_featured,is_pinned)').eq('user_id',req.user.id).order('created_at',{ascending:false});if(error)throw error;res.json(data||[]);}catch(e){console.error(e);res.status(500).json({error:'خطا در دریافت علاقه‌مندی‌ها.'});}});
app.post('/api/favorites/:id', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {data:existing}=await db.from('favorites').select('listing_id').eq('user_id',req.user.id).eq('listing_id',req.params.id).maybeSingle();if(existing){await db.from('favorites').delete().eq('user_id',req.user.id).eq('listing_id',req.params.id);return res.json({favorite:false});}const {error}=await db.from('favorites').insert([{user_id:req.user.id,listing_id:req.params.id}]);if(error)throw error;res.status(201).json({favorite:true});}catch(e){console.error(e);res.status(500).json({error:'خطا در تغییر علاقه‌مندی.'});}});

app.post('/api/admin/users/:id/warnings', requireAdmin, async (req,res)=>{try{const message=String(req.body?.message||'').trim().slice(0,1000);if(!message)return res.status(400).json({error:'متن هشدار الزامی است.'});const db=getSupabaseAdmin();const {data,error}=await db.from('user_warnings').insert([{user_id:req.params.id,message}]).select().single();if(error)throw error;await db.from('user_notifications').insert([{user_id:req.params.id,type:'warning',title:'هشدار مدیریت بازارک',message}]);res.status(201).json(data);}catch(e){console.error(e);res.status(500).json({error:'خطا در ثبت هشدار.'});}});
app.get('/api/admin/warnings', requireAdmin, async (_,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('user_warnings').select('*').order('created_at',{ascending:false}).limit(200);if(error)throw error;res.json(data||[]);}catch(e){res.status(500).json({error:'خطا در دریافت هشدارها.'});}});
app.get('/api/admin/reports', requireAdmin, async (_,res)=>{
  try {
    const db=getSupabaseAdmin();
    const {data,error}=await db.from('reports').select('*').order('created_at',{ascending:false}).limit(200);
    if(error)throw error;
    const rows=data||[];
    const listingIds=[...new Set(rows.map(r=>r.listing_id).filter(Boolean))];
    const reporterIds=[...new Set(rows.map(r=>r.reporter_id).filter(Boolean))];
    const [{data:listings},{data:reporters}]=await Promise.all([
      listingIds.length ? db.from('products').select('id,title,description,price,category,subcategory,province,image_url,is_active,vendor_id,created_at').in('id',listingIds) : Promise.resolve({data:[]}),
      reporterIds.length ? db.from('profiles').select('id,full_name,shop_name,phone,city').in('id',reporterIds) : Promise.resolve({data:[]})
    ]);
    const ownerIds=[...new Set((listings||[]).map(x=>x.vendor_id).filter(Boolean))];
    const {data:owners}=ownerIds.length ? await db.from('profiles').select('id,full_name,shop_name,phone,city').in('id',ownerIds) : {data:[]};
    const lm=Object.fromEntries((listings||[]).map(x=>[x.id,x]));
    const rm=Object.fromEntries((reporters||[]).map(x=>[x.id,x]));
    const om=Object.fromEntries((owners||[]).map(x=>[x.id,x]));
    res.json(rows.map(r=>({
      ...r,
      listing: lm[r.listing_id] || null,
      reporter: rm[r.reporter_id] || null,
      listing_owner: lm[r.listing_id] ? (om[lm[r.listing_id].vendor_id] || null) : null
    })));
  } catch(e) { console.error(e); res.status(500).json({error:'خطا در دریافت گزارش‌ها.'}); }
});
app.patch('/api/admin/reports/:id', requireAdmin, async (req,res)=>{try{const status=String(req.body?.status||'reviewed');if(!['open','reviewed','dismissed'].includes(status))return res.status(400).json({error:'وضعیت گزارش نامعتبر است.'});const db=getSupabaseAdmin();const {data,error}=await db.from('reports').update({status,resolution_note:String(req.body?.resolution_note||'').slice(0,1000),updated_at:new Date().toISOString()}).eq('id',req.params.id).select().single();if(error)throw error;res.json(data);}catch(e){res.status(500).json({error:'خطا در تغییر گزارش.'});}});
app.post('/api/admin/reports/:id/action', requireAdmin, async (req,res)=>{
  try {
    const db=getSupabaseAdmin();
    const {data:report,error:re}=await db.from('reports').select('*').eq('id',req.params.id).maybeSingle();
    if(re)throw re; if(!report)return res.status(404).json({error:'گزارش پیدا نشد.'});
    const status=String(req.body?.status||'reviewed');
    if(!['reviewed','dismissed'].includes(status))return res.status(400).json({error:'وضعیت گزارش نامعتبر است.'});
    const disableListing=Boolean(req.body?.disable_listing);
    const warningMessage=String(req.body?.warning_message||'').trim().slice(0,1000);
    const thankReporter=Boolean(req.body?.thank_reporter);
    const resolutionNote=String(req.body?.resolution_note||'').trim().slice(0,1000);
    const {data:listing}=await db.from('products').select('id,title,vendor_id').eq('id',report.listing_id).maybeSingle();
    if(disableListing && listing) await db.from('products').update({is_active:false,moderation_disabled:true,moderation_reason:String(report.reason||'آگهی به دلیل گزارش و بررسی قوانین بازارک غیرفعال شد.').slice(0,500),updated_at:new Date().toISOString()}).eq('id',listing.id);
    if(warningMessage && listing?.vendor_id) {
      await db.from('user_warnings').insert([{user_id:listing.vendor_id,message:warningMessage}]);
      await db.from('user_notifications').insert([{
        user_id:listing.vendor_id,type:'warning',title:'هشدار مدیریت بازارک',message:warningMessage
      }]);
    }
    if(thankReporter && report.reporter_id) await db.from('user_notifications').insert([{
      user_id:report.reporter_id,type:'report',title:'تشکر بابت گزارش درست',
      message:'از شما بابت اطلاع‌رسانی مسئولانه تشکر می‌کنیم. گزارش شما بررسی شد و اقدام لازم انجام گرفت.'
    }]);
    const {data:updated,error:ue}=await db.from('reports').update({status,resolution_note:resolutionNote,updated_at:new Date().toISOString()}).eq('id',report.id).select().single();
    if(ue)throw ue;
    res.json({ok:true,report:updated,listing_disabled:disableListing,warning_sent:Boolean(warningMessage),reporter_notified:thankReporter});
  } catch(e) { console.error(e); res.status(500).json({error:'خطا در رسیدگی به گزارش.'}); }
});

app.get('/api/admin/security/events', requireAdmin, async (_,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('admin_login_events').select('*').order('created_at',{ascending:false}).limit(100);if(error)throw error;res.json(data||[]);}catch(e){res.status(500).json({error:'خطا در دریافت رویدادهای امنیتی.'});}});


// Marketplace social layer: seller profiles, follows, listing likes, ratings and comments.
app.get('/api/sellers/:id', async (req,res)=>{
  try{
    const db=getSupabaseAdmin(); const id=String(req.params.id);
    const {data:profile,error}=await db.from('profiles').select('id,full_name,shop_name,city,bio,avatar_url,verified,created_at').eq('id',id).maybeSingle();
    if(error) throw error; if(!profile) return res.status(404).json({error:'فروشنده پیدا نشد.'});
    const [{count:followers_count},{data:ratings},storeSub]=await Promise.all([
      db.from('seller_follows').select('*',{count:'exact',head:true}).eq('seller_id',id),
      db.from('seller_ratings').select('rating').eq('seller_id',id),
      getActiveStoreSubscription(db,id)
    ]);
    let saved_count=0;
    try { const r=await db.from('saved_stores').select('*',{count:'exact',head:true}).eq('seller_id',id); saved_count=r.count||0; } catch (_) {}
    const vals=(ratings||[]).map(x=>Number(x.rating)).filter(x=>Number.isFinite(x));
    const rating=vals.length?vals.reduce((a,x)=>a+x,0)/vals.length:0;
    let is_following=false; let is_saved=false;
    if(req.user?.id){
      const {data:f}=await db.from('seller_follows').select('user_id').eq('user_id',req.user.id).eq('seller_id',id).maybeSingle();
      is_following=!!f;
      try { const {data:sv}=await db.from('saved_stores').select('user_id').eq('user_id',req.user.id).eq('seller_id',id).maybeSingle(); is_saved=!!sv; } catch (_) {}
    }
    const {count:products_count}=await db.from('products').select('*',{count:'exact',head:true}).eq('vendor_id',id).eq('is_active',true).eq('is_store_product',true);
    res.json({...profile,followers_count:followers_count||0,rating,is_following,is_saved,is_store_active:Boolean(storeSub),store_plan:storeSub?.plan||null,store_until:storeSub?.ends_at||null,saved_count:saved_count||0,products_count:products_count||0});
  }catch(e){console.error(e);res.status(500).json({error:'خطا در دریافت پروفایل فروشنده.'});}
});
app.get('/api/sellers/:id/listings', async (req,res)=>{try{
  const db=getSupabaseAdmin();
  const sellerId=String(req.params.id);
  const {data,error}=await db.from('products').select('id,title,description,price,currency,image_url,created_at,vendor_id,is_featured,is_pinned,featured_until,pinned_until,boost_level,boost_until,allow_chat,show_phone,contact_phone,location_text,external_link,is_negotiable,views_count,province,brand,model,sizes,colors,material,condition,product_code,specifications,discount_percent,is_store_product,is_active').eq('vendor_id',sellerId).eq('is_active',true).eq('is_store_product',true).order('created_at',{ascending:false}).limit(100);
  if(error)throw error;
  const storeSub=await getActiveStoreSubscription(db,sellerId);
  const storeActive=Boolean(storeSub);
  res.json((data||[]).map(x=>({...x,store_active:storeActive,store_plan:storeSub?.plan||null,store_starts_at:storeSub?.starts_at||null,store_until:storeSub?.ends_at||null})));
}catch(e){console.error(e);res.status(500).json({error:'خطا در دریافت محصولات فروشگاه.'});}});

// Public directory of active professional stores. Product counts are strictly store-product counts.
app.get('/api/stores/active', async (req,res)=>{try{
  const db=getSupabaseAdmin(); const now=new Date().toISOString();
  const {data:subs,error:se}=await db.from('seller_subscriptions').select('user_id,plan,starts_at,ends_at,status').in('plan',['store_monthly','store_yearly']).eq('status','active').gt('ends_at',now).order('ends_at',{ascending:false}).limit(500);
  if(se)throw se;
  const active=(subs||[]).filter(s=>!s.starts_at||new Date(s.starts_at).getTime()<=Date.now());
  const ids=[...new Set(active.map(s=>s.user_id).filter(Boolean))];
  if(!ids.length)return res.json([]);
  const [{data:profiles,error:pe},{data:products,error:prode}]=await Promise.all([
    db.from('profiles').select('id,full_name,shop_name,city,bio,avatar_url,verified').in('id',ids),
    db.from('products').select('vendor_id').in('vendor_id',ids).eq('is_active',true).eq('is_store_product',true)
  ]);
  if(pe)throw pe;if(prode)throw prode;
  const counts={}; for(const p of (products||[])) counts[p.vendor_id]=(counts[p.vendor_id]||0)+1;
  const pm=Object.fromEntries((profiles||[]).map(p=>[p.id,p]));
  const best={}; for(const s of active){if(!best[s.user_id]||new Date(s.ends_at).getTime()>new Date(best[s.user_id].ends_at).getTime())best[s.user_id]=s;}
  res.json(ids.map(id=>{const p=pm[id]||{};const s=best[id];return {vendor_id:id,shop_name:p.shop_name||p.full_name||'فروشگاه بازارک',seller_name:p.shop_name||p.full_name||'فروشگاه بازارک',city:p.city||'',description:p.bio||'',avatar_url:p.avatar_url||'',verified:p.verified!==false,products_count:counts[id]||0,store_plan:s?.plan||null,store_starts_at:s?.starts_at||null,store_until:s?.ends_at||null};}));
}catch(e){console.error(e);res.status(500).json({error:'خطا در دریافت فروشگاه‌های فعال.'});}});

// One-click repair for a product that was accidentally created as an ordinary ad from the store flow.
app.patch('/api/store-products/:id/claim', requireUser, async (req,res)=>{try{
  const db=getSupabaseAdmin(); const id=String(req.params.id); const storeSub=await getActiveStoreSubscription(db,req.user.id);
  if(!storeSub)return res.status(403).json({error:'فروشگاه حرفه‌ای فعال نیست.'});
  const {data:product,error:pe}=await db.from('products').select('id,vendor_id,is_active,is_store_product').eq('id',id).maybeSingle();
  if(pe)throw pe;if(!product)return res.status(404).json({error:'محصول پیدا نشد.'});if(product.vendor_id!==req.user.id)return res.status(403).json({error:'این محصول متعلق به شما نیست.'});if(product.is_active!==true)return res.status(400).json({error:'فقط محصول فعال قابل انتقال است.'});
  const {data,error}=await db.from('products').update({is_store_product:true,is_featured:false,is_pinned:false,featured_until:null,pinned_until:null,boost_level:0,boost_until:null,updated_at:new Date().toISOString()}).eq('id',id).eq('vendor_id',req.user.id).select().single();
  if(error)throw error;res.json(data);
}catch(e){console.error(e);res.status(500).json({error:'انتقال محصول به فروشگاه ناموفق بود.'});}});


app.post('/api/sellers/:id/follow', requireUser, async (req,res)=>{try{const sellerId=String(req.params.id);if(sellerId===req.user.id)return res.status(400).json({error:'نمی‌توانید خودتان را دنبال کنید.'});const db=getSupabaseAdmin();const {data:seller}=await db.from('profiles').select('id').eq('id',sellerId).maybeSingle();if(!seller)return res.status(404).json({error:'فروشنده پیدا نشد.'});const {error}=await db.from('seller_follows').upsert([{user_id:req.user.id,seller_id:sellerId}],{onConflict:'user_id,seller_id'});if(error)throw error;res.status(201).json({following:true});}catch(e){console.error(e);res.status(500).json({error:'دنبال‌کردن فروشنده ناموفق بود.'});}});
app.delete('/api/sellers/:id/follow', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {error}=await db.from('seller_follows').delete().eq('user_id',req.user.id).eq('seller_id',req.params.id);if(error)throw error;res.json({following:false});}catch(e){console.error(e);res.status(500).json({error:'لغو دنبال‌کردن ناموفق بود.'});}});
app.post('/api/listings/:id/like', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {error}=await db.from('listing_likes').upsert([{user_id:req.user.id,listing_id:req.params.id}],{onConflict:'user_id,listing_id'});if(error)throw error;const {count}=await db.from('listing_likes').select('*',{count:'exact',head:true}).eq('listing_id',req.params.id);res.status(201).json({liked:true,likes_count:count||0});}catch(e){console.error(e);res.status(500).json({error:'پسندیدن آگهی ناموفق بود.'});}});
app.delete('/api/listings/:id/like', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {error}=await db.from('listing_likes').delete().eq('user_id',req.user.id).eq('listing_id',req.params.id);if(error)throw error;const {count}=await db.from('listing_likes').select('*',{count:'exact',head:true}).eq('listing_id',req.params.id);res.json({liked:false,likes_count:count||0});}catch(e){console.error(e);res.status(500).json({error:'لغو پسندیدن ناموفق بود.'});}});
app.get('/api/sellers/:id/comments', async (req,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('seller_comments').select('id,user_id,comment,created_at').eq('seller_id',req.params.id).order('created_at',{ascending:false}).limit(100);if(error)throw error;const ids=[...new Set((data||[]).map(x=>x.user_id).filter(Boolean))];let profiles=[];if(ids.length){const r=await db.from('profiles').select('id,full_name,shop_name').in('id',ids);profiles=r.data||[];}const map=Object.fromEntries(profiles.map(x=>[x.id,x]));res.json((data||[]).map(x=>({...x,user_name:map[x.user_id]?.shop_name||map[x.user_id]?.full_name||'کاربر بازارک'})));}catch(e){console.error(e);res.status(500).json({error:'خطا در دریافت دیدگاه‌ها.'});}});
app.post('/api/sellers/:id/comments', requireUser, async (req,res)=>{try{const comment=String(req.body?.comment||'').trim().slice(0,500);if(!comment)return res.status(400).json({error:'دیدگاه خالی است.'});if(req.params.id===req.user.id)return res.status(400).json({error:'نمی‌توانید برای خودتان دیدگاه ثبت کنید.'});const db=getSupabaseAdmin();const {data,error}=await db.from('seller_comments').insert([{seller_id:req.params.id,user_id:req.user.id,comment}]).select().single();if(error)throw error;res.status(201).json(data);}catch(e){console.error(e);res.status(500).json({error:'ثبت دیدگاه ناموفق بود.'});}});
app.post('/api/sellers/:id/rating', requireUser, async (req,res)=>{try{const rating=Math.trunc(Number(req.body?.rating));if(rating<1||rating>5)return res.status(400).json({error:'امتیاز باید بین ۱ تا ۵ باشد.'});if(req.params.id===req.user.id)return res.status(400).json({error:'نمی‌توانید به خودتان امتیاز بدهید.'});const db=getSupabaseAdmin();const {data,error}=await db.from('seller_ratings').upsert([{seller_id:req.params.id,user_id:req.user.id,rating}],{onConflict:'seller_id,user_id'}).select().single();if(error)throw error;res.status(201).json(data);}catch(e){console.error(e);res.status(500).json({error:'ثبت امتیاز ناموفق بود.'});}});


// Current user's social lists used by the clickable statistics on «حساب من».

// Professional store reviews and saved stores.
async function getActiveStoreSubscription(db, sellerId) {
  const { data, error } = await db.from('seller_subscriptions')
    .select('plan,starts_at,ends_at,status')
    .eq('user_id', sellerId)
    .eq('status', 'active')
    .in('plan', ['store_monthly','store_yearly'])
    .order('ends_at', { ascending: false })
    .limit(10);
  if (error) throw error;
  const now = Date.now();
  return (data || []).find(s => new Date(s.ends_at || 0).getTime() > now && (!s.starts_at || new Date(s.starts_at).getTime() <= now)) || null;
}

app.get('/api/products/:id/reviews', async (req,res)=>{
  try {
    const db=getSupabaseAdmin();
    const productId=String(req.params.id);
    const {data:product,error:pe}=await db.from('products').select('id,vendor_id,is_active').eq('id',productId).maybeSingle();
    if(pe) throw pe;
    if(!product || product.is_active !== true) return res.status(404).json({error:'محصول پیدا نشد.'});
    const storeSub=await getActiveStoreSubscription(db, product.vendor_id);
    if(!storeSub) return res.json([]);
    const {data,error}=await db.from('product_reviews').select('id,product_id,user_id,rating,review,seller_reply,seller_replied_at,created_at,updated_at').eq('product_id',productId).order('created_at',{ascending:false}).limit(200);
    if(error) throw error;
    const ids=[...new Set((data||[]).map(x=>x.user_id).filter(Boolean))];
    let profiles=[];
    if(ids.length){const r=await db.from('profiles').select('id,full_name,shop_name,avatar_url').in('id',ids);profiles=r.data||[];}
    const map=Object.fromEntries(profiles.map(x=>[x.id,x]));
    const rows=(data||[]).map(x=>({...x,user_name:map[x.user_id]?.shop_name||map[x.user_id]?.full_name||'کاربر بازارک',user_avatar:map[x.user_id]?.avatar_url||''}));
    const vals=rows.map(x=>Number(x.rating)).filter(Number.isFinite);
    res.json({data:rows,average_rating:vals.length?vals.reduce((a,b)=>a+b,0)/vals.length:0,reviews_count:rows.length});
  } catch(e) { console.error(e); res.status(500).json({error:'خطا در دریافت نظرات محصول.'}); }
});

app.post('/api/products/:id/reviews', requireUser, async (req,res)=>{
  try {
    const db=getSupabaseAdmin();
    const productId=String(req.params.id);
    const rating=Math.trunc(Number(req.body?.rating));
    const review=String(req.body?.review||'').trim().slice(0,1200);
    if(rating<1 || rating>5) return res.status(400).json({error:'امتیاز باید بین ۱ تا ۵ باشد.'});
    if(!review) return res.status(400).json({error:'متن نظر الزامی است.'});
    const {data:product,error:pe}=await db.from('products').select('id,vendor_id,is_active').eq('id',productId).maybeSingle();
    if(pe) throw pe;
    if(!product || product.is_active !== true) return res.status(404).json({error:'محصول پیدا نشد.'});
    if(String(product.vendor_id)===String(req.user.id)) return res.status(400).json({error:'صاحب محصول نمی‌تواند برای محصول خودش نظر ثبت کند.'});
    const storeSub=await getActiveStoreSubscription(db, product.vendor_id);
    if(!storeSub) return res.status(403).json({error:'نظر و امتیاز فقط برای محصولات فروشگاه حرفه‌ای فعال است.'});
    const {data,error}=await db.from('product_reviews').upsert([{
      product_id:productId,user_id:req.user.id,rating,review,seller_reply:null,seller_replied_at:null,updated_at:new Date().toISOString()
    }],{onConflict:'product_id,user_id'}).select().single();
    if(error) throw error;
    res.status(201).json(data);
  } catch(e) { console.error(e); res.status(500).json({error:'ثبت نظر ناموفق بود.'}); }
});

app.patch('/api/product-reviews/:id/reply', requireUser, async (req,res)=>{
  try {
    const db=getSupabaseAdmin();
    const reviewId=String(req.params.id);
    const reply=String(req.body?.reply||'').trim().slice(0,1200);
    if(!reply) return res.status(400).json({error:'متن پاسخ الزامی است.'});
    const {data:review,error:re}=await db.from('product_reviews').select('id,product_id').eq('id',reviewId).maybeSingle();
    if(re) throw re;
    if(!review) return res.status(404).json({error:'نظر پیدا نشد.'});
    const {data:product,error:pe}=await db.from('products').select('id,vendor_id').eq('id',review.product_id).maybeSingle();
    if(pe) throw pe;
    if(!product || String(product.vendor_id)!==String(req.user.id)) return res.status(403).json({error:'شما صاحب این محصول نیستید.'});
    const storeSub=await getActiveStoreSubscription(db, req.user.id);
    if(!storeSub) return res.status(403).json({error:'برای پاسخ‌دادن به نظرات باید فروشگاه حرفه‌ای فعال باشد.'});
    const {data,error}=await db.from('product_reviews').update({seller_reply:reply,seller_replied_at:new Date().toISOString(),updated_at:new Date().toISOString()}).eq('id',reviewId).select().single();
    if(error) throw error;
    res.json(data);
  } catch(e) { console.error(e); res.status(500).json({error:'ثبت پاسخ ناموفق بود.'}); }
});

app.get('/api/me/store-reviews', requireUser, async (req,res)=>{
  try {
    const db=getSupabaseAdmin();
    const storeSub=await getActiveStoreSubscription(db, req.user.id);
    if(!storeSub) return res.json([]);
    const {data:products,error:pe}=await db.from('products').select('id,title,image_url').eq('vendor_id',req.user.id).order('created_at',{ascending:false}).limit(500);
    if(pe) throw pe;
    const ids=(products||[]).map(x=>x.id).filter(Boolean);
    if(!ids.length) return res.json([]);
    const {data:reviews,error}=await db.from('product_reviews').select('id,product_id,user_id,rating,review,seller_reply,seller_replied_at,created_at,updated_at').in('product_id',ids).order('created_at',{ascending:false}).limit(500);
    if(error) throw error;
    const userIds=[...new Set((reviews||[]).map(x=>x.user_id).filter(Boolean))];
    let profiles=[];
    if(userIds.length){const r=await db.from('profiles').select('id,full_name,shop_name,avatar_url').in('id',userIds);profiles=r.data||[];}
    const pm=Object.fromEntries((products||[]).map(x=>[x.id,x]));
    const um=Object.fromEntries(profiles.map(x=>[x.id,x]));
    res.json((reviews||[]).map(x=>({...x,product_title:pm[x.product_id]?.title||'محصول',product_image:pm[x.product_id]?.image_url||'',user_name:um[x.user_id]?.shop_name||um[x.user_id]?.full_name||'کاربر بازارک',user_avatar:um[x.user_id]?.avatar_url||''})));
  } catch(e) { console.error(e); res.status(500).json({error:'خطا در دریافت نظرات فروشگاه.'}); }
});

app.post('/api/stores/:id/save', requireUser, async (req,res)=>{
  try {
    const db=getSupabaseAdmin(); const sellerId=String(req.params.id);
    if(sellerId===String(req.user.id)) return res.status(400).json({error:'فروشگاه خودتان را نمی‌توانید ذخیره کنید.'});
    const storeSub=await getActiveStoreSubscription(db,sellerId);
    if(!storeSub) return res.status(404).json({error:'فروشگاه حرفه‌ای فعال پیدا نشد.'});
    const {error}=await db.from('saved_stores').upsert([{user_id:req.user.id,seller_id:sellerId}],{onConflict:'user_id,seller_id'});
    if(error) throw error;
    const {count}=await db.from('saved_stores').select('*',{count:'exact',head:true}).eq('seller_id',sellerId);
    res.status(201).json({saved:true,saved_count:count||0});
  } catch(e) { console.error(e); res.status(500).json({error:'ذخیره فروشگاه ناموفق بود.'}); }
});

app.delete('/api/stores/:id/save', requireUser, async (req,res)=>{
  try {
    const db=getSupabaseAdmin(); const sellerId=String(req.params.id);
    const {error}=await db.from('saved_stores').delete().eq('user_id',req.user.id).eq('seller_id',sellerId);
    if(error) throw error;
    const {count}=await db.from('saved_stores').select('*',{count:'exact',head:true}).eq('seller_id',sellerId);
    res.json({saved:false,saved_count:count||0});
  } catch(e) { console.error(e); res.status(500).json({error:'لغو ذخیره فروشگاه ناموفق بود.'}); }
});

app.get('/api/me/saved-stores', requireUser, async (req,res)=>{
  try {
    const db=getSupabaseAdmin();
    const {data,error}=await db.from('saved_stores').select('seller_id,created_at').eq('user_id',req.user.id).order('created_at',{ascending:false}).limit(500);
    if(error) throw error;
    const ids=[...new Set((data||[]).map(x=>x.seller_id).filter(Boolean))];
    if(!ids.length) return res.json([]);
    const {data:profiles,error:pe}=await db.from('profiles').select('id,full_name,shop_name,city,bio,avatar_url').in('id',ids);
    if(pe) throw pe;
    const pm=Object.fromEntries((profiles||[]).map(x=>[x.id,x]));
    const rows=[];
    for(const x of (data||[])) {
      const sub=await getActiveStoreSubscription(db,x.seller_id);
      if(sub) rows.push({...pm[x.seller_id],seller_id:x.seller_id,store_plan:sub.plan,store_until:sub.ends_at,saved_at:x.created_at});
    }
    res.json(rows);
  } catch(e) { console.error(e); res.status(500).json({error:'خطا در دریافت فروشگاه‌های ذخیره‌شده.'}); }
});

app.get('/api/me/social/:type', requireUser, async (req,res)=>{
  try {
    const type=String(req.params.type||'');
    const db=getSupabaseAdmin();
    let rows=[];
    if(type==='followers'){
      const {data,error}=await db.from('seller_follows').select('user_id,created_at').eq('seller_id',req.user.id).order('created_at',{ascending:false}).limit(500);
      if(error) throw error;
      const ids=[...new Set((data||[]).map(x=>x.user_id).filter(Boolean))];
      if(ids.length){const r=await db.from('profiles').select('id,full_name,shop_name,avatar_url,city').in('id',ids);const map=Object.fromEntries((r.data||[]).map(x=>[x.id,x]));rows=(data||[]).map(x=>({...map[x.user_id],created_at:x.created_at}));}
    } else if(type==='following'){
      const {data,error}=await db.from('seller_follows').select('seller_id,created_at').eq('user_id',req.user.id).order('created_at',{ascending:false}).limit(500);
      if(error) throw error;
      const ids=[...new Set((data||[]).map(x=>x.seller_id).filter(Boolean))];
      if(ids.length){const r=await db.from('profiles').select('id,full_name,shop_name,avatar_url,city').in('id',ids);const map=Object.fromEntries((r.data||[]).map(x=>[x.id,x]));rows=(data||[]).map(x=>({...map[x.seller_id],created_at:x.created_at}));}
    } else if(type==='ratings'){
      const {data,error}=await db.from('seller_ratings').select('user_id,rating,created_at').eq('seller_id',req.user.id).order('created_at',{ascending:false}).limit(500);
      if(error) throw error;
      const ids=[...new Set((data||[]).map(x=>x.user_id).filter(Boolean))];
      let map={}; if(ids.length){const r=await db.from('profiles').select('id,full_name,shop_name,avatar_url,city').in('id',ids);map=Object.fromEntries((r.data||[]).map(x=>[x.id,x]));}
      rows=(data||[]).map(x=>({...map[x.user_id],rating:x.rating,created_at:x.created_at}));
    } else if(type==='comments'){
      const {data,error}=await db.from('seller_comments').select('id,user_id,comment,created_at').eq('seller_id',req.user.id).order('created_at',{ascending:false}).limit(500);
      if(error) throw error;
      const ids=[...new Set((data||[]).map(x=>x.user_id).filter(Boolean))];
      let map={}; if(ids.length){const r=await db.from('profiles').select('id,full_name,shop_name,avatar_url,city').in('id',ids);map=Object.fromEntries((r.data||[]).map(x=>[x.id,x]));}
      rows=(data||[]).map(x=>({...map[x.user_id],comment:x.comment,created_at:x.created_at}));
    } else if(type==='likes'){
      const {data:ads,error:adsError}=await db.from('products').select('id,title,price,currency,image_url,created_at').eq('vendor_id',req.user.id).limit(500);
      if(adsError) throw adsError;
      const ids=(ads||[]).map(x=>x.id).filter(Boolean);
      if(ids.length){const {data,error}=await db.from('listing_likes').select('listing_id,user_id,created_at').in('listing_id',ids).order('created_at',{ascending:false}).limit(1000);if(error) throw error;const adMap=Object.fromEntries((ads||[]).map(x=>[x.id,x]));rows=(data||[]).map(x=>({...adMap[x.listing_id],listing_id:x.listing_id,user_id:x.user_id,created_at:x.created_at,listing_title:adMap[x.listing_id]?.title||'آگهی'}));}
    } else return res.status(400).json({error:'نوع فهرست نامعتبر است.'});
    res.json(rows.filter(Boolean));
  } catch(e) { console.error(e); res.status(500).json({error:'خطا در دریافت اطلاعات اجتماعی.'}); }
});

app.get('/api/support/requests', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('support_requests').select('*').eq('user_id',req.user.id).order('created_at',{ascending:false}).limit(100);if(error)throw error;res.json(data||[]);}catch(e){console.error(e);res.status(500).json({error:'خطا در دریافت درخواست‌های پشتیبانی.'});}});
app.post('/api/support/requests', requireUser, async (req,res)=>{try{const type=String(req.body?.type||'support');const allowed=['bug','suggestion','support','report'];if(!allowed.includes(type))return res.status(400).json({error:'نوع درخواست نامعتبر است.'});const title=String(req.body?.title||'').trim().slice(0,160);const message=String(req.body?.message||'').trim().slice(0,4000);if(!title||!message)return res.status(400).json({error:'موضوع و توضیح الزامی است.'});const db=getSupabaseAdmin();const {data,error}=await db.from('support_requests').insert([{user_id:req.user.id,type,title,message}]).select().single();if(error)throw error;res.status(201).json(data);}catch(e){console.error(e);res.status(500).json({error:'خطا در ثبت درخواست پشتیبانی.'});}});
app.get('/api/admin/support/requests', requireAdmin, async (_,res)=>{
  try {
    const db=getSupabaseAdmin();
    // support_requests.user_id references auth.users, not public.profiles, so
    // PostgREST cannot safely embed profiles here. Fetch them separately.
    const {data:requests,error}=await db.from('support_requests').select('*').order('created_at',{ascending:false}).limit(500);
    if(error) throw error;
    const rows=requests||[];
    const userIds=[...new Set(rows.map(x=>x.user_id).filter(Boolean))];
    let profiles=[];
    if(userIds.length){
      const {data,error:profileError}=await db.from('profiles').select('id,full_name,phone,city,shop_name,avatar_url').in('id',userIds);
      if(profileError) throw profileError;
      profiles=data||[];
    }
    const profileMap=Object.fromEntries(profiles.map(p=>[p.id,p]));
    res.json(rows.map(x=>({...x,profiles:profileMap[x.user_id]||null,user:profileMap[x.user_id]||null})));
  } catch(e) {
    console.error('admin support requests error:',e);
    res.status(500).json({error:'خطا در دریافت پشتیبانی.'});
  }
});
app.patch('/api/admin/support/requests/:id', requireAdmin, async (req,res)=>{try{const status=String(req.body?.status||'in_progress');if(!['open','in_progress','answered','resolved','closed'].includes(status))return res.status(400).json({error:'وضعیت نامعتبر است.'});const reply=String(req.body?.admin_reply||'').trim().slice(0,4000);const db=getSupabaseAdmin();const {data:old}=await db.from('support_requests').select('user_id,title').eq('id',req.params.id).maybeSingle();const {data,error}=await db.from('support_requests').update({status,admin_reply:reply,updated_at:new Date().toISOString()}).eq('id',req.params.id).select().single();if(error)throw error;if(old?.user_id&&reply){await db.from('user_notifications').insert([{user_id:old.user_id,type:'support',title:'پاسخ پشتیبانی بازارک',message:`پاسخ درخواست «${old.title||'پشتیبانی'}» آماده شد.`}]);}res.json(data);}catch(e){console.error(e);res.status(500).json({error:'خطا در پاسخ به درخواست.'});}});

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


app.get('/api/payment-info', requireUser, async (_,res)=>{
  try {
    // Payment settings are managed in Render Environment Variables.
    // Render values intentionally take priority so a stale/empty Supabase row
    // can never hide the real payment details. A few backwards-compatible
    // aliases are accepted for older Render deployments.
    const env = (...names) => {
      for (const name of names) {
        const value = String(process.env[name] || '').trim();
        if (value) return value;
      }
      return '';
    };

    const bankName = env('PAYMENT_BANK_NAME','BANK_NAME');
    const accountName = env('PAYMENT_ACCOUNT_NAME','BANK_ACCOUNT_NAME','ACCOUNT_NAME');
    const accountNumber = env('PAYMENT_ACCOUNT_NUMBER','BANK_ACCOUNT_NUMBER','ACCOUNT_NUMBER');
    const cardNumber = env('PAYMENT_CARD_NUMBER','BANK_CARD_NUMBER','CARD_NUMBER','PAYMENT_CARD');
    const branch = env('PAYMENT_BANK_BRANCH','BANK_BRANCH');
    const swiftCode = env('PAYMENT_SWIFT_CODE','SWIFT_CODE');
    const instructions = env('PAYMENT_INSTRUCTIONS','PAYMENT_NOTE','BANK_TRANSFER_INSTRUCTIONS') ||
      '۱) مبلغ دقیق را به کارت/حساب بالا انتقال دهید.\n۲) رسید یا شماره پیگیری را نگه دارید.\n۳) شماره پیگیری را در برنامه وارد کنید.\n۴) درخواست را ثبت کنید.\n۵) پس از تأیید پرداخت توسط مدیریت، Boost فعال می‌شود.';

    const bank = {
      name: bankName || 'حساب بانکی بازارک',
      account_name: accountName,
      account_number: accountNumber,
      branch,
      swift_code: swiftCode,
      card_number: cardNumber
    };

    res.json({
      methods:['bank_transfer','manual'],
      source:'render_env',
      bank,
      bank_name: bank.name,
      account_name: bank.account_name,
      account_number: bank.account_number,
      card_number: bank.card_number,
      instructions
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error:'خطا در دریافت اطلاعات پرداخت.' });
  }
});

app.get('/api/monetization/packages', requireUser, async (_,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('promotion_packages').select('*').eq('is_active',true).order('price_afn');if(error)throw error;res.json(data||[]);}catch(e){res.status(500).json({error:'خطا در دریافت بسته‌های تبلیغاتی.'});}});
app.get('/api/wallet', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const [{data:w,error:we},{data:tx,error:te}]=await Promise.all([db.from('wallets').select('*').eq('user_id',req.user.id).maybeSingle(),db.from('wallet_transactions').select('*').eq('user_id',req.user.id).order('created_at',{ascending:false}).limit(100)]);if(we)throw we;if(te)throw te;res.json({wallet:w||{user_id:req.user.id,balance_afn:0},transactions:tx||[]});}catch(e){console.error(e);res.status(500).json({error:'خطا در دریافت کیف پول.'});}});
app.get('/api/promotions/orders', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('promotion_orders').select('*,promotion_packages(title),products(title)').eq('user_id',req.user.id).order('created_at',{ascending:false}).limit(100);if(error)throw error;res.json(data||[]);}catch(e){res.status(500).json({error:'خطا در دریافت سفارش‌ها.'});}});
app.post('/api/promotions/orders', requireUser, async (req,res)=>{try{const {listing_id,package_id,payment_method='bank_transfer',payment_reference=''}=req.body||{};if(!listing_id||!package_id)return res.status(400).json({error:'آگهی و بسته تبلیغاتی الزامی است.'});const db=getSupabaseAdmin();const {data:pkg,error:pe}=await db.from('promotion_packages').select('*').eq('id',package_id).eq('is_active',true).maybeSingle();if(pe)throw pe;if(!pkg)return res.status(404).json({error:'بسته تبلیغاتی پیدا نشد.'});if(Number(pkg.price_afn||0)<=0)return res.status(400).json({error:'این بسته تبلیغاتی قیمت معتبر ندارد.'});const {data:listing,error:le}=await db.from('products').select('id,vendor_id,is_store_product').eq('id',listing_id).maybeSingle();if(le)throw le;if(!listing||listing.vendor_id!==req.user.id)return res.status(403).json({error:'این آگهی متعلق به شما نیست.'});if(listing.is_store_product===true)return res.status(400).json({error:'محصول فروشگاهی قابل بوست یا ارتقای آگهی نیست؛ فقط آگهی‌های عادی قابل بوست هستند.'});
if(!['manual','bank_transfer'].includes(payment_method))return res.status(400).json({error:'برای فعال‌سازی تبلیغ باید مبلغ را به حساب بازارک انتقال دهید و منتظر تأیید مدیریت بمانید.'});
const reference=String(payment_reference||'').trim();if(!reference)return res.status(400).json({error:'شماره پیگیری/رسید انتقال بانکی را وارد کنید.'});
const {data:order,error}=await db.from('promotion_orders').insert([{user_id:req.user.id,listing_id,package_id,amount_afn:pkg.price_afn,payment_method:'manual',payment_reference:reference.slice(0,200),status:'pending'}]).select().single();if(error)throw error;
res.status(201).json(order);}catch(e){console.error(e);res.status(500).json({error:'خطا در ثبت سفارش ارتقای آگهی.'});}});
app.get('/api/subscriptions', requireUser, async (req,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('seller_subscriptions').select('*').eq('user_id',req.user.id).order('created_at',{ascending:false}).limit(20);if(error)throw error;res.json(data||[]);}catch(e){res.status(500).json({error:'خطا در دریافت اشتراک‌ها.'});}});
app.post('/api/subscriptions', requireUser, async (req,res)=>{try{
  const plans={
    basic:{price:150,days:30},pro:{price:250,days:30},business:{price:450,days:30},
    boost_weekly:{price:150,days:7,boost_level:3},
    boost_monthly:{price:500,days:30,boost_level:4},
    boost_yearly:{price:4500,days:365,boost_level:5},
    store_monthly:{price:600,days:30,store:true},
    store_yearly:{price:6000,days:365,store:true}
  };
  const plan=String(req.body?.plan||'').trim().toLowerCase();
  if(!plans[plan])return res.status(400).json({error:'پلن نامعتبر است.'});
  const p=plans[plan];
  const reference=String(req.body?.payment_reference||'').trim();
  if(!reference)return res.status(400).json({error:'برای خرید اشتراک باید مبلغ را انتقال دهید و شماره پیگیری را وارد کنید.'});
  const db=getSupabaseAdmin();
  const {data:existing}=await db.from('seller_subscriptions').select('id').eq('user_id',req.user.id).eq('plan',plan).eq('status','pending').limit(1);
  if(existing?.length)return res.status(409).json({error:'یک درخواست پرداخت برای این پلن در انتظار تأیید است.'});
  // A pending request has no active time yet. The clock starts only when
  // management approves the payment in the admin panel.
  const {data,error}=await db.from('seller_subscriptions').insert([{user_id:req.user.id,plan,price_afn:p.price,starts_at:null,ends_at:null,status:'pending',payment_method:'manual',payment_reference:reference.slice(0,200)}]).select().single();
  if(error)throw error;
  res.status(201).json(data);
}catch(e){console.error(e);res.status(500).json({error:'خطا در ثبت درخواست اشتراک.'});}});

app.patch('/api/admin/subscriptions/:id', requireAdmin, async (req,res)=>{try{
  const status=String(req.body?.status||'active');
  if(!['active','rejected','cancelled'].includes(status))return res.status(400).json({error:'وضعیت نامعتبر است.'});
  const db=getSupabaseAdmin();
  const {data:sub,error:se}=await db.from('seller_subscriptions').select('*').eq('id',req.params.id).maybeSingle();
  if(se)throw se;if(!sub)return res.status(404).json({error:'اشتراک پیدا نشد.'});
  const patch={status};
  if(status==='active'){
    const days=sub.plan==='boost_yearly'||sub.plan==='store_yearly'?365:sub.plan==='boost_monthly'||sub.plan==='store_monthly'?30:sub.plan==='boost_weekly'?7:30;
    let start=new Date();
    // Renewals/plan upgrades are queued after the user's current store period
    // so remaining paid time is never lost. Expired stores start immediately.
    if(String(sub.plan).startsWith('store_')) {
      const {data:currentStore}=await db.from('seller_subscriptions').select('ends_at,status').eq('user_id',sub.user_id).in('plan',['store_monthly','store_yearly']).eq('status','active').gt('ends_at',new Date().toISOString()).order('ends_at',{ascending:false}).limit(1).maybeSingle();
      if(currentStore?.ends_at) {
        const currentEnd=new Date(currentStore.ends_at);
        if(currentEnd.getTime()>start.getTime()) start=currentEnd;
      }
    }
    const end=new Date(start.getTime()+days*86400000);
    patch.starts_at=start.toISOString();patch.ends_at=end.toISOString();
  }
  const {data,error}=await db.from('seller_subscriptions').update(patch).eq('id',req.params.id).select().single();
  if(error)throw error;
  if(status==='active' && ['pro','business'].includes(sub.plan)) await db.from('profiles').update({plan:sub.plan}).eq('id',sub.user_id);
  await db.from('user_notifications').insert([{user_id:sub.user_id,type:'payment',title:status==='active'?'پرداخت اشتراک تأیید شد':'نتیجه درخواست اشتراک',message:status==='active' ? (String(sub.plan).startsWith('store_') && patch.starts_at && new Date(patch.starts_at).getTime()>Date.now() ? `پرداخت اشتراک «${sub.plan}» تأیید شد و پس از پایان زمان باقی‌مانده فروشگاه فعال می‌شود.` : `پرداخت اشتراک «${sub.plan}» تأیید شد و فعال گردید.`) : `درخواست اشتراک «${sub.plan}» توسط مدیریت ${status==='rejected'?'رد':'لغو'} شد.`}]);
  res.json(data);
}catch(e){console.error(e);res.status(500).json({error:'خطا در تغییر وضعیت اشتراک.'});}});
app.get('/api/admin/monetization', requireAdmin, async (_,res)=>{
  try {
    const db=getSupabaseAdmin();
    const [{data:orders,error:oe},{data:tx,error:te},{data:subs,error:se}]=await Promise.all([
      db.from('promotion_orders').select('id,user_id,listing_id,package_id,amount_afn,payment_method,payment_reference,status,created_at,updated_at').order('created_at',{ascending:false}).limit(300),
      db.from('wallet_transactions').select('id,user_id,type,amount_afn,description,reference_id,created_at,is_archived').eq('is_archived',false).order('created_at',{ascending:false}).limit(300),
      db.from('seller_subscriptions').select('*').order('created_at',{ascending:false}).limit(100)
    ]);
    if(oe)throw oe;if(te)throw te;if(se)throw se;
    const rows=[...(orders||[]).map(x=>x.user_id),...(subs||[]).map(x=>x.user_id),...(tx||[]).map(x=>x.user_id)].filter(Boolean);
    const userIds=[...new Set(rows)];
    const listingIds=[...new Set((orders||[]).map(x=>x.listing_id).filter(Boolean))];
    const packageIds=[...new Set((orders||[]).map(x=>x.package_id).filter(Boolean))];
    const [{data:profiles},{data:listings},{data:packages}]=await Promise.all([
      userIds.length?db.from('profiles').select('id,full_name,shop_name,phone,city').in('id',userIds):Promise.resolve({data:[]}),
      listingIds.length?db.from('products').select('id,title,price,category,subcategory,province,image_url,is_active,vendor_id,is_featured,is_pinned,featured_until,pinned_until,boost_level,boost_until,updated_at').in('id',listingIds):Promise.resolve({data:[]}),
      packageIds.length?db.from('promotion_packages').select('id,title,description,feature_days,pin_days,boost_level').in('id',packageIds):Promise.resolve({data:[]})
    ]);
    const pm=Object.fromEntries((profiles||[]).map(x=>[x.id,x]));
    const lm=Object.fromEntries((listings||[]).map(x=>[x.id,x]));
    const km=Object.fromEntries((packages||[]).map(x=>[x.id,x]));
    const enrichedOrders=(orders||[]).map(x=>({...x,user:pm[x.user_id]||null,listing:lm[x.listing_id]||null,package:km[x.package_id]||null}));
    const enrichedSubs=(subs||[]).map(x=>({...x,user:pm[x.user_id]||null}));
    const enrichedTx=(tx||[]).map(x=>({...x,user:pm[x.user_id]||null}));
    const paidPromotions=enrichedOrders.filter(x=>x.status==='paid').reduce((a,x)=>a+Number(x.amount_afn||0),0);
    const paidSubscriptions=enrichedSubs.filter(x=>x.status==='active').reduce((a,x)=>a+Number(x.price_afn||0),0);
    const pendingPromotions=enrichedOrders.filter(x=>x.status==='pending').reduce((a,x)=>a+Number(x.amount_afn||0),0);
    const pendingSubscriptions=enrichedSubs.filter(x=>x.status==='pending').reduce((a,x)=>a+Number(x.price_afn||0),0);
    res.json({revenue_afn:paidPromotions+paidSubscriptions,promotion_revenue_afn:paidPromotions,subscription_revenue_afn:paidSubscriptions,pending_afn:pendingPromotions+pendingSubscriptions,orders:enrichedOrders,transactions:enrichedTx,subscriptions:enrichedSubs});
  }catch(e){console.error(e);res.status(500).json({error:'خطا در دریافت آمار درآمد.'});}
});
app.patch('/api/admin/transactions/:id/archive', requireAdmin, async (req,res)=>{try{const db=getSupabaseAdmin();const {data,error}=await db.from('wallet_transactions').update({is_archived:true}).eq('id',req.params.id).select().single();if(error)throw error;res.json(data);}catch(e){console.error(e);res.status(500).json({error:'خطا در بایگانی تراکنش.'});}});

app.post('/api/admin/wallets/:id/credit', requireAdmin, async (req,res)=>{try{const amount=Math.trunc(Number(req.body?.amount_afn||0));if(amount<=0)return res.status(400).json({error:'مبلغ نامعتبر است.'});const db=getSupabaseAdmin();const balance=await db.rpc('bazarek_wallet_credit',{p_user_id:req.params.id,p_amount:amount,p_type:'credit',p_description:String(req.body?.description||'شارژ کیف پول توسط مدیریت').slice(0,200),p_reference:'admin'});res.status(201).json({balance_afn:balance.data});}catch(e){console.error(e);res.status(500).json({error:'خطا در شارژ کیف پول.'});}});
app.patch('/api/admin/promotions/orders/:id', requireAdmin, async (req,res)=>{try{const status=String(req.body?.status||'paid');if(!['paid','rejected','cancelled'].includes(status))return res.status(400).json({error:'وضعیت نامعتبر است.'});const db=getSupabaseAdmin();const {data:order,error:oe}=await db.from('promotion_orders').select('*,promotion_packages(*)').eq('id',req.params.id).maybeSingle();if(oe)throw oe;if(!order)return res.status(404).json({error:'سفارش پیدا نشد.'});const {data:targetListing}=await db.from('products').select('id,is_store_product').eq('id',order.listing_id).maybeSingle();if(targetListing?.is_store_product===true)return res.status(400).json({error:'محصول فروشگاهی قابل بوست یا ارتقای آگهی نیست.'});const {data:updated,error}=await db.from('promotion_orders').update({status,updated_at:new Date().toISOString()}).eq('id',req.params.id).select().single();if(error)throw error;if(status==='paid'&&order.status!=='paid'){const pkg=order.promotion_packages;const now=Date.now();const days=Math.max(Number(pkg.feature_days||0),Number(pkg.pin_days||0));await db.from('products').update({is_featured:pkg.feature_days>0,is_pinned:pkg.pin_days>0,featured_until:pkg.feature_days>0?new Date(now+pkg.feature_days*86400000).toISOString():null,pinned_until:pkg.pin_days>0?new Date(now+pkg.pin_days*86400000).toISOString():null,boost_level:Number(pkg.boost_level||0),boost_until:days>0?new Date(now+days*86400000).toISOString():null,updated_at:new Date().toISOString()}).eq('id',order.listing_id);}await db.from('user_notifications').insert([{user_id:order.user_id,type:'payment',title:status==='paid'?'ارتقای آگهی فعال شد':'نتیجه سفارش ارتقا',message:status==='paid'?`پرداخت شما تأیید شد و ارتقای آگهی «${order.listing_id}» فعال گردید.`:`سفارش ارتقای آگهی شما توسط مدیریت ${status==='rejected'?'رد':'لغو'} شد.`}]);res.json(updated);}catch(e){console.error(e);res.status(500).json({error:'خطا در تغییر سفارش.'});}});
app.get('/api/products', requireUser, async (req, res) => {
  try {
    const db = getSupabaseAdmin();
    const { data, error } = await db.from('products').select('*').eq('vendor_id', req.user.id).order('created_at', { ascending: false });
    if (error) throw error;
    const now = Date.now();
    const { data: subs } = await db.from('seller_subscriptions').select('plan,status,starts_at,ends_at').eq('user_id', req.user.id).eq('status','active').in('plan', ['boost_weekly','boost_monthly','boost_yearly']);
    const globalLevel = (subs || []).reduce((max, sub) => {
      const end = new Date(sub.ends_at || 0).getTime();
      if (end <= now) return max;
      const level = sub.plan === 'boost_yearly' ? 5 : sub.plan === 'boost_monthly' ? 4 : sub.plan === 'boost_weekly' ? 3 : 0;
      return Math.max(max, level);
    }, 0);
    const labels = {1:'⚡ توربو',2:'🔥 انفجاری',3:'💥 قدرتی',4:'👑 فروشنده ویژه',5:'🏆 فروشنده طلایی'};
    res.json((data || []).map(x => {
      const own = x.boost_level && (!x.boost_until || new Date(x.boost_until).getTime() > now) ? Number(x.boost_level) : 0;
      const level = Math.max(own, globalLevel);
      const turboSub = (subs || []).filter(s => s.status === 'active' && new Date(s.ends_at || 0).getTime() > now).sort((a,b)=>new Date(b.ends_at).getTime()-new Date(a.ends_at).getTime())[0];
      const isStoreProduct = x.is_store_product === true; const safeLevel = isStoreProduct ? 0 : level; return { ...x, effective_boost_level: safeLevel, boost_label: isStoreProduct ? '' : (turboSub ? '⚡ توربو' : (labels[safeLevel] || '')), global_boost: isStoreProduct ? false : globalLevel > 0, turbo_active: isStoreProduct ? false : Boolean(turboSub), turbo_plan: isStoreProduct ? null : (turboSub?.plan || null), turbo_starts_at: isStoreProduct ? null : (turboSub?.starts_at || null), turbo_until: isStoreProduct ? null : (turboSub?.ends_at || null) };
    }));
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در دریافت محصولات.' }); }
});

app.post('/api/products', requireUser, async (req, res) => {
  try {
    const { title, price, cost_price = 0, description = '', category = '', subcategory = '', image_url = '', stock = 0, allow_chat = true, show_phone = false, contact_phone = '', location_text = '', province = '', is_negotiable = false, currency = 'AFN', brand = '', model = '', sizes = '', colors = '', material = '', condition = '', product_code = '', specifications = '', discount_percent = 0, is_store_product = false } = req.body || {};
    const forceStoreProduct = String(req.headers['x-bazarek-store-product'] || '').toLowerCase() === 'true';
    if (!title || typeof title !== 'string') return res.status(400).json({ error: 'نام محصول الزامی است.' });
    const db = getSupabaseAdmin();
    if (!String(province).trim()) return res.status(400).json({ error: 'ولایت آگهی الزامی است.' });
    const cleanCode = String(product_code || '').trim().slice(0,80);
    const generatedCode = cleanCode || `BZ-${crypto.randomUUID().replaceAll('-', '').slice(0,10).toUpperCase()}`;
    const discount = Math.min(99, Math.max(0, Number(discount_percent) || 0));
    // The server is the final authority: only the dedicated store-product flow
    // (explicit header) may create a store product. A normal ad can never become
    // a store product merely by sending is_store_product=true in JSON.
    const storeProduct = forceStoreProduct;
    if (storeProduct) {
      const storeSub = await getActiveStoreSubscription(db, req.user.id);
      if (!storeSub) return res.status(403).json({ error: 'برای افزودن محصول فروشگاهی باید فروشگاه حرفه‌ای فعال باشد.' });
    }
    const payload = { vendor_id: req.user.id, title: title.trim(), price: Math.max(0, Number(price) || 0), cost_price: Math.max(0, Number(cost_price) || 0), description: String(description).slice(0,10000), category: String(category), subcategory: String(subcategory), image_url: String(image_url), allow_chat: Boolean(allow_chat), show_phone: Boolean(show_phone), contact_phone: String(contact_phone).trim().slice(0,30), location_text: String(location_text).trim().slice(0,160), external_link: String(req.body?.external_link || '').trim().slice(0,500), province: String(province).trim().slice(0,80), is_negotiable: Boolean(is_negotiable), currency: String(currency).toUpperCase() === 'USD' ? 'USD' : 'AFN', stock: Math.max(0, Math.trunc(Number(stock) || 0)), brand: String(brand).trim().slice(0,120), model: String(model).trim().slice(0,120), sizes: String(sizes).trim().slice(0,300), colors: String(colors).trim().slice(0,300), material: String(material).trim().slice(0,120), condition: String(condition).trim().slice(0,120), product_code: generatedCode, specifications: String(specifications).trim().slice(0,3000), discount_percent: discount, is_store_product: storeProduct, is_featured: false, is_pinned: false, featured_until: null, pinned_until: null, boost_level: 0, boost_until: null };
    const { data, error } = await db.from('products').insert([payload]).select().single();
    if (error) throw error;
    try {
      const { data: followers } = await db.from('seller_follows').select('user_id').eq('seller_id', req.user.id);
      if (followers?.length) {
        await db.from('user_notifications').insert(followers.map(f => ({
          user_id: f.user_id, type: 'seller_new_listing', title: 'آگهی جدید از فروشنده مورد علاقه شما',
          message: `فروشنده «${title.trim()}» یک آگهی جدید منتشر کرد.`
        })));
      }
    } catch (notifyError) { console.warn('seller follower notification error:', notifyError?.message || notifyError); }
    res.status(201).json(data);
  } catch (e) { console.error(e); res.status(500).json({ error: 'خطا در ثبت محصول.' }); }
});

app.patch('/api/products/:id/status', requireUser, async (req, res) => {
  try {
    const isActive = req.body?.is_active === true;
    const db = getSupabaseAdmin();
    const { data: listing, error: le } = await db
      .from('products')
      .select('id,vendor_id,is_active,moderation_disabled,moderation_reason')
      .eq('id', req.params.id)
      .maybeSingle();
    if (le) throw le;
    if (!listing) return res.status(404).json({ error: 'آگهی پیدا نشد.' });
    if (String(listing.vendor_id) !== String(req.user.id)) return res.status(403).json({ error: 'این آگهی متعلق به شما نیست.' });
    if (isActive && listing.moderation_disabled === true) {
      return res.status(403).json({ error: 'این آگهی توسط مدیریت بازارک به دلیل بررسی قوانین غیرفعال شده و فعلاً قابل فعال‌سازی نیست.' });
    }

    // Update without relying on Supabase's returned-row behaviour. This avoids
    // the generic "status change failed" error on deployments where the
    // products table has restrictive RETURNING/RLS behaviour.
    const { error: updateError } = await db
      .from('products')
      .update({ is_active: isActive, updated_at: new Date().toISOString() })
      .eq('id', req.params.id)
      .eq('vendor_id', req.user.id);
    if (updateError) throw updateError;

    const { data: updated, error: readError } = await db
      .from('products')
      .select('*')
      .eq('id', req.params.id)
      .eq('vendor_id', req.user.id)
      .maybeSingle();
    if (readError) throw readError;
    if (!updated) return res.status(404).json({ error: 'آگهی پس از تغییر وضعیت پیدا نشد.' });
    res.json(updated);
  } catch (e) {
    console.error('Listing status change error:', e);
    res.status(500).json({ error: `خطا در تغییر وضعیت آگهی${e?.message ? `: ${e.message}` : '.'}` });
  }
});

// Permanently delete the authenticated user's account and its related data.
// All user-owned tables in the Bazarek schema reference auth.users with
// ON DELETE CASCADE, so deleting the auth user removes the linked profile,
// listings, favorites, reports, messages, wallet records, etc.
app.delete('/api/me/account', requireUser, async (req, res) => {
  try {
    const db = getSupabaseAdmin();
    const userId = String(req.user.id);
    const { error } = await db.auth.admin.deleteUser(userId);
    if (error) throw error;
    res.json({ ok: true, message: 'حساب شما برای همیشه حذف شد.' });
  } catch (e) {
    console.error('Account deletion error:', e);
    res.status(500).json({ error: 'حذف حساب انجام نشد. لطفاً دوباره تلاش کنید.' });
  }
});

app.patch('/api/products/:id', requireUser, async (req, res) => {
  try {
    const allowed = ['title', 'price', 'cost_price', 'description', 'category', 'subcategory', 'image_url', 'stock', 'allow_chat', 'show_phone', 'contact_phone', 'location_text', 'external_link', 'is_negotiable', 'currency', 'brand', 'model', 'sizes', 'colors', 'material', 'condition', 'product_code', 'specifications'];
    const payload = {};
    for (const key of allowed) if (req.body[key] !== undefined) payload[key] = req.body[key];
    if (payload.price !== undefined) payload.price = Math.max(0, Number(payload.price) || 0);
    if (payload.currency !== undefined) payload.currency = String(payload.currency).toUpperCase() === 'USD' ? 'USD' : 'AFN';
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

// Run once on startup, then every 30 seconds. This guarantees expired Boosts are
// cleaned up automatically even when the optional Supabase pg_cron job is unavailable.
expireTimeBasedBoosts();
setInterval(expireTimeBasedBoosts, 30 * 1000);

app.listen(PORT, () => console.log(`Bazarek backend running on ${PORT}`));
