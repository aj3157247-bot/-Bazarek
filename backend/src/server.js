require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
app.use(cors());
app.use(express.json());

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://xenljmaprmggejadadbo.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_KEY || 'sb_publishable_DFyKCc9_Pv5SoJiSiouWxg_FycPk7M3';
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

app.get('/', (req, res) => {
    res.json({ message: 'Smart Sales Assistant Backend is Running!' });
});

app.get('/api/products', async (req, res) => {
    try {
        const { data, error } = await supabase.from('products').select('*');
        if (error) throw error;
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/products', async (req, res) => {
    try {
        const { title, price, description, vendor_id } = req.body;
        const { data, error } = await supabase
            .from('products')
            .insert([{ title, price, description, vendor_id }]);
            
        if (error) throw error;
        res.status(201).json({ message: 'محصول با موفقیت ثبت شد', data });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/generate-ad', async (req, res) => {
    try {
        const { productName, description } = req.body;

        if (!GEMINI_API_KEY) {
            return res.status(400).json({ error: 'کلید GEMINI_API_KEY مقداردهی نشده است.' });
        }

        const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
        const prompt = `یک متن تبلیغاتی جذاب به زبان فارسی برای این محصول بساز:
        نام محصول: ${productName}
        توضیحات: ${description || 'بدون توضیح'}`;

        const result = await model.generateContent(prompt);
        const responseText = result.response.text();

        res.json({ adText: responseText });
    } catch (error) {
        console.error('خطای Gemini:', error);
        res.status(500).json({ error: 'خطا در تولید متن آگهی' });
    }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
