function escHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function cleanText(value, max = 180) {
  return String(value ?? "").replace(/\s+/g, " ").trim().slice(0, max);
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

  const match = raw.match(/https?:\/\/[^"'\\\s\],}]+/);
  return match ? match[0] : raw;
}

function replaceTitle(html, value) {
  const tag = `<title>${escHtml(value)}</title>`;
  const re = /<title\b[^>]*>[\s\S]*?<\/title>/i;
  return re.test(html)
    ? html.replace(re, tag)
    : html.replace(/<\/head>/i, `${tag}\n</head>`);
}

function replaceMeta(html, attr, key, value) {
  const safeKey = String(key).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const tag = `<meta ${attr}="${safeKey}" content="${escHtml(value)}">`;
  const re = new RegExp(
    `<meta\\b[^>]*\\b${attr}\\s*=\\s*["']${safeKey}["'][^>]*>`,
    "i"
  );

  return re.test(html)
    ? html.replace(re, tag)
    : html.replace(/<\/head>/i, `${tag}\n</head>`);
}

function replaceCanonical(html, href) {
  const tag = `<link rel="canonical" href="${escHtml(href)}">`;
  const re = /<link\b[^>]*\brel\s*=\s*["']canonical["'][^>]*>/i;
  return re.test(html)
    ? html.replace(re, tag)
    : html.replace(/<\/head>/i, `${tag}\n</head>`);
}

function addJsonLd(html, data) {
  const json = JSON.stringify(data).replace(/</g, "\\u003c");
  const tag = `<script type="application/ld+json" id="bazarek-listing-jsonld">${json}</script>`;
  const re = /<script\b[^>]*id\s*=\s*["']bazarek-listing-jsonld["'][^>]*>[\s\S]*?<\/script>/i;
  return re.test(html)
    ? html.replace(re, tag)
    : html.replace(/<\/head>/i, `${tag}\n</head>`);
}

async function getShell(context) {
  // Pages Functions route to static assets through the ASSETS binding.
  // Try the requested route first, then the root asset as a fallback.
  const candidates = [context.request.url, new URL("/", context.request.url).toString()];

  for (const candidate of candidates) {
    try {
      const response = await context.env.ASSETS.fetch(candidate);
      if (response && response.ok) {
        return await response.text();
      }
    } catch (_) {}
  }

  return null;
}

async function getProduct(env, id) {
  const supabaseUrl = String(env.SUPABASE_URL || "").replace(/\/+$/, "");
  const key =
    env.SUPABASE_SERVICE_ROLE_KEY ||
    env.SUPABASE_KEY ||
    env.SUPABASE_ANON_KEY;

  if (!supabaseUrl || !key) return null;

  const endpoint =
    `${supabaseUrl}/rest/v1/products?select=*` +
    `&id=eq.${encodeURIComponent(id)}&is_active=eq.true&limit=1`;

  const response = await fetch(endpoint, {
    headers: {
      apikey: String(key),
      Authorization: `Bearer ${String(key)}`,
    },
  });

  if (!response.ok) return null;

  const rows = await response.json();
  return Array.isArray(rows) && rows.length ? rows[0] : null;
}

function buildSeo(shell, product, requestUrl) {
  const title = cleanText(product.title, 120) || "آگهی در بازارک";
  const description =
    cleanText(product.description, 180) ||
    `آگهی ${title} در بازار آنلاین افغانستان، بازارک.`;
  const canonical = requestUrl.toString().split("?")[0].split("#")[0];
  const image = firstImage(product.image_url);
  const location =
    cleanText(product.location_text, 120) ||
    cleanText(product.location, 120) ||
    cleanText(product.province, 80);

  let html = shell;
  html = replaceTitle(html, `${title} | بازارک`);
  html = replaceMeta(html, "name", "description", description);
  html = replaceMeta(html, "name", "robots", "index,follow,max-image-preview:large");
  html = replaceMeta(html, "property", "og:title", title);
  html = replaceMeta(html, "property", "og:description", description);
  html = replaceMeta(html, "property", "og:url", canonical);
  html = replaceMeta(html, "property", "og:type", "product");
  html = replaceMeta(html, "property", "og:locale", "fa_AF");
  html = replaceMeta(html, "name", "twitter:card", image ? "summary_large_image" : "summary");
  html = replaceMeta(html, "name", "twitter:title", title);
  html = replaceMeta(html, "name", "twitter:description", description);

  if (image) {
    html = replaceMeta(html, "property", "og:image", image);
    html = replaceMeta(html, "property", "og:image:alt", title);
    html = replaceMeta(html, "name", "twitter:image", image);
  }

  html = replaceCanonical(html, canonical);

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: title,
    description,
    url: canonical,
    ...(image ? { image: [image] } : {}),
    ...(location ? { areaServed: location } : {}),
    ...(product.price !== null && product.price !== undefined
      ? {
          offers: {
            "@type": "Offer",
            price: String(product.price),
            priceCurrency: product.currency || "AFN",
            availability: "https://schema.org/InStock",
            url: canonical
          }
        }
      : {})
  };

  return addJsonLd(html, jsonLd);
}

export async function onRequestGet(context) {
  const id = String(context.params?.id || "").trim();

  // Most important rule: never make a listing URL fail just because SEO fails.
  const shell = await getShell(context);

  if (!shell) {
    return new Response(
      "Bazarek: static app asset could not be loaded.",
      {
        status: 503,
        headers: {
          "content-type": "text/plain; charset=utf-8",
          "cache-control": "no-store"
        }
      }
    );
  }

  if (!id) {
    return new Response(shell, {
      status: 200,
      headers: { "content-type": "text/html; charset=utf-8" }
    });
  }

  try {
    const product = await getProduct(context.env, id);

    if (!product) {
      return new Response(shell, {
        status: 200,
        headers: {
          "content-type": "text/html; charset=utf-8",
          "x-bazarek-seo": "listing-shell"
        }
      });
    }

    let html = shell;
    try {
      html = buildSeo(shell, product, new URL(context.request.url));
    } catch (_) {
      // Keep the normal Flutter page if metadata generation fails.
    }

    return new Response(html, {
      status: 200,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "cache-control": "public, max-age=60, s-maxage=300",
        "x-bazarek-seo": html === shell ? "listing-shell" : "listing-v5"
      }
    });
  } catch (_) {
    return new Response(shell, {
      status: 200,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "x-bazarek-seo": "listing-fallback"
      }
    });
  }
}
