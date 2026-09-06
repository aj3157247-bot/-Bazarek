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

    const { data: profile } = await supabase
      .from('profiles')
      .select('is_blocked,blocked_until,block_reason')
      .eq('id', data.user.id)
      .maybeSingle();

    const blockedUntil = profile?.blocked_until ? new Date(profile.blocked_until) : null;
    const blocked = profile?.is_blocked === true && (!blockedUntil || blockedUntil > new Date());
    if (blocked) {
      const untilText = blockedUntil ? ` تا ${blockedUntil.toLocaleString('fa-IR')}` : '';
      return res.status(403).json({ error: `حساب شما توسط مدیریت مسدود شده است${untilText}.${profile?.block_reason ? ` دلیل: ${profile.block_reason}` : ''}` });
    }

    // Automatically clear an expired temporary block.
    if (profile?.is_blocked === true && blockedUntil && blockedUntil <= new Date()) {
      await supabase.from('profiles').update({ is_blocked: false, blocked_until: null, block_reason: null }).eq('id', data.user.id);
    }

    req.user = data.user;
    next();
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'خطای احراز هویت سرور.' });
  }
}

module.exports = { requireUser, getSupabaseAdmin };
