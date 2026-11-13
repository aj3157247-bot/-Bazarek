// دستیار هوش مصنوعی آگهی: از عکس‌ها و توضیح فروشنده، آگهی کامل می‌سازد.
//  ۱) ربات تلگرام (فقط ادمین‌های مجاز): عکس + توضیح بفرستید ← آگهی در بازارک منتشر می‌شود.
//  ۲) /api/ai/draft-listing: پیش‌نویس آگهی برای فرم ثبت آگهی (برای کمک به فروشنده‌ها).
// نکته‌ی مهم: فقط آگهی کسانی را منتشر کنید که خودشان اجازه داده‌اند. کپی کردن آگهی مردم از فیسبوک ممنوع است.
const { CATEGORIES, PROVINCES } = require('./taxonomy');

const FA = '۰۱۲۳۴۵۶۷۸۹', AR = '٠١٢٣٤٥٦٧٨٩';
function toEnDigits(t) {
  let v = String(t || '');
  for (let i = 0; i < 10; i++) v = v.split(FA[i]).join(String(i)).split(AR[i]).join(String(i));
  return v;
}
// شماره‌ی موبایل افغانستان (07xxxxxxxx یا +93...) را از متن برمی‌دارد
function findAfghanPhone(text) {
  const m = toEnDigits(text).replace(/[\s\-().]/g, '').match(/(?:\+?93|0093|0)?(7\d{8})/);
  return m ? `0${m[1]}` : '';
}

function categoryGuide() {
  return CATEGORIES.map((c) => `- ${c.id} (${c.title}): ${c.subs.map((s) => `${s.id}=${s.title}`).join('، ')}`).join('\n');
}

function buildPrompt(text) {
  return `تو دستیار ثبت آگهی «بازارک»، بازار آنلاین افغانستان هستی. از عکس‌ها و متن زیر، یک آگهی دقیق بساز.
قوانین سخت:
- فقط از اطلاعاتی استفاده کن که در عکس یا متن واقعاً هست. چیزی را از خودت نساز (قیمت، شماره، مشخصات).
- اگر قیمت معلوم نیست، price را 0 بگذار.
- شماره‌ی تلفن فقط از متن فروشنده؛ از عکس حدس نزن.
- category و subcategory باید دقیقاً از فهرست زیر باشند.
- province باید یکی از این ولایت‌ها باشد: ${PROVINCES.join('، ')}.
- address: آدرس دقیق (منطقه، سرک، مارکیت، ناحیه) فقط اگر در متن باشد؛ وگرنه خالی.
- عنوان کوتاه و روشن (حداکثر ۸۰ کاراکتر) به فارسی/دری. توضیحات ۲ تا ۶ خط، بدون ایموجی زیاد و بدون شماره‌ی تلفن.
فهرست دسته‌ها (id (عنوان): زیردسته‌ها):
${categoryGuide()}

متن فروشنده:
"""${String(text || '').slice(0, 2000)}"""

فقط یک JSON معتبر برگردان با این کلیدها:
{"title":"","description":"","category":"","subcategory":"","price":0,"currency":"AFN یا USD","province":"","address":"","condition":"نو/دست‌دوم/خالی","brand":"","model":"","negotiable":false}`;
}

// خروجی مدل را اعتبارسنجی و پاک می‌کند؛ اگر دسته‌ی معتبر نبود، null برمی‌گرداند (چیزی منتشر نمی‌شود).
function normalizeDraft(raw, text, activeCategories = '*') {
  if (!raw || typeof raw !== 'object') return { ok: false, reason: 'پاسخ هوش مصنوعی قابل فهم نبود.' };
  const cat = CATEGORIES.find((c) => c.id === String(raw.category || ''));
  if (!cat) return { ok: false, reason: 'دسته‌ی آگهی تشخیص داده نشد. در توضیح، نوع کالا را واضح‌تر بنویسید.' };
  if (activeCategories !== '*' && !String(activeCategories).split(',').map((x) => x.trim()).includes(cat.id)) {
    return { ok: false, reason: `ثبت آگهی در دسته‌ی «${cat.title}» فعلاً فعال نیست.` };
  }
  // زیردسته‌ی نامعتبر را حدس نمی‌زنیم؛ آگهی با زیردسته‌ی اشتباه بدتر از منتشر نشدن است.
  const sub = cat.subs.find((s) => s.id === String(raw.subcategory || ''));
  if (!sub) return { ok: false, reason: `زیردسته‌ی مناسب برای «${cat.title}» تشخیص داده نشد. نوع دقیق کالا را در توضیح بنویسید.` };
  const title = String(raw.title || '').replace(/\s+/g, ' ').trim().slice(0, 120);
  if (title.length < 3) return { ok: false, reason: 'عنوان آگهی ساخته نشد.' };
  let price = Number(toEnDigits(raw.price));
  if (!Number.isFinite(price) || price < 0 || price > 1e10) price = 0;
  const province = PROVINCES.includes(String(raw.province || '')) ? String(raw.province) : '';
  const phone = findAfghanPhone(text);
  return {
    ok: true,
    draft: {
      title,
      description: String(raw.description || '').replace(/(\+?93|0)?7\d{8}/g, '').trim().slice(0, 2000),
      category: cat.id,
      categoryTitle: cat.title,
      subcategory: sub.id,
      price: Math.round(price),
      currency: String(raw.currency || '').toUpperCase() === 'USD' ? 'USD' : 'AFN',
      province,
      address: String(raw.address || '').replace(/(\+?93|0)?7\d{8}/g, '').replace(/\s+/g, ' ').trim().slice(0, 200),
      condition: String(raw.condition || '').trim().slice(0, 60),
      brand: String(raw.brand || '').trim().slice(0, 120),
      model: String(raw.model || '').trim().slice(0, 120),
      negotiable: raw.negotiable === true,
      phone,
    },
  };
}

async function askModel(genAI, images, text) {
  if (!genAI) throw new Error('GEMINI_API_KEY تنظیم نشده است.');
  const model = genAI.getGenerativeModel({
    model: process.env.GEMINI_MODEL || 'gemini-1.5-flash',
    generationConfig: { responseMimeType: 'application/json', temperature: 0.2 },
  });
  const parts = [{ text: buildPrompt(text) }, ...images.slice(0, 4).map((im) => ({ inlineData: { mimeType: im.mimeType || 'image/jpeg', data: im.data } }))];
  const result = await model.generateContent(parts);
  const out = String(result?.response?.text?.() || '').replace(/```json|```/g, '').trim();
  return JSON.parse(out);
}

async function extractListingDraft({ genAI, images, text, activeCategories }) {
  const raw = await askModel(genAI, images, text);
  return normalizeDraft(raw, text, activeCategories);
}

function registerAssist(app, deps) {
  const { getSupabaseAdmin, requireUser, genAI, sharp, crypto, postAdToChannels, express } = deps;
  const env = process.env;
  const activeCategories = String(env.ACTIVE_AD_CATEGORIES || '*');
  const admins = new Set(String(env.TELEGRAM_ASSIST_ADMINS || '').split(',').map((x) => x.trim()).filter(Boolean));
  const pending = new Map();      // جمع‌کردن آلبوم عکس‌ها
  const lastByAdmin = new Map();  // برای /undo
  const hourly = new Map();       // محدودیت: ۴۰ آگهی در ساعت برای هر ادمین
  setInterval(() => hourly.clear(), 3600 * 1000).unref?.();
  const aiDaily = new Map();      // محدودیت پیش‌نویس برای کاربران: ۱۵ بار در روز
  setInterval(() => aiDaily.clear(), 24 * 3600 * 1000).unref?.();

  const token = () => env.TELEGRAM_BOT_TOKEN || '';
  async function tg(method, body) {
    const r = await fetch(`https://api.telegram.org/bot${token()}/${method}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
    return r.json().catch(() => ({}));
  }
  const say = (chatId, text) => tg('sendMessage', { chat_id: chatId, text, disable_web_page_preview: true });

  async function downloadPhoto(fileId) {
    const info = await tg('getFile', { file_id: fileId });
    const path = info?.result?.file_path;
    if (!path) throw new Error('دانلود عکس از تلگرام ممکن نشد.');
    const r = await fetch(`https://api.telegram.org/file/bot${token()}/${path}`);
    if (!r.ok) throw new Error('دانلود عکس ناموفق بود.');
    return Buffer.from(await r.arrayBuffer());
  }

  async function processBatch(key) {
    const b = pending.get(key);
    pending.delete(key);
    if (!b) return;
    const { chatId, userId, fileIds, caption } = b;
    try {
      const count = (hourly.get(userId) || 0) + 1;
      hourly.set(userId, count);
      if (count > 40) return say(chatId, '⏱ سقف ساعتی (۴۰ آگهی) پر شد؛ کمی بعد دوباره امتحان کنید.');
      const vendorId = env.ASSIST_VENDOR_ID;
      if (!vendorId) return say(chatId, '⚠️ ASSIST_VENDOR_ID در سرور تنظیم نشده است.');
      if (!caption || caption.trim().length < 5) return say(chatId, '✍️ عکس‌ها را همراه توضیح (caption) بفرستید: نوع کالا، قیمت، ولایت و شماره‌ی واتساپ.');
      await say(chatId, `⏳ ${fileIds.length} عکس دریافت شد؛ در حال ساخت آگهی...`);

      const full = [], small = [];
      for (const id of fileIds.slice(0, 6)) {
        const buf = await downloadPhoto(id);
        full.push(await sharp(buf).rotate().resize(1600, 1600, { fit: 'inside', withoutEnlargement: true }).jpeg({ quality: 84 }).toBuffer());
        small.push((await sharp(buf).rotate().resize(1024, 1024, { fit: 'inside', withoutEnlargement: true }).jpeg({ quality: 78 }).toBuffer()).toString('base64'));
      }
      const res = await extractListingDraft({ genAI, images: small.map((d) => ({ mimeType: 'image/jpeg', data: d })), text: caption, activeCategories });
      if (!res.ok) return say(chatId, `❌ منتشر نشد: ${res.reason}`);
      const d = res.draft;

      const db = getSupabaseAdmin();
      const urls = [];
      for (const buf of full) {
        const path = `${vendorId}/${crypto.randomUUID()}.jpg`;
        const up = await db.storage.from('listing-images').upload(path, buf, { contentType: 'image/jpeg', cacheControl: '31536000', upsert: false });
        if (up.error) throw up.error;
        urls.push(db.storage.from('listing-images').getPublicUrl(path).data.publicUrl);
      }
      const payload = {
        vendor_id: vendorId, title: d.title, description: d.description, price: d.price, currency: d.currency, stock: 1,
        category: d.category, subcategory: d.subcategory, image_url: JSON.stringify(urls), audio_url: '', video_url: '',
        share_to_channels: true, show_whatsapp: Boolean(d.phone), whatsapp_number: d.phone, allow_chat: false, show_phone: Boolean(d.phone),
        contact_phone: d.phone, location_text: d.address || '', external_link: '', province: d.province || 'کابل', is_negotiable: d.negotiable,
        brand: d.brand, model: d.model, sizes: '', colors: '', material: '', condition: d.condition, specifications: '',
        product_code: `BZ-${crypto.randomUUID().replaceAll('-', '').slice(0, 10).toUpperCase()}`, discount_percent: 0, cost_price: 0,
        is_store_product: false, is_featured: false, is_pinned: false, featured_until: null, pinned_until: null, boost_level: 0, boost_until: null,
      };
      const { data, error } = await db.from('products').insert([payload]).select().single();
      if (error) throw error;
      lastByAdmin.set(userId, data.id);
      if (postAdToChannels) postAdToChannels(data);
      const priceText = d.price > 0 ? `${d.price.toLocaleString('en-US')} ${d.currency === 'USD' ? 'دالر' : 'افغانی'}` : 'توافقی';
      await say(chatId, `✅ منتشر شد\n\n📌 ${d.title}\n📂 ${d.categoryTitle}\n💰 ${priceText}\n📍 ${payload.province}${d.province ? '' : ' (ولایت در متن نبود؛ کابل گذاشته شد)'}\n📞 ${d.phone || 'شماره پیدا نشد'}\n\n🔗 https://bazarek.pages.dev/listing/${data.id}\n\nاشتباه بود؟ بنویسید: /undo`);
    } catch (e) {
      console.error('assist error:', e?.message || e);
      await say(chatId, `⚠️ خطا: ${String(e?.message || e).slice(0, 180)}`);
    }
  }

  async function handleUpdate(update) {
    const msg = update?.message;
    if (!msg || !msg.chat) return;
    const chatId = msg.chat.id, userId = String(msg.from?.id || '');
    if (!admins.has(userId)) return say(chatId, '⛔ این ربات فقط برای مدیران بازارک است.');
    const text = String(msg.text || '').trim();
    if (text === '/start' || text === '/help') {
      return say(chatId, 'سلام 👋 دستیار آگهی بازارک\n\nعکس‌های کالا را (یک یا چند عکس، به‌صورت آلبوم) همراه توضیح بفرستید: نوع کالا، قیمت، ولایت، شماره‌ی واتساپ. هوش مصنوعی آگهی را کامل می‌کند و منتشر می‌کند.\n\nفقط آگهی کسانی را بگذارید که خودشان اجازه داده‌اند.\n/undo = حذف آخرین آگهی');
    }
    if (text === '/undo') {
      const id = lastByAdmin.get(userId);
      if (!id) return say(chatId, 'آگهی‌ای برای حذف نیست.');
      await getSupabaseAdmin().from('products').update({ is_active: false }).eq('id', id);
      lastByAdmin.delete(userId);
      return say(chatId, '🗑 آخرین آگهی غیرفعال شد.');
    }
    if (msg.photo?.length) {
      const fileId = msg.photo[msg.photo.length - 1].file_id;
      const key = msg.media_group_id ? `${chatId}:g:${msg.media_group_id}` : `${chatId}:m:${msg.message_id}`;
      const b = pending.get(key) || { chatId, userId, fileIds: [], caption: '' };
      b.fileIds.push(fileId);
      if (msg.caption) b.caption = msg.caption;
      clearTimeout(b.timer);
      b.timer = setTimeout(() => processBatch(key), 3000);
      pending.set(key, b);
      return;
    }
    if (text) return say(chatId, '📷 برای ساخت آگهی، عکس‌ها را همراه توضیح (caption) بفرستید.');
  }

  // وب‌هوک تلگرام: آدرس را با secret محافظت کنید
  app.post('/api/telegram/webhook/:secret', (req, res) => {
    const secret = String(env.TELEGRAM_WEBHOOK_SECRET || '');
    const given = String(req.params.secret || '');
    const ok = secret.length >= 16 && given.length === secret.length && crypto.timingSafeEqual(Buffer.from(given), Buffer.from(secret));
    if (!ok) return res.status(403).json({ ok: false });
    res.json({ ok: true }); // فوراً جواب می‌دهیم؛ پردازش در پس‌زمینه
    handleUpdate(req.body).catch((e) => console.error('assist webhook error:', e?.message || e));
  });

  const multer = require('multer');
  const uploadAi = multer({ storage: multer.memoryStorage(), limits: { fileSize: 8 * 1024 * 1024, files: 3 } });
  const withUpload = (mw) => (req, res, next) => mw(req, res, (err) => (err ? res.status(400).json({ error: 'فایل عکس نامعتبر یا بزرگ‌تر از ۸ مگابایت است.' }) : next()));
  const cleanDaily = new Map();
  setInterval(() => cleanDaily.clear(), 24 * 3600 * 1000).unref?.();

  // پیش‌نویس آگهی برای فرم ثبت آگهی (آگهی عادی و محصول فروشگاه): multipart با فیلد text و تا ۳ عکس (images)
  app.post('/api/ai/draft-listing', requireUser, withUpload(uploadAi.array('images', 3)), async (req, res) => {
    try {
      const uid = req.user.id;
      const used = (aiDaily.get(uid) || 0) + 1;
      aiDaily.set(uid, used);
      if (used > 20) return res.status(429).json({ error: 'سقف روزانه‌ی کمک هوش مصنوعی (۲۰ بار) پر شد.' });
      const text = String(req.body?.text || '').slice(0, 2000);
      const files = Array.isArray(req.files) ? req.files : [];
      if (!files.length && text.trim().length < 5) return res.status(400).json({ error: 'عکس یا چند کلمه توضیح بدهید.' });
      const images = [];
      for (const f of files.slice(0, 3)) {
        const buf = await sharp(f.buffer).rotate().resize(1024, 1024, { fit: 'inside', withoutEnlargement: true }).jpeg({ quality: 78 }).toBuffer();
        images.push({ mimeType: 'image/jpeg', data: buf.toString('base64') });
      }
      const result = await extractListingDraft({ genAI, images, text, activeCategories });
      if (!result.ok) return res.status(422).json({ error: result.reason });
      res.json({ draft: result.draft });
    } catch (e) {
      console.error('draft-listing error:', e?.message || e);
      res.status(500).json({ error: 'ساخت پیش‌نویس انجام نشد؛ دوباره امتحان کنید.' });
    }
  });

  // پاک‌سازی پس‌زمینه (آزمایشی): فقط وقتی GEMINI_IMAGE_MODEL در سرور تنظیم شده باشد فعال است.
  app.post('/api/ai/clean-image', requireUser, withUpload(uploadAi.single('image')), async (req, res) => {
    try {
      const model = env.GEMINI_IMAGE_MODEL;
      if (!model || !env.GEMINI_API_KEY) return res.status(501).json({ error: 'پاک‌سازی پس‌زمینه هنوز فعال نشده است.' });
      if (!req.file) return res.status(400).json({ error: 'عکس ارسال نشده است.' });
      const uid = req.user.id;
      const used = (cleanDaily.get(uid) || 0) + 1;
      cleanDaily.set(uid, used);
      if (used > 20) return res.status(429).json({ error: 'سقف روزانه‌ی پاک‌سازی عکس پر شد.' });
      const input = await sharp(req.file.buffer).rotate().resize(1280, 1280, { fit: 'inside', withoutEnlargement: true }).jpeg({ quality: 86 }).toBuffer();
      const r = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(env.GEMINI_API_KEY)}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [
            { text: 'Remove the background of this product photo and place the product on a clean, pure white background with soft natural lighting. Keep the product exactly the same: shape, color, text, logos and details. Do not add, remove or redraw anything on the product.' },
            { inline_data: { mime_type: 'image/jpeg', data: input.toString('base64') } },
          ] }],
          generationConfig: { responseModalities: ['TEXT', 'IMAGE'] },
        }),
      });
      const j = await r.json().catch(() => ({}));
      const part = (j?.candidates?.[0]?.content?.parts || []).find((p) => p.inlineData?.data || p.inline_data?.data);
      const b64 = part?.inlineData?.data || part?.inline_data?.data;
      if (!r.ok || !b64) { console.warn('clean-image failed:', r.status, JSON.stringify(j).slice(0, 200)); return res.status(502).json({ error: 'پاک‌سازی پس‌زمینه انجام نشد.' }); }
      const out = await sharp(Buffer.from(b64, 'base64')).jpeg({ quality: 88 }).toBuffer();
      res.set('Content-Type', 'image/jpeg');
      res.send(out);
    } catch (e) {
      console.error('clean-image error:', e?.message || e);
      res.status(500).json({ error: 'پاک‌سازی پس‌زمینه انجام نشد.' });
    }
  });
}

module.exports = { registerAssist, extractListingDraft, normalizeDraft, findAfghanPhone };
