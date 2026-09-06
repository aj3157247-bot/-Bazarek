require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const { createClient } = require('@supabase/supabase-supabase-js');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const verifyAdmin = require('./middlewares/adminAuth');

const app = express();
const upload = multer({ storage: multer.memoryStorage() });

app.use(cors());
app.use(express.json());

// 1. تنظیمات دیتابیس Supabase
const supabase = createClient(
  process.env.SUPABASE_URL || "YOUR_SUPABASE_URL",
  process.env.SUPABASE_KEY || "YOUR_SUPABASE_KEY"
);

// 2. تنظیمات Gemini AI
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "YOUR_GEMINI_KEY");

/* ==================== 📸 بخش اول: پردازش تصویر و ساخت آگهی ==================== */
app.post('/api/ai/scan-product', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "لطفاً تصویر کالا را آپلود کنید." });

    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    const imagePart = {
      inlineData: {
        data: req.file.buffer.toString("base64"),
        mimeType: req.file.mimetype
      },
    };

    const prompt = `این تصویر یک محصول است. مشخصات زیر را به زبان دری استخراج کن و دقیقاً در قالب JSON برگردان:
    {
      "title": "عنوان جذاب محصول به دری",
      "category": "دسته بندی کالا",
      "suggested_price": "قیمت تخمینی به افغانی (فقط عدد)",
      "description": "توضیحات کامل و جذاب برای فروش در اینستاگرام"
    }`;

    const result = await model.generateContent([prompt, imagePart]);
    const responseText = result.response.text().replace(/```json|```/g, '').trim();
    const productData = JSON.parse(responseText);

    res.json({ success: true, data: productData });
  } catch (error) {
    res.status(500).json({ error: "خطا در پردازش تصویر با هوش مصنوعی" });
  }
});

/* ==================== 🤖 بخش دوم: چت‌بات هوشمند فروشنده ==================== */
app.post('/api/ai/vendor-chat', async (req, res) => {
  try {
    const { vendorId, userQuestion } = req.body;

    // دریافت لیست محصولات فروشنده از دیتابیس
    const { data: products, error } = await supabase
      .from('products')
      .select('title, price, description')
      .eq('vendor_id', vendorId);

    if (error) throw error;

    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    const contextPrompt = `شما دستیار فروشگاه هستید. بر اساس لیست زیر پاسخ خریدار را به زبان دری و لحن محترمانه بدهید:
    لیست محصولات فروشگاه: ${JSON.stringify(products)}
    سوال خریدار: ${userQuestion}`;

    const result = await model.generateContent(contextPrompt);
    res.json({ success: true, reply: result.response.text() });
  } catch (error) {
    res.status(500).json({ error: "خطا در پاسخگویی دستیار" });
  }
});

/* ==================== 🗄️ بخش سوم: مدیریت محصولات (دیتابیس) ==================== */
app.post('/api/products/add', async (req, res) => {
  const { vendorId, title, price, description } = req.body;

  const { data, error } = await supabase
    .from('products')
    .insert([{ vendor_id: vendorId, title, price, description }]);

  if (error) return res.status(500).json({ error: error.message });
  res.json({ success: true, message: "محصول با موفقیت ثبت شد", data });
});

/* ==================== 👑 بخش پنل ادمین ==================== */
app.get('/api/admin/dashboard', verifyAdmin, async (req, res) => {
  const { count: userCount } = await supabase.from('users').select('*', { count: 'exact' });
  const { count: productCount } = await supabase.from('products').select('*', { count: 'exact' });

  res.json({
    totalUsers: userCount || 0,
    totalProducts: productCount || 0,
    systemStatus: "فعال",
    admin: "abdullahjafari712@gmail.com"
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`سرور کامل اجرا شد روی پورت ${PORT}`));
