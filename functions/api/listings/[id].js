function json(data, status = 200) {
  return Response.json(data, {
    status,
    headers: {
      'Cache-Control': 'no-store',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Accept, Content-Type, Authorization',
    },
  });
}

export async function onRequestOptions() {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Accept, Content-Type, Authorization',
    },
  });
}

export async function onRequestGet({ params, env }) {
  const id = String(params.id || '').trim();
  if (!id) return json({ error: 'شناسه آگهی نامعتبر است.' }, 400);

  const supabaseUrl = String(env.SUPABASE_URL || '').replace(/\/$/, '');
  const supabaseKey = String(env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_KEY || env.SUPABASE_ANON_KEY || '');

  if (!supabaseUrl || !supabaseKey) {
    return json({
      error: 'تنظیمات پایگاه‌داده Cloudflare کامل نیست.',
      code: 'SUPABASE_CONFIG_MISSING',
    }, 500);
  }

  const columns = [
    'id','title','description','price','stock','category','subcategory','image_url',
    'created_at','vendor_id','is_featured','is_pinned','featured_until','pinned_until',
    'boost_level','boost_until','allow_chat','show_phone','contact_phone','location_text',
    'external_link','is_negotiable','currency','views_count','province','brand','model',
    'sizes','colors','material','condition','product_code','specifications','is_active'
  ].join(',');

  try {
    const url = new URL(`${supabaseUrl}/rest/v1/products`);
    url.searchParams.set('select', columns);
    url.searchParams.set('id', `eq.${id}`);
    url.searchParams.set('limit', '1');

    const r = await fetch(url, {
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
        Accept: 'application/json',
      },
    });
    const rows = await r.json().catch(() => []);

    if (!r.ok) {
      console.error('Supabase listing error:', r.status, rows);
      return json({ error: 'خطا در ارتباط با پایگاه‌داده آگهی.', code: 'SUPABASE_QUERY_FAILED' }, 502);
    }

    const product = Array.isArray(rows) ? rows[0] : null;
    if (!product) return json({ error: 'آگهی پیدا نشد.', code: 'LISTING_NOT_FOUND' }, 404);

    let seller = {};
    if (product.vendor_id) {
      const profileUrl = new URL(`${supabaseUrl}/rest/v1/profiles`);
      profileUrl.searchParams.set('select', 'id,full_name,shop_name,phone,bio');
      profileUrl.searchParams.set('id', `eq.${product.vendor_id}`);
      profileUrl.searchParams.set('limit', '1');

      const pr = await fetch(profileUrl, {
        headers: {
          apikey: supabaseKey,
          Authorization: `Bearer ${supabaseKey}`,
          Accept: 'application/json',
        },
      });
      const profiles = await pr.json().catch(() => []);
      if (Array.isArray(profiles) && profiles[0]) seller = profiles[0];
    }

    return json({
      ...product,
      seller_name: seller.shop_name || seller.full_name || 'فروشنده بازارک',
      seller_phone: product.show_phone ? (product.contact_phone || seller.phone || '') : '',
      store_description: seller.bio || '',
    });
  } catch (error) {
    console.error('listing lookup failed:', error);
    return json({ error: 'خطا در دریافت آگهی.', code: 'LISTING_LOOKUP_FAILED' }, 502);
  }
}
