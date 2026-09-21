/**
 * functions/listing/[id].js
 *
 * Route: /listing/<id>
 *
 * هدف:
 *   1) Direct URL باز شود (بدون redirect به "/").
 *   2) همان Flutter shell عادی سایت تحویل داده شود (تا Flutter خودش آگهی را باز کند).
 *   3) HTML اولیه‌ای که crawlerها می‌بینند (title/description/OG/Twitter/JSON-LD)
 *      واقعاً مربوط به همان آگهی باشد.
 *   4) هر خطایی در مسیر Supabase/SEO باعث 500 یا شکست صفحه نشود؛ همیشه HTTP 200
 *      و shell سالم برگردانده می‌شود.
 *
 * این فایل مسیر "/api/listings/*" را تحت تأثیر قرار نمی‌دهد.
 */

const SEO_CACHE_CONTROL = "public, max-age=60, s-maxage=300";
const SUPABASE_TIMEOUT_MS = 5000;

export async function onRequestGet(context) {
  // 1) هر طور شده shell سالمی به دست بیاور. اگر هیچ‌کدام کار نکرد،
  //    یک fallback حداقلی برمی‌گردانیم تا هرگز 500 ندهیم.
  let shellResponse = null;
  try {
    shellResponse = await getShellResponse(context);
  } catch (err) {
    shellResponse = null;
  }

  if (!shellResponse) {
    return new Response(
      '<!doctype html><html><head><meta charset="utf-8"></head><body></body></html>',
      { status: 200, headers: { "content-type": "text/html; charset=utf-8" } }
    );
  }

  const id = context.params ? context.params.id : null;

  // اگر id نداریم یا پاسخ HTML نیست (مثلاً asset دیگری است)، دست‌نخورده برگردان.
  const contentType = shellResponse.headers.get("content-type") || "";
  if (!id || !contentType.includes("text/html")) {
    return shellResponse;
  }

  // 2) تلاش برای SEO injection. هر خطایی اینجا رخ دهد، shell خام برمی‌گردد.
  try {
    if (!isValidUuid(id)) {
      return shellResponse;
    }

    const product = await fetchProduct(context.env, id);
    if (!product) {
      return shellResponse;
    }

    const originalHtml = await shellResponse.clone().text();
    const finalHtml = injectSeo(originalHtml, product, context.request.url);

    const headers = new Headers(shellResponse.headers);
    headers.set("content-type", "text/html; charset=utf-8");
    headers.set("cache-control", SEO_CACHE_CONTROL);

    return new Response(finalHtml, { status: 200, headers });
  } catch (err) {
    return shellResponse;
  }
}

/**
 * shell را از مسیر عادی Pages می‌گیرد (context.next()).
 * اگر پاسخ next() سالم/HTML نبود (مثلاً چون _redirects فعلاً کار نمی‌کند و
 * asset server مسیر "/listing/<id>" را پیدا نمی‌کند)، به‌صورت fallback
 * مستقیماً "/index.html" را از ASSETS می‌گیرد. این fallback است، نه راه اصلی.
 */
async function getShellResponse(context) {
  let nextResponse = null;
  try {
    nextResponse = await context.next();
  } catch (err) {
    nextResponse = null;
  }

  const nextIsHtml =
    nextResponse &&
    (nextResponse.headers.get("content-type") || "").includes("text/html");

  if (nextResponse && nextResponse.ok && nextIsHtml) {
    return nextResponse;
  }

  if (context.env && context.env.ASSETS) {
    try {
      const shellUrl = new URL("/index.html", context.request.url);
      const shellRequest = new Request(shellUrl.toString(), context.request);
      const fallback = await context.env.ASSETS.fetch(shellRequest);
      if (fallback && fallback.ok) {
        return fallback;
      }
    } catch (err) {
      // نادیده گرفته می‌شود؛ در ادامه nextResponse (اگر باشد) برگردانده می‌شود
    }
  }

  return nextResponse;
}

/**
 * رکورد آگهی را از جدول products در Supabase (از طریق REST API) می‌گیرد.
 * در هر خطا (timeout، env متغیر نبود، 500، ...) مقدار null برمی‌گرداند
 * و هرگز throw نمی‌کند به بیرون از این تابع که باعث شکست صفحه شود.
 */
async function fetchProduct(env, id) {
  if (!env) return null;

  const supabaseUrl = env.SUPABASE_URL;
  const key =
    env.SUPABASE_SERVICE_ROLE_KEY ||
    env.SUPABASE_KEY ||
    env.SUPABASE_ANON_KEY;

  if (!supabaseUrl || !key) return null;

  const columns = [
    "id",
    "title",
    "description",
    "price",
    "currency",
    "category",
    "location_text",
    "province",
    "image_url",
    "is_active",
  ].join(",");

  const endpoint =
    `${supabaseUrl.replace(/\/+$/, "")}/rest/v1/products` +
    `?id=eq.${encodeURIComponent(id)}` +
    `&is_active=eq.true` +
    `&select=${columns}` +
    `&limit=1`;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), SUPABASE_TIMEOUT_MS);

  try {
    const res = await fetch(endpoint, {
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
        Accept: "application/json",
      },
      signal: controller.signal,
    });

    if (!res.ok) return null;

    const data = await res.json();
    if (!Array.isArray(data) || data.length === 0) return null;

    return data[0];
  } catch (err) {
    return null;
  } finally {
    clearTimeout(timeoutId);
  }
}

/**
 * meta tagهای قبلی (description/og:*/twitter:*/canonical) را حذف می‌کند
 * تا duplicate ایجاد نشود، سپس نسخه Dynamic را جایگزین می‌کند.
 */
function injectSeo(html, product, requestUrl) {
  const url = new URL(requestUrl);
  const canonicalUrl = `${url.origin}${url.pathname}`;

  const title = `${cleanText(product.title) || "آگهی"} | بازارک`;
  const rawDescription = cleanText(product.description);
  const description = truncate(
    rawDescription || `${cleanText(product.title) || ""} در بازارک`.trim(),
    160
  );

  const image = getFirstImage(product.image_url);
  const price = product.price !== null && product.price !== undefined
    ? String(product.price)
    : null;
  const currency = product.currency || "AFN";

  let cleaned = stripExistingSeoTags(html);

  const titleTag = `<title>${escapeHtml(title)}</title>`;
  if (/<title>[\s\S]*?<\/title>/i.test(cleaned)) {
    cleaned = cleaned.replace(/<title>[\s\S]*?<\/title>/i, titleTag);
  } else if (/<head[^>]*>/i.test(cleaned)) {
    cleaned = cleaned.replace(/<head[^>]*>/i, (m) => `${m}\n    ${titleTag}`);
  }

  const metaTags = [];
  metaTags.push(`<meta name="description" content="${escapeHtml(description)}">`);
  metaTags.push(`<link rel="canonical" href="${escapeHtml(canonicalUrl)}">`);
  metaTags.push(`<meta property="og:title" content="${escapeHtml(title)}">`);
  metaTags.push(`<meta property="og:description" content="${escapeHtml(description)}">`);
  metaTags.push(`<meta property="og:url" content="${escapeHtml(canonicalUrl)}">`);
  metaTags.push(`<meta property="og:type" content="product">`);
  metaTags.push(`<meta property="og:site_name" content="بازارک">`);
  if (image) {
    metaTags.push(`<meta property="og:image" content="${escapeHtml(image)}">`);
  }
  metaTags.push(
    `<meta name="twitter:card" content="${image ? "summary_large_image" : "summary"}">`
  );
  metaTags.push(`<meta name="twitter:title" content="${escapeHtml(title)}">`);
  metaTags.push(`<meta name="twitter:description" content="${escapeHtml(description)}">`);
  if (image) {
    metaTags.push(`<meta name="twitter:image" content="${escapeHtml(image)}">`);
  }

  const jsonLd = buildJsonLd({
    title: cleanText(product.title),
    description,
    canonicalUrl,
    image,
    price,
    currency,
  });
  metaTags.push(`<script type="application/ld+json">${jsonLd}</script>`);

  const injection = "    " + metaTags.join("\n    ") + "\n  ";

  if (/<\/head>/i.test(cleaned)) {
    cleaned = cleaned.replace(/<\/head>/i, `${injection}</head>`);
  } else if (/<head[^>]*>/i.test(cleaned)) {
    cleaned = cleaned.replace(/<head[^>]*>/i, (m) => `${m}\n${injection}`);
  }
  // اگر اصلاً <head> در HTML نبود، همان html اصلی (فقط با title اصلاح‌شده در صورت وجود) برمی‌گردد.

  return cleaned;
}

function stripExistingSeoTags(html) {
  return html
    .replace(/<meta[^>]+name=["']description["'][^>]*>\s*/gi, "")
    .replace(/<meta[^>]+property=["']og:[^"']+["'][^>]*>\s*/gi, "")
    .replace(/<meta[^>]+name=["']twitter:[^"']+["'][^>]*>\s*/gi, "")
    .replace(/<link[^>]+rel=["']canonical["'][^>]*>\s*/gi, "");
}

function buildJsonLd({ title, description, canonicalUrl, image, price, currency }) {
  const data = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: title || "",
    description: description || "",
    url: canonicalUrl,
  };

  if (image) {
    data.image = [image];
  }

  if (price) {
    data.offers = {
      "@type": "Offer",
      price: price,
      priceCurrency: currency,
      availability: "https://schema.org/InStock",
      url: canonicalUrl,
    };
  }

  // جلوگیری از بسته شدن زودهنگام تگ <script> در صورت وجود "</" در متن
  return JSON.stringify(data).replace(/</g, "\\u003c");
}

/**
 * image_url ممکن است: null، یک رشته URL ساده، یا رشته JSON از آرایه URLها باشد.
 * اولین URL معتبر را برمی‌گرداند.
 */
function getFirstImage(imageUrlField) {
  if (!imageUrlField) return null;

  if (Array.isArray(imageUrlField)) {
    const found = imageUrlField.find((u) => typeof u === "string" && u.trim());
    return found ? found.trim() : null;
  }

  if (typeof imageUrlField === "string") {
    const trimmed = imageUrlField.trim();
    if (!trimmed) return null;

    if (trimmed.startsWith("[")) {
      try {
        const arr = JSON.parse(trimmed);
        if (Array.isArray(arr)) {
          const found = arr.find((u) => typeof u === "string" && u.trim());
          return found ? found.trim() : null;
        }
      } catch (err) {
        return null;
      }
    }

    return trimmed;
  }

  return null;
}

function cleanText(value) {
  if (typeof value !== "string") return "";
  return value.replace(/\s+/g, " ").trim();
}

function truncate(str, maxLen) {
  if (!str) return "";
  if (str.length <= maxLen) return str;
  return str.slice(0, maxLen - 1).trim() + "…";
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function isValidUuid(id) {
  return (
    typeof id === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)
  );
}
