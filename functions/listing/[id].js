// Cloudflare Pages Function for direct listing deep-links.
// Always serve the Flutter shell with HTTP 200 while keeping the requested
// /listing/<id> URL in the browser. Listing data is loaded by Flutter from
// /api/listings/<id>.

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
  const supabaseKey = String(
    env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_KEY || env.SUPABASE_ANON_KEY || ''
  );
  if (!supabaseUrl || !supabaseKey) return null;

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

export async function onRequestGet({ request, params, env }) {
  const id = String(params.id || '').trim();
  const origin = new URL(request.url).origin;

  // IMPORTANT: fetch the pretty root path, not /index.html.
  // Cloudflare's asset service can redirect /index.html to /, which would
  // otherwise turn /listing/<id> into the home page before Flutter starts.
  let htmlResponse;
  try {
    const assetUrl = new URL('/', request.url);
    htmlResponse = await env.ASSETS.fetch(new Request(assetUrl.toString(), request));
  } catch (_) {
    return new Response('Static asset unavailable', { status: 500 });
  }

  if (!htmlResponse.ok) return htmlResponse;

  let html = await htmlResponse.text();

  // Server-side listing metadata is optional. If the database is unavailable,
  // the Flutter app still loads normally and gets the listing from its API.
  try {
    const product = id ? await getProduct(env, id) : null;
    if (product) {
      const title = `${product.title || 'آگهی'} | بازارک`;
      const descriptionRaw = `${product.title || 'آگهی'}؛ ${product.description || 'خرید و فروش در افغانستان'}`
        .replace(/\s+/g, ' ')
        .trim();
      const description = descriptionRaw.slice(0, 250);
      const canonical = `${origin}/listing/${encodeURIComponent(id)}`;
      const image = firstImage(product.image_url);

      const jsonLd = JSON.stringify({
        '@context': 'https://schema.org',
        '@type': 'Product',
        name: product.title || 'آگهی بازارک',
        description,
        ...(image ? { image: [image] } : {}),
        offers: {
          '@type': 'Offer',
          url: canonical,
          priceCurrency:
            String(product.currency || 'AFN').toUpperCase() === 'USD' ? 'USD' : 'AFN',
          ...(product.price != null ? { price: product.price } : {}),
          availability: 'https://schema.org/InStock',
        },
      }).replace(/<\/script/gi, '<\\/script');

      const tags =
        `\n<title>${esc(title)}</title>\n` +
        `<meta name="description" content="${esc(description)}">\n` +
        `<meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1">\n` +
        `<link rel="canonical" href="${esc(canonical)}">\n` +
        `<meta property="og:type" content="product">\n` +
        `<meta property="og:title" content="${esc(title)}">\n` +
        `<meta property="og:description" content="${esc(description)}">\n` +
        `<meta property="og:url" content="${esc(canonical)}">\n` +
        `<meta property="og:locale" content="fa_AF">\n` +
        (image ? `<meta property="og:image" content="${esc(image)}">\n` : '') +
        `<meta name="twitter:card" content="summary_large_image">\n` +
        `<meta name="twitter:title" content="${esc(title)}">\n` +
        `<meta name="twitter:description" content="${esc(description)}">\n` +
        (image ? `<meta name="twitter:image" content="${esc(image)}">\n` : '') +
        `<script type="application/ld+json">${jsonLd}</script>`;

      html = html.replace('</head>', `${tags}\n</head>`);
    }
  } catch (_) {
    // SEO metadata must never prevent the actual Flutter app from loading.
  }

  return new Response(html, {
    status: 200,
    headers: {
      'content-type': 'text/html; charset=UTF-8',
      'Cache-Control': 'no-store',
    },
  });
}
