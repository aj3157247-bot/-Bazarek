// Bazarek - SEO-aware Cloudflare Pages Function for /listing/<id>.
// Keeps the requested URL, serves the Flutter shell with HTTP 200, and injects
// per-listing SEO metadata into the initial HTML for search/social crawlers.

function esc(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function cleanText(value, fallback = '') {
  return String(value ?? fallback)
    .replace(/\s+/g, ' ')
    .trim();
}

function firstImage(raw) {
  if (Array.isArray(raw)) {
    const value = raw.find((item) => typeof item === 'string' && item.trim());
    return value ? value.trim() : '';
  }

  if (typeof raw !== 'string') return '';
  const value = raw.trim();
  if (!value) return '';

  try {
    const parsed = JSON.parse(value);
    if (Array.isArray(parsed)) {
      const image = parsed.find((item) => typeof item === 'string' && item.trim());
      if (image) return image.trim();
    }
  } catch (_) {}

  return /^https?:\/\//i.test(value) ? value : '';
}

function normalizeCurrency(value) {
  const currency = cleanText(value, 'AFN').toUpperCase();
  return currency === 'USD' ? 'USD' : 'AFN';
}

function numericPrice(value) {
  if (typeof value === 'number' && Number.isFinite(value) && value >= 0) return value;
  if (typeof value === 'string') {
    const normalized = value.replace(/,/g, '').trim();
    const parsed = Number(normalized);
    if (Number.isFinite(parsed) && parsed >= 0) return parsed;
  }
  return null;
}

function upsertHeadTag(html, pattern, tag) {
  return pattern.test(html) ? html.replace(pattern, tag) : null;
}

async function getProduct(env, id) {
  const supabaseUrl = String(env.SUPABASE_URL || '').replace(/\/$/, '');
  const supabaseKey = String(
    env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_KEY || env.SUPABASE_ANON_KEY || ''
  );
  if (!supabaseUrl || !supabaseKey || !id) return null;

  const url = new URL(`${supabaseUrl}/rest/v1/products`);
  url.searchParams.set(
    'select',
    'id,title,description,price,currency,image_url,category,subcategory,location_text,province,is_active'
  );
  url.searchParams.set('id', `eq.${id}`);
  url.searchParams.set('is_active', 'eq.true');
  url.searchParams.set('limit', '1');

  const response = await fetch(url, {
    headers: {
      apikey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      Accept: 'application/json',
    },
  });

  if (!response.ok) return null;
  const rows = await response.json().catch(() => []);
  return Array.isArray(rows) ? (rows[0] || null) : null;
}

function buildDescription(product) {
  const title = cleanText(product.title, 'آگهی در بازارک');
  const details = cleanText(product.description);
  const category = cleanText(product.category);
  const subcategory = cleanText(product.subcategory);
  const location = cleanText(product.location_text || product.province);

  const parts = [title];
  if (details) parts.push(details);
  if (category) parts.push(`دسته‌بندی: ${category}${subcategory ? `، ${subcategory}` : ''}`);
  if (location) parts.push(`موقعیت: ${location}`);
  parts.push('خرید و فروش در بازار آنلاین افغانستان، بازارک.');

  return parts.join('؛ ').replace(/\s+/g, ' ').trim().slice(0, 300);
}

function buildPriceText(product) {
  const price = numericPrice(product.price);
  if (price == null) return '';
  const currency = normalizeCurrency(product.currency);
  const formatted = new Intl.NumberFormat('fa-AF', {
    maximumFractionDigits: 2,
  }).format(price);
  return `قیمت: ${formatted} ${currency === 'AFN' ? 'افغانی' : 'دالر'}`;
}

function buildJsonLd(product, canonical, description, image) {
  const title = cleanText(product.title, 'آگهی بازارک');
  const price = numericPrice(product.price);
  const currency = normalizeCurrency(product.currency);

  const data = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: title,
    description,
    url: canonical,
  };

  if (image) data.image = [image];

  const priceText = buildPriceText(product);
  if (priceText) data.offers = {
    '@type': 'Offer',
    url: canonical,
    priceCurrency: currency,
    price,
    availability: 'https://schema.org/InStock',
  };

  if (product.category) data.category = cleanText(product.category);

  return JSON.stringify(data).replace(/<\/script/gi, '<\\/script');
}

function injectSeo(html, product, canonical) {
  const title = `${cleanText(product.title, 'آگهی')} | بازارک`;
  const description = buildDescription(product);
  const image = firstImage(product.image_url);
  const priceText = buildPriceText(product);
  const jsonLd = buildJsonLd(product, canonical, description, image);

  const replacements = [
    [/<title[^>]*>[\s\S]*?<\/title>/i, `<title>${esc(title)}</title>`],
    [/<meta\s+name=["']description["'][^>]*>/i, `<meta name="description" content="${esc(description)}">`],
    [/<meta\s+name=["']robots["'][^>]*>/i, '<meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1">'],
    [/<link\s+rel=["']canonical["'][^>]*>/i, `<link rel="canonical" href="${esc(canonical)}">`],
    [/<meta\s+property=["']og:type["'][^>]*>/i, '<meta property="og:type" content="product">'],
    [/<meta\s+property=["']og:title["'][^>]*>/i, `<meta property="og:title" content="${esc(title)}">`],
    [/<meta\s+property=["']og:description["'][^>]*>/i, `<meta property="og:description" content="${esc(description)}">`],
    [/<meta\s+property=["']og:url["'][^>]*>/i, `<meta property="og:url" content="${esc(canonical)}">`],
    [/<meta\s+property=["']og:locale["'][^>]*>/i, '<meta property="og:locale" content="fa_AF">'],
    [/<meta\s+property=["']og:image["'][^>]*>/i, image ? `<meta property="og:image" content="${esc(image)}">` : ''],
    [/<meta\s+name=["']twitter:card["'][^>]*>/i, '<meta name="twitter:card" content="summary_large_image">'],
    [/<meta\s+name=["']twitter:title["'][^>]*>/i, `<meta name="twitter:title" content="${esc(title)}">`],
    [/<meta\s+name=["']twitter:description["'][^>]*>/i, `<meta name="twitter:description" content="${esc(description)}">`],
    [/<meta\s+name=["']twitter:image["'][^>]*>/i, image ? `<meta name="twitter:image" content="${esc(image)}">` : ''],
  ];

  for (const [pattern, tag] of replacements) {
    const updated = upsertHeadTag(html, pattern, tag);
    if (updated !== null) html = updated;
  }

  // Add price information to the description only when a valid price exists.
  // This is useful for social/search previews without inventing a price.
  if (priceText && !description.includes(priceText)) {
    // Keep the existing description stable; Product JSON-LD carries the exact price.
  }

  const jsonLdPattern = /<script\s+type=["']application\/ld\+json["'][^>]*data-bazarek-listing-seo=["']1["'][^>]*>[\s\S]*?<\/script>/i;
  const jsonLdTag = `<script type="application/ld+json" data-bazarek-listing-seo="1">${jsonLd}</script>`;
  const existingJsonLd = upsertHeadTag(html, jsonLdPattern, jsonLdTag);
  if (existingJsonLd !== null) {
    html = existingJsonLd;
  } else {
    html = html.replace(/<\/head>/i, `${jsonLdTag}\n</head>`);
  }

  return html;
}

export async function onRequestGet({ request, params, env }) {
  const id = String(params.id || '').trim();
  const origin = new URL(request.url).origin;
  const canonical = `${origin}/listing/${encodeURIComponent(id)}`;

  let htmlResponse;
  try {
    // Use the pretty root path so Pages does not redirect /index.html to /.
    const assetUrl = new URL('/', request.url);
    htmlResponse = await env.ASSETS.fetch(new Request(assetUrl.toString(), request));
  } catch (_) {
    return new Response('Static asset unavailable', { status: 500 });
  }

  if (!htmlResponse.ok) return htmlResponse;

  let html = await htmlResponse.text();

  try {
    const product = id ? await getProduct(env, id) : null;
    if (product) html = injectSeo(html, product, canonical);
  } catch (_) {
    // SEO must never prevent the Flutter app from loading.
  }

  return new Response(html, {
    status: 200,
    headers: {
      'content-type': 'text/html; charset=UTF-8',
      'Cache-Control': 'no-store',
    },
  });
}
