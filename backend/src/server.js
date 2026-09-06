require('dotenv').config();
const express = require('express');
const cors = require('cors');
const verifyAdmin = require('./middlewares/adminAuth');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
app.use(cors());
app.use(express.json());

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "YOUR_API_KEY");

// مسیر AI برای تبدیل متن/عکس به آگهی
app.post('/api/ai/generate-ad', async (req, res) => {
  try {
    const { productInfo } = req.body;
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    
    const prompt = `شما یک دستیار فروش در افغانستان هستید. بر اساس اطلاعات زیر یک آگهی جذاب به زبان دری با قیمت به افغانی بنویس: ${productInfo}`;
    const result = await model.generateContent(prompt);
    const response = await result.response;
    
    res.json({ success: true, adText: response.text() });
  } catch (error) {
    res.status(500).json({ error: "خطا در ارتباط با هوش مصنوعی" });
  }
});

// مسیرهای پنل ادمین (محافظت‌شده)
app.get('/api/admin/dashboard', verifyAdmin, (req, res) => {
  res.json({
    totalUsers: 1250,
    activeSubscriptions: 340,
    monthlyRevenueAfn: 102000,
    aiUsageCount: 8450,
    systemStatus: "آنلاین"
  });
});

app.post('/api/admin/change-plan-price', verifyAdmin, (req, res) => {
  const { planName, newPrice } = req.body;
  // کد بروزرسانی قیمت در دیتابیس
  res.json({ message: `قیمت پلن ${planName} به ${newPrice} افغانی تغییر یافت.` });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`سرور روی پورت ${PORT} فعال شد.`));
