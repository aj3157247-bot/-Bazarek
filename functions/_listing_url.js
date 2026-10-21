// منطق مشترک ساخت/خواندن لینک کوتاه آگهی.
// باید دقیقاً با توابع _listingSlug / _listingPath در lib/main.dart یکی باشد.
// فرمت: /listing/<کلمات-انگلیسی-عنوان یا دسته>-<۱۲ کاراکتر اول شناسه>

const FA = "۰۱۲۳۴۵۶۷۸۹";
const AR = "٠١٢٣٤٥٦٧٨٩";

export const UUID_RE = /([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$/;
export const SHORT_RE = /([0-9a-f]{12})$/;

export function shortId(id) {
  return String(id || "").replace(/-/g, "").toLowerCase().slice(0, 12);
}

function asciiDigits(value) {
  let v = String(value || "").toLowerCase();
  for (let i = 0; i < 10; i++) {
    v = v.split(FA[i]).join(String(i)).split(AR[i]).join(String(i));
  }
  return v;
}

function categoryPart(value) {
  const t = String(value || "").toLowerCase().trim();
  return /^[a-z0-9_]+$/.test(t) ? t.replace(/_/g, "-") : "";
}

export function listingSlug(product) {
  let tokens = asciiDigits(product && product.title).match(/[a-z0-9]+/g) || [];
  if (!tokens.some((t) => /[a-z]/.test(t))) tokens = [];
  tokens = tokens.slice(0, 4);
  let slug = tokens.join("-");
  if (!slug) {
    slug = [categoryPart(product && product.category), categoryPart(product && product.subcategory)]
      .filter(Boolean)
      .join("-");
  }
  if (slug.length > 40) slug = slug.slice(0, 40).replace(/-+$/, "");
  return slug;
}

export function listingPath(product) {
  const short = shortId(product && product.id);
  const slug = listingSlug(product);
  return `/listing/${slug ? slug + "-" : ""}${short}`;
}

// از بخش آخر مسیر، UUID کامل یا شناسه کوتاه را برمی‌گرداند.
export function idFromSegment(raw) {
  let seg = String(raw || "");
  try { seg = decodeURIComponent(seg); } catch (_) {}
  seg = seg.toLowerCase();
  const full = seg.match(UUID_RE);
  if (full) return full[1];
  const short = seg.match(SHORT_RE);
  if (short) return short[1];
  return seg;
}

// فیلتر PostgREST برای id: eq برای UUID کامل، بازه برای شناسه کوتاه (۱۲ hex).
export function applyIdFilter(url, id) {
  if (/^[0-9a-f]{12}$/.test(id)) {
    const head = `${id.slice(0, 8)}-${id.slice(8, 12)}`;
    url.searchParams.append("id", `gte.${head}-0000-0000-0000-000000000000`);
    url.searchParams.append("id", `lte.${head}-ffff-ffff-ffff-ffffffffffff`);
  } else {
    url.searchParams.append("id", `eq.${id}`);
  }
}

// پشتیبان: اگر فیلتر بازه‌ای روی ستون id جواب نداد (مثلاً نوع ستون uuid نبود)،
// آگهی‌های فعال اخیر را می‌خوانیم و شناسه کامل را از روی پیشوند پیدا می‌کنیم.
export async function resolveFullId(supabaseUrl, key, short) {
  if (!/^[0-9a-f]{12}$/.test(short)) return null;
  const base = String(supabaseUrl || "").replace(/\/+$/, "");
  const head = `${short.slice(0, 8)}-${short.slice(8, 12)}`;
  for (let page = 0; page < 5; page++) {
    const url = new URL(`${base}/rest/v1/products`);
    url.searchParams.set("select", "id");
    url.searchParams.set("is_active", "eq.true");
    url.searchParams.set("order", "created_at.desc,id.asc");
    url.searchParams.set("limit", "1000");
    url.searchParams.set("offset", String(page * 1000));
    try {
      const r = await fetch(url, {
        headers: { apikey: String(key), Authorization: `Bearer ${String(key)}`, Accept: "application/json" },
      });
      if (!r.ok) return null;
      const rows = await r.json();
      if (!Array.isArray(rows) || rows.length === 0) return null;
      const hit = rows.find((x) => String(x.id || "").toLowerCase().startsWith(head));
      if (hit) return String(hit.id);
      if (rows.length < 1000) return null;
    } catch (_) {
      return null;
    }
  }
  return null;
}

// ───────── لینک فروشگاه: /store/<کلمات-انگلیسی نام فروشگاه یا store>-<۱۲ کاراکتر اول شناسه> ─────────
const STORE_TYPE_SLUG = {
  clothing: "clothing-store", shoes: "shoe-store", heating: "heating-store", mobile: "mobile-store",
  electronics: "electronics-store", solar: "solar-store", home: "home-goods-store", furniture: "furniture-store",
  carpet: "carpet-store", gold: "jewelry-store", supermarket: "supermarket", dry_fruit: "dry-fruit-store",
  car_parts: "car-parts-store", car_dealer: "car-dealer", construction: "building-materials-store",
  cosmetics: "cosmetics-store", kids: "kids-store", books: "bookstore", wedding: "wedding-store",
  sports: "sports-store", pharmacy: "pharmacy", agriculture: "agriculture-store", other: "store",
};

// اولویت slug: ۱) کلمات انگلیسی نام فروشگاه  ۲) نوع فروشگاه (مثلاً heating-store)  ۳) store
export function storeSlug(profile) {
  const name = asciiDigits(profile && (profile.shop_name || profile.full_name));
  let tokens = name.match(/[a-z0-9]+/g) || [];
  if (!tokens.some((t) => /[a-z]/.test(t))) tokens = [];
  let slug = tokens.slice(0, 4).join("-");
  if (!slug) slug = STORE_TYPE_SLUG[profile && profile.store_category] || "store";
  if (slug.length > 40) slug = slug.slice(0, 40).replace(/-+$/, "");
  return slug;
}

export function storePath(profile) {
  return `/store/${storeSlug(profile)}-${shortId(profile && profile.id)}`;
}
