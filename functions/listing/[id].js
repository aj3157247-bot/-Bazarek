function esc(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function firstImage(raw) {
  try {
    if (Array.isArray(raw) && raw.length) return String(raw[0]);
    if (typeof raw === 'string' && raw.trim()) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length) return String(parsed[0]);
      if (/^https?:\/\//i.test(raw)) return raw;
    }
  } catch (_) {}
  return '';
}

async function getProduct(env, id) {
  const supabaseUrl = String(env.SUPABASE_URL || '').replace(/\/$/, '');
  const supabaseKey = String(env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_KEY || env.SUPABASE_ANON_KEY || '');
  if (!supabaseUrl || !supabaseKey) return null;
  const url = new URL(`${supabaseUrl}/rest/v1/products`);
  url.searchParams.set('select', 'id,title,description,price,currency,image_url,category,subcategory,location_text,province,is_active');
  url.searchParams.set('id', `eq.${id}`);
  url.searchParams.set('is_active', 'eq.true');
  url.searchParams.set('limit', '1');
  const r = await fetch(url, { headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` } });
  if (!r.ok) return null;
  const rows = await r.json().catch(() => []);
  return Array.isArray(rows) ? rows[0] || null : null;
}

export async function onRequestGet({ request, params, env }) {
  const id = String(params.id || '').trim();
  const origin = new URL(request.url).origin;
  let product = null;
  try { product = await getProduct(env, id); } catch (_) {}

  if (!product) {
    return new Response('<!doctype html><html lang="fa" dir="rtl"><head><meta charset="utf-8"><title>آگهی پیدا نشد | بازارک</title><meta name="robots" content="noindex"></head><body><h1>آگهی پیدا نشد.</h1><p><a href="/">بازگشت به بازارک</a></p></body></html>', {
      status: 404,
      headers: { 'content-type': 'text/html; charset=UTF-8' },
    });
  }

  const title = `${product.title || 'آگهی'} | بازارک`;
  const descriptionRaw = `${product.title || 'آگهی'}؛ ${product.description || 'خرید و فروش در افغانستان'}`.replace(/\s+/g, ' ').trim();
  const description = descriptionRaw.slice(0, 250);
  const canonical = `${origin}/listing/${encodeURIComponent(id)}`;
  const image = firstImage(product.image_url);

  let htmlResponse;
  try {
    const assetUrl = new URL('/index.html', request.url);
    htmlResponse = await env.ASSETS.fetch(new Request(assetUrl.toString(), request));
  } catch (_) {
    return new Response('Static asset unavailable', { status: 500 });
  }
  let html = await htmlResponse.text();
  const tags = `
<title>${esc(title)}</title>
<meta name="description" content="${esc(description)}">
<meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1">
<link rel="canonical" href="${esc(canonical)}">
<meta property="og:type" content="product">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(description)}">
<meta property="og:url" content="${esc(canonical)}">
<meta property="og:locale" content="fa_AF">
${image ? `<meta property="og:image" content="${esc(image)}">` : ''}
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${esc(title)}">
<meta name="twitter:description" content="${esc(description)}">
${image ? `<meta name="twitter:image" content="${esc(image)}">` : ''}
<script type="application/ld+json">${JSON.stringify({
    '@context': 'https://schema.org', '@type': 'Product', name: product.title || 'آگهی بازارک', description: description,
    image: image ? [image] : undefined,
    offers: { '@type': 'Offer', url: canonical, priceCurrency: String(product.currency || 'AFN').toUpperCase() === 'USD' ? 'USD' : 'AFN', price: product.price ?? undefined, availability: 'https://schema.org/InStock' }
  }).replace(/<\/script/gi, '<\\/script')}</script>`;
  html = html.replace('</head>', `${tags}\n</head>`);
  return new Response(html, {
    status: 200,
    headers: { 'content-type': 'text/html; charset=UTF-8', 'Cache-Control': 'public, max-age=60, s-maxage=300' },
  });
}
