const SITE = 'https://bazarek.pages.dev';
const API = 'https://bazarek.onrender.com/api';
const FALLBACK_IMAGE = `${SITE}/icons/bazarek-pwa-192.png`;

function esc(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function jsonForHtml(value) {
  return JSON.stringify(value)
    .replace(/</g, '\\u003c')
    .replace(/>/g, '\\u003e')
    .replace(/&/g, '\\u0026');
}

function firstImage(value) {
  if (Array.isArray(value)) return String(value.find(Boolean) || '');
  if (typeof value === 'string') {
    const raw = value.trim();
    if (!raw) return '';
    try {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) return String(parsed.find(Boolean) || '');
    } catch (_) {}
    return raw;
  }
  return '';
}

function cleanText(value, max = 320) {
  const text = String(value ?? '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  return text.length > max ? `${text.slice(0, max - 1).trim()}…` : text;
}

function formatPrice(product) {
  const n = Number(product?.price);
  if (!Number.isFinite(n) || n <= 0) return '';
  const currency = String(product?.currency || 'AFN').toUpperCase();
  const label = currency === 'AFN' ? 'افغانی' : currency;
  return `${new Intl.NumberFormat('fa-AF').format(n)} ${label}`;
}

function buildProductSchema(product, url, image) {
  const title = cleanText(product.title, 180) || 'آگهی در بازارک';
  const description = cleanText(product.description, 500) || `${title}؛ خرید و فروش در افغانستان در بازارک.`;
  const schema = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    '@id': `${url}#product`,
    name: title,
    description,
    url,
    image: image ? [image] : [FALLBACK_IMAGE],
    brand: product.brand ? { '@type': 'Brand', name: cleanText(product.brand, 100) } : undefined,
    model: product.model ? cleanText(product.model, 100) : undefined,
    sku: product.product_code ? cleanText(product.product_code, 100) : undefined,
    offers: Number.isFinite(Number(product.price)) && Number(product.price) > 0 ? {
      '@type': 'Offer',
      url,
      priceCurrency: String(product.currency || 'AFN').toUpperCase(),
      price: Number(product.price),
      availability: product.stock === 0 ? 'https://schema.org/OutOfStock' : 'https://schema.org/InStock',
      itemCondition: 'https://schema.org/NewCondition',
    } : undefined,
  };
  return JSON.parse(JSON.stringify(schema));
}

function pageHtml(product, id) {
  const url = `${SITE}/listing/${encodeURIComponent(id)}`;
  const title = cleanText(product.title, 180) || 'آگهی در بازارک';
  const price = formatPrice(product);
  const province = cleanText(product.province || product.location_text, 100);
  const description = cleanText(product.description, 320) || `${title}؛ خرید و فروش در افغانستان در بازار آنلاین بازارک.`;
  const image = firstImage(product.image_url) || FALLBACK_IMAGE;
  const productSchema = buildProductSchema(product, url, image);
  const breadcrumbSchema = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'بازارک', item: SITE },
      { '@type': 'ListItem', position: 2, name: 'آگهی', item: url },
    ],
  };

  return `<!DOCTYPE html>
<html lang="fa-AF" dir="rtl">
<head>
  <base href="/">
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1">
  <meta name="googlebot" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1">
  <title>${esc(title)} | بازارک افغانستان</title>
  <meta name="description" content="${esc(description)}${price ? ` قیمت: ${esc(price)}.` : ''}${province ? ` موقعیت: ${esc(province)}.` : ''}">
  <link rel="canonical" href="${esc(url)}">
  <meta property="og:type" content="product">
  <meta property="og:locale" content="fa_AF">
  <meta property="og:site_name" content="بازارک">
  <meta property="og:title" content="${esc(title)} | بازارک افغانستان">
  <meta property="og:description" content="${esc(description)}">
  <meta property="og:url" content="${esc(url)}">
  <meta property="og:image" content="${esc(image)}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${esc(title)} | بازارک افغانستان">
  <meta name="twitter:description" content="${esc(description)}">
  <meta name="twitter:image" content="${esc(image)}">
  <link rel="icon" type="image/png" href="/icons/bazarek-pwa-192.png">
  <link rel="manifest" href="/manifest.json">
  <script type="application/ld+json">${jsonForHtml(productSchema)}</script>
  <script type="application/ld+json">${jsonForHtml(breadcrumbSchema)}</script>
</head>
<body>
  <main id="seo-listing-content" style="max-width:900px;margin:0 auto;padding:24px;font-family:Arial,sans-serif;line-height:1.9">
    <article>
      <h1>${esc(title)}</h1>
      ${price ? `<p><strong>قیمت:</strong> ${esc(price)}</p>` : ''}
      ${province ? `<p><strong>موقعیت:</strong> ${esc(province)}</p>` : ''}
      <p>${esc(description)}</p>
      <p><a href="${esc(url)}">مشاهده آگهی در بازارک</a></p>
      <img src="${esc(image)}" alt="${esc(title)}" style="max-width:100%;height:auto" loading="eager">
    </article>
  </main>
  <script src="/flutter_bootstrap.js" async></script>
</body>
</html>`;
}

export async function onRequestGet({ params }) {
  const id = String(params?.id || '').trim();
  if (!/^[0-9a-fA-F-]{36}$/.test(id)) {
    return new Response('آدرس آگهی نامعتبر است.', { status: 400, headers: { 'content-type': 'text/plain; charset=utf-8' } });
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 12000);
  try {
    const response = await fetch(`${API}/listings/${encodeURIComponent(id)}`, {
      headers: { accept: 'application/json' },
      signal: controller.signal,
    });
    if (!response.ok) {
      return new Response('آگهی پیدا نشد.', {
        status: response.status === 404 ? 404 : 502,
        headers: { 'content-type': 'text/plain; charset=utf-8', 'cache-control': 'no-store' },
      });
    }
    const product = await response.json();
    return new Response(pageHtml(product, id), {
      status: 200,
      headers: {
        'content-type': 'text/html; charset=utf-8',
        'cache-control': 'public, max-age=60, s-maxage=300',
        'x-bazarek-seo': 'listing-ssr',
      },
    });
  } catch (error) {
    console.error('Bazarek listing SSR error:', error);
    return new Response('خطا در دریافت آگهی.', {
      status: 502,
      headers: { 'content-type': 'text/plain; charset=utf-8', 'cache-control': 'no-store' },
    });
  } finally {
    clearTimeout(timer);
  }
}
