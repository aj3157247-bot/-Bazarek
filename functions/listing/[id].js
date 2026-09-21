// Bazarek - SEO-aware Cloudflare Pages Function for /listing/<id>.
// Serves the Flutter shell at the requested listing URL and injects
// listing-specific SEO metadata when the listing can be read.

function cleanText(value, fallback = '') {
  return String(value ?? fallback).replace(/\s+/g, ' ').trim();
}

function esc(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function jsSafeJson(value) {
  return JSON.stringify(value).replace(/<\/script/gi, '<\\/script');
}

function firstImage(...values) {
  for (const raw of values) {
    if (Array.isArray(raw)) {
      const found = raw.find((v) => typeof v === 'string' && v.trim());
      if (found) return found.trim();
      continue;
    }

    if (typeof raw !== 'string') continue;
    const value = raw.trim();
    if (!value) continue;

    try {
      const parsed = JSON.parse(value);
      if (Array.isArray(parsed)) {
        const found = parsed.find((v) => typeof v === 'string' && v.trim());
        if (found) return found.trim();
      }
    } catch (_) {}

    if (/^https?:\/\//i.test(value)) return value;
  }
  return '';
}

function numericPrice(value) {
  if (typeof value === 'number' && Number.isFinite(value) && value >= 0) return value;

  if (typeof value === 'string') {
    const normalized = value
      .replace(/[٬،,\s]/g, '')
      .replace(/[۰-۹]/g, (d) => String('۰۱۲۳۴۵۶۷۸۹'.indexOf(d)))
      .replace(/[٠-٩]/g, (d) => String('٠١٢٣٤٥٦٧٨٩'.indexOf(d)));

    const n = Number(normalized);
    if (Number.isFinite(n) && n >= 0) return n;
  }

  return null;
}

function normalizeCurrency(value) {
  const c = cleanText(value, 'AFN').toUpperCase();
  if (c === 'USD' || c === 'US$' || c === '$' || c === 'دالر' || c === 'دلار') return 'USD';
  return 'AFN';
}

function priceText(product) {
  const price = numericPrice(product.price);
  if (price == null) return '';

  const currency = normalizeCurrency(product.currency);
  const formatted = new Intl.NumberFormat('fa-AF', {
    maximumFractionDigits: 2,
  }).format(price);

  return `قیمت: ${formatted} ${currency === 'USD' ? 'دالر' : 'افغانی'}`;
}

function imageFromProduct(product) {
  return firstImage(
    product.image_url,
    product.image_urls,
    product.images,
    product.photos,
    product.photo_urls,
    product.thumbnail,
    product.cover_image,
    product.cover_image_url
  );
}

function locationFromProduct(product) {
  return cleanText(
    product.location_text ||
    product.location ||
    product.city ||
    product.province ||
    product.address ||
    ''
  );
}

function buildDescription(product) {
  const title = cleanText(product.title, 'آگهی بازارک');
  const details = cleanText(product.description);
  const category = cleanText(product.category);
  const subcategory = cleanText(product.subcategory);
  const location = locationFromProduct(product);
  const price = priceText(product);

  const parts = [title];
  if (details) parts.push(details.slice(0, 220));
  if (price) parts.push(price);
  if (category) {
    parts.push(`دسته‌بندی: ${category}${subcategory ? `، ${subcategory}` : ''}`);
  }
  if (location) parts.push(`موقعیت: ${location}`);
  parts.push('خرید و فروش در بازار آنلاین افغانستان، بازارک.');

  return parts.join('؛ ').replace(/\s+/g, ' ').slice(0, 320);
}

function buildProductJsonLd(product, canonical, description, image) {
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
  if (product.category) data.category = cleanText(product.category);

  if (price != null) {
    data.offers = {
      '@type': 'Offer',
      url: canonical,
      priceCurrency: currency,
      price,
      availability: 'https://schema.org/InStock',
    };
  }

  return jsSafeJson(data);
}

function setOrAddMeta(html, selectorRegex, tag) {
  if (selectorRegex.test(html)) return html.replace(selectorRegex, tag);
  return html.replace(/<\/head>/i, `${tag}\n</head>`);
}

function setOrAddLink(html, selectorRegex, tag) {
  if (selectorRegex.test(html)) return html.replace(selectorRegex, tag);
  return html.replace(/<\/head>/i, `${tag}\n</head>`);
}

function injectSeo(html, product, canonical) {
  const title = `${cleanText(product.title, 'آگهی')} | بازارک`;
  const description = buildDescription(product);
  const image = imageFromProduct(product);
  const location = locationFromProduct(product);
  const price = priceText(product);

  html = /<title[^>]*>[\s\S]*?<\/title>/i.test(html)
    ? html.replace(/<title[^>]*>[\s\S]*?<\/title>/i, `<title>${esc(title)}</title>`)
    : html.replace(/<\/head>/i, `<title>${esc(title)}</title>\n</head>`);

  html = setOrAddMeta(
    html,
    /<meta\s+name=["']description["'][^>]*>/i,
    `<meta name="description" content="${esc(description)}">`
  );

  html = setOrAddMeta(
    html,
    /<meta\s+name=["']robots["'][^>]*>/i,
    '<meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1">'
  );

  html = setOrAddLink(
    html,
    /<link\s+rel=["']canonical["'][^>]*>/i,
    `<link rel="canonical" href="${esc(canonical)}">`
  );

  const metas = [
    ['property', 'og:type', 'product'],
    ['property', 'og:title', title],
    ['property', 'og:description', description],
    ['property', 'og:url', canonical],
    ['property', 'og:locale', 'fa_AF'],
    ['name', 'twitter:card', 'summary_large_image'],
    ['name', 'twitter:title', title],
    ['name', 'twitter:description', description],
  ];

  if (image) {
    metas.push(['property', 'og:image', image]);
    metas.push(['name', 'twitter:image', image]);
  }

  if (price) {
    metas.push(['property', 'product:price:amount', String(numericPrice(product.price))]);
    metas.push(['property', 'product:price:currency', normalizeCurrency(product.currency)]);
  }

  if (location) {
    metas.push(['property', 'og:locality', location]);
  }

  for (const [kind, key, value] of metas) {
    const attr = kind === 'property' ? 'property' : 'name';
    const pattern = new RegExp(`<meta\\s+${attr}=["']${key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}["'][^>]*>`, 'i');
    html = setOrAddMeta(html, pattern, `<meta ${attr}="${esc(key)}" content="${esc(value)}">`);
  }

  const jsonLd = buildProductJsonLd(product, canonical, description, image);
  const jsonLdPattern = /<script\s+type=["']application\/ld\+json["'][^>]*data-bazarek-listing-seo=["']1["'][^>]*>[\s\S]*?<\/script>/i;
  const jsonLdTag = `<script type="application/ld+json" data-bazarek-listing-seo="1">${jsonLd}</script>`;

  if (jsonLdPattern.test(html)) {
    html = html.replace(jsonLdPattern, jsonLdTag);
  } else {
    html = html.replace(/<\/head>/i, `${jsonLdTag}\n</head>`);
  }

  return html;
}

async function getProduct(env, id) {
  const supabaseUrl = String(env.SUPABASE_URL || '').replace(/\/$/, '');
  const supabaseKey = String(
    env.SUPABASE_SERVICE_ROLE_KEY ||
    env.SUPABASE_KEY ||
    env.SUPABASE_ANON_KEY ||
    ''
  );

  if (!supabaseUrl || !supabaseKey || !id) return null;

  const url = new URL(`${supabaseUrl}/rest/v1/products`);
  url.searchParams.set(
    'select',
    [
      'id',
      'title',
      'description',
      'price',
      'currency',
      'image_url',
      'image_urls',
      'images',
      'photos',
      'photo_urls',
      'thumbnail',
      'cover_image',
      'cover_image_url',
      'category',
      'subcategory',
      'location_text',
      'location',
      'city',
      'province',
      'address',
      'is_active',
    ].join(',')
  );
  url.searchParams.set('id', `eq.${id}`);
  url.searchParams.set('is_active', 'eq.true');
  url.searchParams.set('limit', '1');

  const response = await fetch(url.toString(), {
    method: 'GET',
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

export async function onRequestGet({ request, params, env }) {
  const id = String(params.id || '').trim();
  const requestUrl = new URL(request.url);
  const canonical = `${requestUrl.origin}/listing/${encodeURIComponent(id)}`;

  let htmlResponse;

  try {
    // Cloudflare recommends fetching the pretty path rather than /index.html.
    htmlResponse = await env.ASSETS.fetch(
      new Request(new URL('/', request.url).toString(), request)
    );
  } catch (_) {
    return new Response('Static asset unavailable', { status: 500 });
  }

  if (!htmlResponse.ok) return htmlResponse;

  let html = await htmlResponse.text();

  try {
    const product = await getProduct(env, id);
    if (product) {
      html = injectSeo(html, product, canonical);
    }
  } catch (_) {
    // SEO must never prevent the Flutter application from loading.
  }

  return new Response(html, {
    status: 200,
    headers: {
      'content-type': 'text/html; charset=UTF-8',
      'cache-control': 'no-store',
      'x-bazarek-seo': 'listing',
    },
  });
}
