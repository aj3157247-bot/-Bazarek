function esc(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function text(value) {
  if (value == null) return "";
  if (Array.isArray(value)) return value.join(", ");
  if (typeof value === "object") return JSON.stringify(value);
  return String(value);
}

function parseImages(value) {
  if (!value) return [];
  if (Array.isArray(value)) return value.map(text).filter(Boolean);
  if (typeof value === "object") {
    return Object.values(value).map(text).filter(Boolean);
  }
  const raw = String(value).trim();
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed)) return parsed.map(text).filter(Boolean);
  } catch (_) {}
  return raw.split(/\s*,\s*/).filter(Boolean);
}

function pick(obj, names) {
  for (const name of names) {
    const value = obj?.[name];
    if (value !== null && value !== undefined && String(value).trim() !== "") {
      return value;
    }
  }
  return "";
}

function digitsToLatin(value) {
  return String(value ?? "")
    .replace(/[۰-۹]/g, d => String("۰۱۲۳۴۵۶۷۸۹".indexOf(d)))
    .replace(/[٠-٩]/g, d => String("٠١٢٣٤٥٦٧٨٩".indexOf(d)));
}

function formatPrice(value, currency) {
  if (value === "" || value == null) return "";
  const numeric = Number(digitsToLatin(String(value)).replace(/[^\d.-]/g, ""));
  if (!Number.isFinite(numeric)) return text(value);
  return `${new Intl.NumberFormat("fa-AF").format(numeric)} ${currency || "AFN"}`;
}

function normalizeDescription(value) {
  return text(value).replace(/\s+/g, " ").trim();
}

async function getProduct(id, env) {
  const supabaseUrl = String(env.SUPABASE_URL || "").replace(/\/+$/, "");
  const serviceKey = String(env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_KEY || env.SUPABASE_ANON_KEY || "");

  if (!supabaseUrl || !serviceKey) return null;

  const endpoint = `${supabaseUrl}/rest/v1/products?id=eq.${encodeURIComponent(id)}&select=*`;
  const response = await fetch(endpoint, {
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
      Accept: "application/json"
    }
  });

  if (!response.ok) return null;
  const data = await response.json();
  if (!Array.isArray(data) || !data.length) return null;
  return data[0];
}

function setMeta(doc, attr, key, content) {
  if (!content) return;
  const selector = `meta[${attr}="${key}"]`;
  const found = doc.match(new RegExp(`<meta\\s+[^>]*${attr}=["']${key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}["'][^>]*>`, "i"));
  const tag = `<meta ${attr}="${key}" content="${esc(content)}">`;
  if (found) {
    doc = doc.replace(found[0], tag);
  } else {
    doc = doc.replace(/<head[^>]*>/i, m => `${m}\n${tag}`);
  }
  return doc;
}

function injectSeo(html, product, url) {
  const title = text(pick(product, ["title", "name", "product_name"])) || "آگهی در بازارک";
  const description =
    normalizeDescription(pick(product, ["description", "details", "body"])) ||
    `${title} در بازارک؛ بازار آنلاین خرید و فروش افغانستان.`;

  const price = pick(product, ["price", "amount"]);
  const currency = text(pick(product, ["currency", "price_currency"])) || "AFN";
  const location =
    text(pick(product, ["location_text", "location", "city", "province", "address"])) || "افغانستان";
  const province = text(pick(product, ["province"]));
  const category = text(pick(product, ["category"]));
  const subcategory = text(pick(product, ["subcategory"]));

  const images = parseImages(pick(product, [
    "image_url", "image_urls", "images", "photos", "photo_urls",
    "thumbnail", "cover_image", "cover_image_url"
  ]));
  const image = images[0] || "";

  const canonical = url.toString().split("?")[0];
  const seoDescription = description.slice(0, 300);

  html = html.replace(/<title>[\s\S]*?<\/title>/i, `<title>${esc(title)} | بازارک</title>`);
  if (!/<title[\s>]/i.test(html)) {
    html = html.replace(/<head[^>]*>/i, m => `${m}\n<title>${esc(title)} | بازارک</title>`);
  }

  html = setMeta(html, "name", "description", seoDescription);
  html = setMeta(html, "name", "robots", "index,follow,max-image-preview:large");
  html = setMeta(html, "property", "og:title", `${title} | بازارک`);
  html = setMeta(html, "property", "og:description", seoDescription);
  html = setMeta(html, "property", "og:url", canonical);
  html = setMeta(html, "property", "og:type", "product");
  html = setMeta(html, "property", "og:locale", "fa_AF");
  html = setMeta(html, "name", "twitter:card", image ? "summary_large_image" : "summary");
  html = setMeta(html, "name", "twitter:title", `${title} | بازارک`);
  html = setMeta(html, "name", "twitter:description", seoDescription);

  if (image) {
    html = setMeta(html, "property", "og:image", image);
    html = setMeta(html, "property", "og:image:alt", title);
    html = setMeta(html, "name", "twitter:image", image);
  }

  if (price !== "" && price != null) {
    html = setMeta(html, "property", "product:price:amount", String(price));
    html = setMeta(html, "property", "product:price:currency", currency);
  }

  const oldCanonical = /<link\s+[^>]*rel=["']canonical["'][^>]*>/i;
  const canonicalTag = `<link rel="canonical" href="${esc(canonical)}">`;
  if (oldCanonical.test(html)) html = html.replace(oldCanonical, canonicalTag);
  else html = html.replace(/<head[^>]*>/i, m => `${m}\n${canonicalTag}`);

  const structured = {
    "@context": "https://schema.org",
    "@type": "Product",
    "name": title,
    "description": seoDescription,
    "url": canonical,
    "image": images,
    "category": [category, subcategory].filter(Boolean).join(" > ") || undefined,
    "offers": price !== "" && price != null ? {
      "@type": "Offer",
      "price": String(price),
      "priceCurrency": currency,
      "availability": product.is_active === false
        ? "https://schema.org/OutOfStock"
        : "https://schema.org/InStock",
      "url": canonical,
      "itemCondition": "https://schema.org/UsedCondition"
    } : undefined,
    "areaServed": location,
    "address": province ? {
      "@type": "PostalAddress",
      "addressRegion": province,
      "addressCountry": "AF"
    } : undefined
  };

  const json = JSON.stringify(structured).replace(/</g, "\\u003c");
  html = html.replace(
    /<script[^>]+id=["']bazarek-listing-jsonld["'][^>]*>[\s\S]*?<\/script>/i,
    ""
  );
  html = html.replace(/<\/head>/i,
    `<script id="bazarek-listing-jsonld" type="application/ld+json">${json}</script>\n</head>`
  );

  return html;
}

export async function onRequestGet(context) {
  const id = String(context.params?.id || "").trim();

  try {
    const product = await getProduct(id, context.env);
    const asset = await context.env.ASSETS.fetch("/");
    const contentType = asset.headers.get("content-type") || "text/html; charset=UTF-8";

    if (!product) {
      const response = new Response(asset.body, asset);
      response.headers.set("content-type", contentType);
      response.headers.set("x-bazarek-seo", "listing-not-found");
      return response;
    }

    const html = await asset.text();
    const url = new URL(context.request.url);
    const seoHtml = injectSeo(html, product, url);

    return new Response(seoHtml, {
      status: asset.status,
      headers: {
        "content-type": contentType,
        "cache-control": "public, max-age=60, s-maxage=300",
        "x-bazarek-seo": "listing"
      }
    });
  } catch (_) {
    const asset = await context.env.ASSETS.fetch("/");
    const response = new Response(asset.body, asset);
    response.headers.set("x-bazarek-seo", "listing-error-fallback");
    return response;
  }
}
