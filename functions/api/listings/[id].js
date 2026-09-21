export async function onRequestGet({ request, params, env }) {
  const id = String(params.id || '').trim();
  if (!id) return Response.json({ error: 'شناسه آگهی نامعتبر است.' }, { status: 400 });

  const supabaseUrl = String(env.SUPABASE_URL || '').replace(/\/$/, '');
  const supabaseKey = String(
    env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_KEY || env.SUPABASE_ANON_KEY || ''
  );
  if (!supabaseUrl || !supabaseKey) {
    return Response.json({ error: 'تنظیمات پایگاه‌داده Cloudflare کامل نیست.' }, { status: 500 });
  }

  const columns = [
    'id','title','description','price','stock','category','subcategory','image_url',
    'created_at','vendor_id','is_featured','is_pinned','featured_until','pinned_until',
    'boost_level','boost_until','allow_chat','show_phone','contact_phone','location_text',
    'external_link','is_negotiable','currency','views_count','province','brand','model',
    'sizes','colors','material','condition','product_code','specifications'
  ].join(',');

  const url = new URL(`${supabaseUrl}/rest/v1/products`);
  url.searchParams.set('select', columns);
  url.searchParams.set('id', `eq.${id}`);
  url.searchParams.set('is_active', 'eq.true');
  url.searchParams.set('limit', '1');

  try {
    const r = await fetch(url, {
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
        Accept: 'application/json',
      },
    });
    const rows = await r.json().catch(() => []);
    if (!r.ok) throw new Error(typeof rows === 'object' ? JSON.stringify(rows) : 'Supabase error');
    const product = Array.isArray(rows) ? rows[0] : null;
    if (!product) return Response.json({ error: 'آگهی پیدا نشد.' }, { status: 404 });

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

    return Response.json({
      ...product,
      seller_name: seller.shop_name || seller.full_name || 'فروشنده بازارک',
      seller_phone: product.show_phone ? (product.contact_phone || seller.phone || '') : '',
      store_description: seller.bio || '',
    }, {
      headers: {
        'Cache-Control': 'public, max-age=60, s-maxage=300',
      },
    });
  } catch (error) {
    console.error('listing lookup failed', error);
    return Response.json({ error: 'خطا در دریافت آگهی.' }, { status: 502 });
  }
}
