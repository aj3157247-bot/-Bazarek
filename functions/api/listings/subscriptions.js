function json(data, status = 200) {
  return Response.json(data, {
    status,
    headers: {
      'Cache-Control': 'no-store',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Accept, Content-Type, Authorization',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    },
  });
}

export async function onRequestOptions() {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Accept, Content-Type, Authorization',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    },
  });
}

async function getUser(env, request) {
  const token = String(request.headers.get('Authorization') || '').replace(/^Bearer\s+/i, '').trim();
  const supabaseUrl = String(env.SUPABASE_URL || '').replace(/\/$/, '');
  const anonKey = String(env.SUPABASE_ANON_KEY || env.SUPABASE_KEY || '').trim();
  if (!token || !supabaseUrl || !anonKey) return null;

  const r = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${token}`,
      Accept: 'application/json',
    },
  });
  if (!r.ok) return null;
  const user = await r.json().catch(() => null);
  return user && user.id ? user : null;
}

function dbHeaders(serviceKey) {
  return {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    'Content-Type': 'application/json',
    Accept: 'application/json',
    Prefer: 'return=representation',
  };
}

export async function onRequestPost({ request, env }) {
  try {
    const supabaseUrl = String(env.SUPABASE_URL || '').replace(/\/$/, '');
    const serviceKey = String(env.SUPABASE_SERVICE_ROLE_KEY || '').trim();
    if (!supabaseUrl || !serviceKey) {
      return json({ error: 'تنظیمات پایگاه‌داده Cloudflare کامل نیست.', code: 'SUPABASE_CONFIG_MISSING' }, 500);
    }

    const user = await getUser(env, request);
    if (!user) return json({ error: 'لطفاً ابتدا وارد حساب شوید.' }, 401);

    const body = await request.json().catch(() => ({}));
    const plan = String(body?.plan || '').trim().toLowerCase();
    const reference = String(body?.payment_reference || '').trim();

    const plans = {
      store_monthly: { price: 600, days: 30 },
      store_yearly: { price: 6000, days: 365 },
    };

    if (!plans[plan]) return json({ error: 'پلن نامعتبر است.' }, 400);
    if (!reference) return json({ error: 'برای خرید فروشگاه باید مبلغ را انتقال دهید و شماره پیگیری را وارد کنید.' }, 400);

    const base = `${supabaseUrl}/rest/v1/seller_subscriptions`;
    const headers = dbHeaders(serviceKey);

    const existingUrl = new URL(base);
    existingUrl.searchParams.set('select', 'id');
    existingUrl.searchParams.set('user_id', `eq.${user.id}`);
    existingUrl.searchParams.set('plan', `eq.${plan}`);
    existingUrl.searchParams.set('status', 'eq.pending');
    existingUrl.searchParams.set('limit', '1');

    const existingRes = await fetch(existingUrl, { headers });
    const existing = await existingRes.json().catch(() => []);
    if (!existingRes.ok) {
      console.error('subscription duplicate check failed:', existing);
      return json({ error: 'خطا در بررسی درخواست قبلی.' }, 502);
    }
    if (Array.isArray(existing) && existing.length) {
      return json({ error: 'یک درخواست پرداخت برای این پلن در انتظار تأیید است.' }, 409);
    }

    const insertRes = await fetch(base, {
      method: 'POST',
      headers,
      body: JSON.stringify([{
        user_id: user.id,
        plan,
        price_afn: plans[plan].price,
        starts_at: null,
        ends_at: null,
        status: 'pending',
        payment_method: 'manual',
        payment_reference: reference.slice(0, 200),
      }]),
    });

    const inserted = await insertRes.json().catch(() => null);
    if (!insertRes.ok) {
      console.error('subscription insert failed:', insertRes.status, inserted);
      return json({ error: 'خطا در ثبت درخواست اشتراک.' }, 500);
    }

    return json(Array.isArray(inserted) ? inserted[0] : inserted, 201);
  } catch (e) {
    console.error('subscription purchase failed:', e);
    return json({ error: 'خطا در ثبت درخواست اشتراک.' }, 500);
  }
}
