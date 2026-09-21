// Cloudflare Pages Function for direct listing deep-links.
// Important: never block the Flutter app with a server-side 404 here.
// The Flutter client fetches the listing from /api/listings/:id.

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

  const r = await fetch(url, {
    headers: {
      apikey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      Accept: 'application/json',
    },
  });
  if (!r.ok) return null;
  const rows = await r.json().catch(() => []);
  return Array.isArray(rows) ? (rows[0] || null) : null;
}

export async function onRequestGet({ request, params, env }) {
  const id = String(params.id || '').trim();
  const origin = new URL(request.url).origin;

  // Always return the real Flutter app for a deep link. This prevents a
  // server-side "آگهی پیدا نشد" page from replacing the application.
  let htmlResponse;
  try {
    const assetUrl = new URL('/index.html', request.url);
    htmlResponse = await env.ASSETS.fetch(new Request(assetUrl.toString(), request));
  } catch (_) {
    return new Response('Static asset unavailable', { status: 500 });
  }

  if (!htmlResponse.ok) return htmlResponse;

  let html = await htmlResponse.text();

  // Add listing metadata when the server can read it. If it cannot, the app
  // still loads normally and Flutter/API remains the source of truth.
  try {
    const product = id ? await getProduct(env, id) : null;
    if (product) {
      const title = `${product.title || 'آگهی'} | بازارک`;
      const descriptionRaw = `${product.title || 'آگهی'}؛ ${product.description || 'خرید و فروش در افغانستان'}`
        .replace(/\s+/g, ' ').trim();
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
          priceCurrency: String(product.currency || 'AFN').toUpperCase() === 'USD' ? 'USD' : 'AFN',
          ...(product.price != null ? { price: product.price } : {}),
          availability: 'https://schema.org/InStock',
        },
      }).replace(/<\/script/gi, '<\\/script');

      const tags = `\n<title>${esc(title)}</title>\n` +
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
    // Metadata is optional; never break the actual app because of SEO lookup.
  }

  return new Response(html, {
    status: 200,
    headers: {
      'content-type': 'text/html; charset=UTF-8',
      'Cache-Control': 'no-store',
    },
  });
}
