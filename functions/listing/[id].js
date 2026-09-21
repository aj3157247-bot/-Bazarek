function escHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function cleanText(value, max = 180) {
  return String(value ?? "")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, max);
}

function firstImage(value) {
  if (!value) return "";
  if (Array.isArray(value)) return String(value[0] || "");
  const raw = String(value).trim();

  try {
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed)) return String(parsed[0] || "");
    if (typeof parsed === "string") return parsed;
  } catch (_) {}

  if (raw.startsWith("[") && raw.endsWith("]")) {
    const match = raw.match(/https?:\/\/[^"'\\\s]+/);
    if (match) return match[0];
  }

  return raw;
}

function formatPrice(value, currency) {
  if (value === null || value === undefined || value === "") return "";
  const number = Number(value);
  if (!Number.isFinite(number)) return cleanText(value, 80);

  const formatted = new Intl.NumberFormat("en-US", {
    maximumFractionDigits: 0,
  }).format(number);

  const labels = {
    AFN: "افغانی",
    USD: "دالر",
    EUR: "یورو",
    PKR: "روپیه",
  };

  return `${formatted} ${labels[currency] || currency || ""}`.trim();
}

function replaceTag(html, tagName, key, value) {
  const safeKey = String(key).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const safeValue = escHtml(value);
  const attr = tagName === "title" ? "" : ` ${tagName}="${safeKey}"`;

  if (tagName === "title") {
    const re = /<title\b[^>]*>[\s\S]*?<\/title>/i;
    if (re.test(html)) return html.replace(re, `<title>${safeValue}</title>`);
    return html.replace(/<\/head>/i, `<title>${safeValue}</title>\n</head>`);
  }

  const re = new RegExp(
    `<meta\\b[^>]*\\b${tagName}\\s*=\\s*["']${safeKey}["'][^>]*>`,
    "i"
  );
  const tag = `<meta${attr} content="${safeValue}">`;

  if (re.test(html)) return html.replace(re, tag);
  return html.replace(/<\/head>/i, `${tag}\n</head>`);
}

function replaceLinkCanonical(html, href) {
  const safeHref = escHtml(href);
  const re = /<link\b[^>]*\brel\s*=\s*["']canonical["'][^>]*>/i;
  const tag = `<link rel="canonical" href="${safeHref}">`;

  if (re.test(html)) return html.replace(re, tag);
  return html.replace(/<\/head>/i, `${tag}\n</head>`);
}

function replaceOrAddJsonLd(html, data) {
  const json = JSON.stringify(data).replace(/</g, "\\u003c");
  const tag = `<script type="application/ld+json" id="bazarek-listing-jsonld">${json}</script>`;
  const re = /<script\b[^>]*type\s*=\s*["']application\/ld\+json["'][^>]*id\s*=\s*["']bazarek-listing-jsonld["'][^>]*>[\s\S]*?<\/script>/i;

  if (re.test(html)) return html.replace(re, tag);
  return html.replace(/<\/head>/i, `${tag}\n</head>`);
}

async function fetchShell(env) {
  const asset = await env.ASSETS.fetch("/");
  if (!asset || !asset.ok) {
    throw new Error(`ASSETS fetch failed: ${asset?.status ?? "unknown"}`);
  }
  return await asset.text();
}

async function getProduct(env, id) {
  const supabaseUrl = String(env.SUPABASE_URL || "").replace(/\/+$/, "");
  const supabaseKey =
    env.SUPABASE_SERVICE_ROLE_KEY ||
    env.SUPABASE_KEY ||
    env.SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseKey) {
    return null;
  }

  const url =
    `${supabaseUrl}/rest/v1/products` +
    `?select=*` +
    `&id=eq.${encodeURIComponent(id)}` +
    `&is_active=eq.true` +
    `&limit=1`;

  const response = await fetch(url, {
    headers: {
      apikey: String(supabaseKey),
      Authorization: `Bearer ${String(supabaseKey)}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Supabase products request failed: ${response.status}`);
  }

  const rows = await response.json();
  return Array.isArray(rows) && rows.length ? rows[0] : null;
}

function buildSeoHtml(html, product, requestUrl) {
  const title = cleanText(product.title, 120) || "آگهی در بازارک";
  const description =
    cleanText(product.description, 180) ||
    `آگهی ${title} در بازار آنلاین افغانستان، بازارک.`;

  const canonical = requestUrl.toString().split("?")[0].split("#")[0];
  const image = firstImage(product.image_url);
  const price = formatPrice(product.price, product.currency);
  const location =
    cleanText(product.location_text, 120) ||
    cleanText(product.location, 120) ||
    cleanText(product.province, 80);

  let out = html;

  out = replaceTag(out, "title", "", `${title} | بازارک`);
  out = replaceTag(out, "name", "description", description);
  out = replaceTag(out, "name", "robots", "index,follow,max-image-preview:large");
  out = replaceTag(out, "property", "og:title", title);
  out = replaceTag(out, "property", "og:description", description);
  out = replaceTag(out, "property", "og:url", canonical);
  out = replaceTag(out, "property", "og:type", "product");
  out = replaceTag(out, "property", "og:locale", "fa_AF");

  if (image) {
    out = replaceTag(out, "property", "og:image", image);
    out = replaceTag(out, "property", "og:image:alt", title);
    out = replaceTag(out, "name", "twitter:image", image);
  }

  out = replaceTag(out, "name", "twitter:card", image ? "summary_large_image" : "summary");
  out = replaceTag(out, "name", "twitter:title", title);
  out = replaceTag(out, "name", "twitter:description", description);
  out = replaceLinkCanonical(out, canonical);

  if (price) {
    out = replaceTag(out, "property", "product:price:amount", String(product.price));
    out = replaceTag(out, "property", "product:price:currency", product.currency || "AFN");
  }

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: title,
    description,
    url: canonical,
    ...(image ? { image: [image] } : {}),
    ...(price
      ? {
          offers: {
            "@type": "Offer",
            price: String(product.price),
            priceCurrency: product.currency || "AFN",
            availability: product.is_active === false
              ? "https://schema.org/OutOfStock"
              : "https://schema.org/InStock",
            url: canonical,
          },
        }
      : {}),
    ...(location ? { areaServed: location } : {}),
    brand: {
      "@type": "Brand",
      name: "بازارک",
    },
  };

  out = replaceOrAddJsonLd(out, jsonLd);
  return out;
}

export async function onRequestGet(context) {
  const url = new URL(context.request.url);
  const id = String(context.params?.id || "").trim();

  // Always keep the listing route alive. SEO enhancement must never break the app.
  let shell;
  try {
    shell = await fetchShell(context.env);
  } catch (error) {
    return new Response("Bazarek shell unavailable", {
      status: 500,
      headers: { "content-type": "text/plain; charset=utf-8" },
    });
  }

  if (!id) {
    return new Response(shell, {
      status: 200,
      headers: { "content-type": "text/html; charset=utf-8" },
    });
  }

  try {
    const product = await getProduct(context.env, id);

    if (!product) {
      return new Response(shell, {
        status: 200,
        headers: {
          "content-type": "text/html; charset=utf-8",
          "x-bazarek-seo": "listing-shell",
        },
      });
    }

    const html = buildSeoHtml(shell, product, url);

    return new Response(html, {
      status: 200,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "cache-control": "public, max-age=60, s-maxage=300",
        "x-bazarek-seo": "listing-v4",
      },
    });
  } catch (_) {
    // Critical safety net: never turn a listing URL into a 500 because SEO failed.
    return new Response(shell, {
      status: 200,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "x-bazarek-seo": "listing-fallback",
      },
    });
  }
}
