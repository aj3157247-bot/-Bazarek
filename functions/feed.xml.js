// فید RSS آگهی‌های تازه‌ی بازارک: با ابزارهای رایگان (مثل dlvr.it یا IFTTT) می‌توان آن را
// بدون هیچ برنامه‌نویسی و بدون توکن مت، خودکار به صفحه‌ی فیسبوک و اینستاگرام وصل کرد.
import { listingPath } from "./_listing_url.js";

function xml(v) {
  return String(v ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
function firstImage(value) {
  if (!value) return "";
  if (Array.isArray(value)) return String(value[0] || "");
  try {
    const p = JSON.parse(String(value));
    if (Array.isArray(p)) return String(p[0] || "");
    if (typeof p === "string") return p;
  } catch (_) {}
  const m = String(value).match(/https?:\/\/[^"'\\\s\],}]+/);
  return m ? m[0] : "";
}
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

export async function onRequestGet(context) {
  const origin = new URL(context.request.url).origin;
  const env = context.env;
  const cols = "id,title,category,subcategory,price,currency,province,image_url,created_at,is_store_product,vendor_id";
  const base = [["is_active", "eq.true"], ["order", "created_at.desc"], ["limit", "40"]];
  let rows = await rest(env, "products", [["select", cols + ",share_to_channels"], ...base]);
  if (!rows) rows = await rest(env, "products", [["select", cols], ...base]) || []; // اگر ستون share_to_channels هنوز ساخته نشده

  const nowIso = new Date().toISOString();
  const subs = await rest(env, "seller_subscriptions", [["select", "user_id"], ["status", "eq.active"], ["plan", "in.(store_monthly,store_yearly)"], ["ends_at", `gt.${nowIso}`], ["limit", "5000"]]) || [];
  const activeStores = new Set(subs.map((x) => x.user_id));

  const items = rows
    .filter((x) => x && x.id && x.share_to_channels !== false && (x.is_store_product !== true || activeStores.has(x.vendor_id)))
    .slice(0, 30)
    .map((x) => {
      const link = origin + listingPath(x);
      const img = firstImage(x.image_url);
      const price = Number(x.price) > 0 ? `${Number(x.price).toLocaleString("en-US")} ${String(x.currency).toUpperCase() === "USD" ? "دالر" : "افغانی"}` : "توافقی";
      const text = `${x.title}\n💰 ${price}${x.province ? `\n📍 ${x.province}` : ""}\n\n🔗 مشاهده و تماس: ${link}\n\n#بازارک`;
      const html = `${img ? `<p><img src="${xml(img)}" /></p>` : ""}<p>💰 ${xml(price)}${x.province ? ` — 📍 ${xml(x.province)}` : ""}</p><p><a href="${xml(link)}">مشاهده و تماس با فروشنده</a></p>`;
      return `    <item>
      <title>${xml(x.title)}</title>
      <link>${xml(link)}</link>
      <guid isPermaLink="true">${xml(link)}</guid>
      <pubDate>${new Date(x.created_at || Date.now()).toUTCString()}</pubDate>
      <description><![CDATA[${html.replace(/]]>/g, "")}]]></description>
      ${img ? `<enclosure url="${xml(img)}" type="image/jpeg" length="0" />\n      <media:content url="${xml(img)}" medium="image" />` : ""}
      <source url="${origin}/feed.xml">${xml(text.slice(0, 0))}بازارک</source>
    </item>`;
    });

  const body = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>بازارک | آگهی‌های تازه</title>
    <link>${origin}/</link>
    <description>تازه‌ترین آگهی‌های بازارک؛ بازار آنلاین خرید و فروش افغانستان</description>
    <language>fa</language>
    <atom:link href="${origin}/feed.xml" rel="self" type="application/rss+xml" />
${items.join("\n")}
  </channel>
</rss>`;
  return new Response(body, {
    status: 200,
    headers: { "content-type": "application/rss+xml; charset=utf-8", "cache-control": "public, max-age=300, s-maxage=300" },
  });
}
