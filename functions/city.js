// صفحه‌های SEO شهر + دسته، مثل /city/kabul/vehicles، با آگهی‌های واقعی همان شهر و دسته.
// اگر هیچ آگهی‌ای نباشد، صفحه noindex می‌شود تا گوگل صفحه‌ی خالی را ایندکس نکند.
import { listingPath } from "./_listing_url.js";

const CITIES = {
  kabul: ["کابل", "Kabul"], herat: ["هرات", "Herat"], mazar: ["بلخ (مزارشریف)", "Mazar-e-Sharif"],
  kandahar: ["قندهار", "Kandahar"], jalalabad: ["ننگرهار (جلال‌آباد)", "Jalalabad"], kunduz: ["کندز", "Kunduz"],
};
const CATS = {
  vehicles: "وسایط نقلیه", real_estate: "املاک و خانه", mobile_tablets: "موبایل و تبلت",
  electronics: "لوازم الکترونیکی و کمپیوتر", heating_winter: "گرمایش و زمستان", home_goods: "لوازم خانه",
  fashion: "لباس و پوشاک", jewelry_gems: "طلا و جواهر", food_grocery: "مواد غذایی", services: "خدمات", jobs: "استخدام و کاریابی",
};

function esc(v) { return String(v ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;"); }
function fmtPrice(p, c) { const n = Number(p); return n > 0 ? `${n.toLocaleString("en-US")} ${String(c).toUpperCase() === "USD" ? "دالر" : "افغانی"}` : "توافقی"; }

async function fetchListings(env, cityFa, cat) {
  const base = String(env.SUPABASE_URL || "").replace(/\/+$/, "");
  const key = String(env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_KEY || env.SUPABASE_ANON_KEY || "");
  if (!base || !key) return [];
  const url = new URL(`${base}/rest/v1/products`);
  url.searchParams.set("select", "id,title,price,currency,province,category,image_url,created_at");
  url.searchParams.set("is_active", "eq.true");
  url.searchParams.set("province", `eq.${cityFa}`);
  url.searchParams.set("category", `eq.${cat}`);
  url.searchParams.set("order", "created_at.desc");
  url.searchParams.set("limit", "60");
  const r = await fetch(url, { headers: { apikey: key, Authorization: `Bearer ${key}` } });
  if (!r.ok) return [];
  const rows = await r.json().catch(() => []);
  return Array.isArray(rows) ? rows.filter((x) => x && x.id && x.is_store_product !== true) : [];
}
function firstImage(v) { try { const a = Array.isArray(v) ? v : JSON.parse(v || "[]"); return String(a[0] || ""); } catch (_) { return ""; } }

export async function onRequestGet(context) {
  const u = new URL(context.request.url);
  const parts = u.pathname.split("/").filter(Boolean); // ["city", citySlug, catSlug]
  const city = CITIES[parts[1]];
  const catName = CATS[parts[2]];
  if (!city || !catName) return new Response("Not found", { status: 404 });
  const [cityFa, cityEn] = city;
  const origin = u.origin;
  const listings = await fetchListings(context.env, cityFa, parts[2]);
  const title = `خرید و فروش ${catName} در ${cityFa} | بازارک`;
  const desc = `${listings.length} آگهی ${catName} در ${cityFa} در بازارک. آگهی‌های تازه با عکس، قیمت و تماس مستقیم با فروشنده.`;
  const canonical = `${origin}/city/${parts[1]}/${parts[2]}`;
  const items = listings.slice(0, 60).map((x) => {
    const img = firstImage(x.image_url);
    return `<a class="item" href="${esc(origin + listingPath(x))}">${img ? `<img src="${esc(img)}" alt="${esc(x.title)}" loading="lazy">` : ""}<strong>${esc(x.title)}</strong><span>${esc(fmtPrice(x.price, x.currency))}</span></a>`;
  }).join("");
  const ld = { "@context": "https://schema.org", "@type": "CollectionPage", name: title, description: desc, url: canonical, inLanguage: "fa-AF",
    about: { "@type": "Thing", name: catName }, areaServed: { "@type": "City", name: cityEn } };
  const html = `<!doctype html><html lang="fa" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(title)}</title><meta name="description" content="${esc(desc)}">
<link rel="canonical" href="${esc(canonical)}">
${listings.length ? "" : '<meta name="robots" content="noindex,follow">'}
<meta property="og:type" content="website"><meta property="og:title" content="${esc(title)}"><meta property="og:description" content="${esc(desc)}"><meta property="og:url" content="${esc(canonical)}"><meta property="og:site_name" content="بازارک"><meta property="og:locale" content="fa_AF">
<script type="application/ld+json">${JSON.stringify(ld)}</script>
<style>body{margin:0;font-family:system-ui,Tahoma,sans-serif;background:#f4f6f8;color:#131921}header{background:#131921;color:#fff;padding:22px 16px}header h1{margin:0;font-size:22px}header a{color:#ffd814;font-weight:800;text-decoration:none}main{max-width:1000px;margin:0 auto;padding:16px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px}.item{background:#fff;border-radius:14px;overflow:hidden;text-decoration:none;color:#131921;border:1px solid #e3e6e8;display:flex;flex-direction:column}.item img{width:100%;aspect-ratio:1/1;object-fit:contain;background:#f5f6f7}.item strong{padding:8px 10px 2px;font-size:14px}.item span{padding:0 10px 10px;color:#0f6b78;font-weight:900}p.empty{color:#4b5563}</style></head>
<body><header><h1>${esc(catName)} در ${esc(cityFa)}</h1><a href="${esc(origin)}/">بازگشت به بازارک</a></header>
<main><p>${esc(desc)}</p>${listings.length ? `<div class="grid">${items}</div>` : `<p class="empty">فعلاً آگهی‌ای در این بخش نیست. <a href="${esc(origin)}/">همه‌ی آگهی‌ها</a></p>`}</main></body></html>`;
  return new Response(html, { status: 200, headers: { "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=600, s-maxage=900" } });
}
