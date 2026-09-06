const { createClient } = require('@supabase/supabase-js');

function getSupabaseAdmin() {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required');
  return createClient(url, key, { auth: { autoRefreshToken: false, persistSession: false } });
}

async function requireUser(req, res, next) {
  try {
    const auth = req.headers.authorization || '';
    if (!auth.startsWith('Bearer ')) return res.status(401).json({ error: 'لطفاً وارد حساب شوید.' });
    const token = auth.slice(7);
    const supabase = getSupabaseAdmin();
    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data.user) return res.status(401).json({ error: 'نشست شما منقضی شده است.' });
    req.user = data.user;
    next();
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'خطای احراز هویت سرور.' });
  }
}

module.exports = { requireUser, getSupabaseAdmin };
