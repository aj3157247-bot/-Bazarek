import { idFromSegment, storePath, applyIdFilter } from "../_listing_url.js";

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
  const re = /<title\b[^>]*>[\s\S]*?<\/title>/gi;
  // اگر (به هر دلیلی، از جمله باگ‌های احتمالی در HTML منبع) بیش از یک
  // <title> وجود داشته باشد، همه را با همین یک مقدار درست جایگزین می‌کنیم
  // تا crawlerها هیچ‌وقت تگ عنوان قدیمی/عمومی را به‌جای عنوان آگهی نبینند.
  return re.test(html)
    ? html.replace(re, tag)
    : html.replace(/<\/head>/i, `${tag}\n</head>`);
}

function replaceMeta(html, attr, key, value) {
  const safeKey = String(key).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const tag = `<meta ${attr}="${safeKey}" content="${escHtml(value)}">`;
  const re = new RegExp(
    `<meta\\b[^>]*\\b${attr}\\s*=\\s*["']${safeKey}["'][^>]*>`,
    "gi"
  );

  return re.test(html)
    ? html.replace(re, tag)
    : html.replace(/<\/head>/i, `${tag}\n</head>`);
}

function replaceCanonical(html, href) {
  const tag = `<link rel="canonical" href="${escHtml(href)}">`;
  const re = /<link\b[^>]*\brel\s*=\s*["']canonical["'][^>]*>/gi;
  return re.test(html)
    ? html.replace(re, tag)
    : html.replace(/<\/head>/i, `${tag}\n</head>`);
}

function addJsonLd(html, data) {
  const json = JSON.stringify(data).replace(/</g, "\\u003c");
  const tag = `<script type="application/ld+json" id="bazarek-store-jsonld">${json}</script>`;
  const re = /<script\b[^>]*id\s*=\s*["']bazarek-store-jsonld["'][^>]*>[\s\S]*?<\/script>/i;
  return re.test(html)
    ? html.replace(re, tag)
    : html.replace(/<\/head>/i, `${tag}\n</head>`);
}

async function getShell(context) {
  // 1) راه اصلی طبق مستندات رسمی Pages Functions: context.next() درخواست را
  //    به Function بعدی یا در صورت نبود، به asset server منتقل می‌کند.
  try {
    const nextResponse = await context.next();
    const contentType = nextResponse && nextResponse.headers.get("content-type");
    if (nextResponse && nextResponse.ok && contentType && contentType.includes("text/html")) {
      return await nextResponse.text();
    }
  } catch (_) {}

  // 2) Fallback: چون مسیر "/listing/<id>" خودش یک فایل استاتیک نیست و
  //    _redirects فعلاً غیرفعال است، در صورت نیاز مستقیماً "/index.html"
  //    (نه "/" و نه خودِ URL آگهی) را از ASSETS می‌گیریم.
  if (context && context.env && context.env.ASSETS) {
    try {
      const shellUrl = new URL("/index.html", context.request.url).toString();
      const response = await context.env.ASSETS.fetch(shellUrl);
      if (response && response.ok) {
        return await response.text();
      }
    } catch (_) {}
  }

  return null;
}


const TYPE_FA = {
  clothing: "لباس‌فروشی", shoes: "کفش‌فروشی", heating: "بخاری و لوازم زمستانی", mobile: "موبایل‌فروشی و لوازم جانبی",
  electronics: "الکترونیک و کمپیوتر", solar: "سولر و برق", home: "لوازم خانه و آشپزخانه", furniture: "مبلمان و دکوراسیون",
  carpet: "قالین‌فروشی", gold: "طلا و جواهر", supermarket: "سوپرمارکت و مواد غذایی", dry_fruit: "میوه خشک و عطاری",
  car_parts: "پرزه‌جات و لوازم موتر", car_dealer: "نمایشگاه موتر و موترسایکل", construction: "مصالح ساختمانی و ابزار",
  cosmetics: "آرایشی و بهداشتی", kids: "لوازم کودک و اسباب‌بازی", books: "کتاب و لوازم تحریر", wedding: "عروسی و مراسم",
  sports: "ورزش و تندرستی", pharmacy: "داروخانه و تجهیزات طبی", agriculture: "زراعت و مالداری", other: "فروشگاه",
};

async function rest(env, table, params) {
  const base = String(env.SUPABASE_URL || "").replace(/\/+$/, "");
  const key = String(env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_KEY || env.SUPABASE_ANON_KEY || "");
  if (!base || !key) return null;
  const url = new URL(`${base}/rest/v1/${table}`);
  for (const [k, v] of params) url.searchParams.append(k, v);
  const r = await fetch(url, { headers: { apikey: key, Authorization: `Bearer ${key}`, Accept: "application/json" } });
  if (!r.ok) return null;
  const rows = await r.json().catch(() => null);
  return Array.isArray(rows) ? rows : null;
}

async function getStore(env, id) {
  const url = new URL("https://x.invalid/");
  applyIdFilter(url, id);
  const params = [["select", "id,shop_name,full_name,city,bio,avatar_url,store_cover_url,store_category,updated_at,store_name,store_bio,store_logo_url,store_city"], ["limit", "1"]];
  for (const v of url.searchParams.getAll("id")) params.push(["id", v]);
  const rows = await rest(env, "profiles", params);
  const profile = rows && rows[0];
  if (!profile) return null;
  const nowIso = new Date().toISOString();
  const subs = await rest(env, "seller_subscriptions", [
    ["select", "user_id"], ["user_id", `eq.${profile.id}`], ["status", "eq.active"],
    ["plan", "in.(store_monthly,store_yearly)"], ["ends_at", `gt.${nowIso}`], ["limit", "1"],
  ]);
  if (!subs || !subs.length) return null; // فروشگاه غیرفعال ← صفحه‌ی عمومی SEO نمی‌گیرد
  return profile;
}

function buildSeo(shell, store, requestUrl) {
  const name = cleanText(store.store_name || store.shop_name || store.full_name || "فروشگاه", 80);
  const type = TYPE_FA[store.store_category] || "";
  const city = cleanText(store.store_city || store.city, 60);
  const title = `${name}${type ? " | " + type : ""} | بازارک`;
  const description = cleanText([type, city, store.store_bio || store.bio].filter(Boolean).join(" • ") || `فروشگاه ${name} در بازارک؛ محصولات اصلی با قیمت مناسب.`, 220);
  const image = String(store.store_cover_url || store.store_logo_url || store.avatar_url || "");
  const canonical = `${requestUrl.origin}${storePath(store)}`;

  let html = shell;
  html = replaceTitle(html, title);
  html = replaceMeta(html, "name", "description", description);
  html = replaceMeta(html, "property", "og:type", "website");
  html = replaceMeta(html, "property", "og:title", title);
  html = replaceMeta(html, "property", "og:description", description);
  html = replaceMeta(html, "property", "og:url", canonical);
  if (image) {
    html = replaceMeta(html, "property", "og:image", image);
    html = replaceMeta(html, "name", "twitter:image", image);
  }
  html = replaceMeta(html, "name", "twitter:card", image ? "summary_large_image" : "summary");
  html = replaceMeta(html, "name", "twitter:title", title);
  html = replaceMeta(html, "name", "twitter:description", description);
  html = replaceCanonical(html, canonical);
  html = addJsonLd(html, {
    "@context": "https://schema.org",
    "@type": "Store",
    name,
    description,
    url: canonical,
    ...(image ? { image } : {}),
    ...(city ? { address: { "@type": "PostalAddress", addressLocality: city, addressCountry: "AF" } } : {}),
  });
  return html;
}

export async function onRequestGet(context) {
  const id = idFromSegment(context.params?.id);
  let shell = null;
  try { shell = await getShell(context); } catch (_) { shell = null; }
  if (!shell) {
    return new Response('<!doctype html><html><head><meta charset="utf-8"></head><body></body></html>', {
      status: 200, headers: { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" },
    });
  }
  const plain = () => new Response(shell, { status: 200, headers: { "content-type": "text/html; charset=utf-8", "x-bazarek-seo": "store-shell" } });
  if (!id) return plain();
  try {
    const store = await getStore(context.env, id);
    if (!store) return plain();
    const reqUrl = new URL(context.request.url);
    const wanted = storePath(store);
    let current = reqUrl.pathname;
    try { current = decodeURIComponent(current); } catch (_) {}
    if (current.replace(/\/+$/, "") !== wanted) return Response.redirect(`${reqUrl.origin}${wanted}${reqUrl.search}`, 301);
    let html = shell;
    try { html = buildSeo(shell, store, reqUrl); } catch (_) {}
    return new Response(html, {
      status: 200,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "cache-control": "public, max-age=60, s-maxage=300",
        "x-bazarek-seo": html === shell ? "store-shell" : "store-v1",
      },
    });
  } catch (_) {
    return plain();
  }
}
