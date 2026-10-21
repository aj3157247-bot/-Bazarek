// sitemap.xml پویا: آگهی‌ها، فروشگاه‌ها و محصولات فروشگاه‌ها خودکار وارد می‌شوند و
// <lastmod> هر URL از «تاریخ واقعی آخرین تغییر» همان رکورد در دیتابیس خوانده می‌شود (نه یک تاریخ ثابت).
import { listingPath, storePath } from "./_listing_url.js";

const STATIC_PATHS = [
  "/category/vehicles",
  "/category/vehicles/car",
  "/category/vehicles/motorcycle",
  "/category/vehicles/bicycles",
  "/category/vehicles/rickshaw",
  "/category/vehicles/trucks",
  "/category/vehicles/buses",
  "/category/vehicles/heavy_machinery",
  "/category/vehicles/parts",
  "/category/vehicles/tires_batteries",
  "/category/vehicles/car_accessories",
  "/category/real_estate",
  "/category/real_estate/house_rent",
  "/category/real_estate/house_mortgage",
  "/category/real_estate/house_sale",
  "/category/real_estate/apartment",
  "/category/real_estate/land_sale",
  "/category/real_estate/land_rent",
  "/category/real_estate/shop",
  "/category/real_estate/office",
  "/category/real_estate/garden",
  "/category/real_estate/warehouse",
  "/category/real_estate/room_rent",
  "/category/mobile_tablets",
  "/category/mobile_tablets/mobile",
  "/category/mobile_tablets/tablet",
  "/category/mobile_tablets/smartwatch",
  "/category/mobile_tablets/mobile_accessories",
  "/category/mobile_tablets/mobile_parts",
  "/category/electronics",
  "/category/electronics/laptop",
  "/category/electronics/computer",
  "/category/electronics/tv",
  "/category/electronics/camera",
  "/category/electronics/printer_network",
  "/category/electronics/gaming",
  "/category/electronics/audio",
  "/category/electronics/satellite",
  "/category/energy_solar",
  "/category/energy_solar/solar_panels",
  "/category/energy_solar/batteries_inverters",
  "/category/energy_solar/generators",
  "/category/energy_solar/solar_pumps",
  "/category/energy_solar/electric_supplies",
  "/category/heating_winter",
  "/category/heating_winter/turkish_stove",
  "/category/heating_winter/simple_stove",
  "/category/heating_winter/electric_heater",
  "/category/heating_winter/gas_oil_heater",
  "/category/heating_winter/chimney",
  "/category/heating_winter/fuel",
  "/category/heating_winter/winter_bedding",
  "/category/heating_winter/winter_clothes",
  "/category/home_goods",
  "/category/home_goods/furniture",
  "/category/home_goods/carpets",
  "/category/home_goods/appliances",
  "/category/home_goods/kitchen",
  "/category/home_goods/curtains_decor",
  "/category/fashion",
  "/category/fashion/mens",
  "/category/fashion/womens",
  "/category/fashion/kids",
  "/category/fashion/shoes",
  "/category/fashion/traditional",
  "/category/fashion/accessories",
  "/category/jewelry_gems",
  "/category/jewelry_gems/gold_silver",
  "/category/jewelry_gems/gemstones",
  "/category/jewelry_gems/jewelry",
  "/category/food_grocery",
  "/category/food_grocery/grocery",
  "/category/food_grocery/dry_fruits",
  "/category/food_grocery/fruit_vegetables",
  "/category/food_grocery/meat_dairy",
  "/category/food_grocery/honey_saffron",
  "/category/food_grocery/water_drinks",
  "/category/food_grocery/bakery",
  "/category/agriculture_livestock",
  "/category/agriculture_livestock/cattle",
  "/category/agriculture_livestock/sheep_goats",
  "/category/agriculture_livestock/horses",
  "/category/agriculture_livestock/poultry",
  "/category/agriculture_livestock/farm_equipment",
  "/category/agriculture_livestock/seeds_fertilizer",
  "/category/agriculture_livestock/irrigation",
  "/category/construction_tools",
  "/category/construction_tools/building_materials",
  "/category/construction_tools/tools",
  "/category/construction_tools/doors_windows",
  "/category/construction_tools/plumbing_electric",
  "/category/construction_tools/paint_tiles",
  "/category/services",
  "/category/services/repair",
  "/category/services/transport",
  "/category/services/home_services",
  "/category/services/visa_documents",
  "/category/services/design_digital",
  "/category/services/translation_typing",
  "/category/jobs",
  "/category/jobs/full_time",
  "/category/jobs/part_time",
  "/category/jobs/remote",
  "/category/jobs/daily_labor",
  "/category/jobs/job_seekers",
  "/category/education",
  "/category/education/courses",
  "/category/education/kankor",
  "/category/education/language",
  "/category/education/books",
  "/category/education/school_supplies",
  "/category/education/tutoring",
  "/category/health",
  "/category/health/pharmacy",
  "/category/health/medical_equipment",
  "/category/health/herbal",
  "/category/health/fitness_wellness",
  "/category/kids_family",
  "/category/kids_family/baby_gear",
  "/category/kids_family/toys",
  "/category/kids_family/strollers",
  "/category/kids_family/kids_furniture",
  "/category/wedding_events",
  "/category/wedding_events/wedding_dresses",
  "/category/wedding_events/wedding_services",
  "/category/wedding_events/halls",
  "/category/wedding_events/photography",
  "/category/wedding_events/wedding_decor",
  "/category/wedding_events/cake_sweets",
  "/category/animals_pets",
  "/category/animals_pets/pigeons",
  "/category/animals_pets/partridge",
  "/category/animals_pets/parrots",
  "/category/animals_pets/cats",
  "/category/animals_pets/dogs",
  "/category/animals_pets/pet_supplies",
  "/category/sports_hobbies",
  "/category/sports_hobbies/sports_equipment",
  "/category/sports_hobbies/music",
  "/category/sports_hobbies/camping",
  "/category/travel_tickets",
  "/category/travel_tickets/air_tickets",
  "/category/travel_tickets/bus_tickets",
  "/category/travel_tickets/hotels",
  "/category/travel_tickets/tours",
  "/category/afghan_stores",
  "/category/afghan_stores/clothing_stores",
  "/category/afghan_stores/shoe_stores",
  "/category/afghan_stores/gold_stores",
  "/category/afghan_stores/mobile_stores",
  "/category/afghan_stores/electronics_stores",
  "/category/afghan_stores/home_stores",
  "/category/afghan_stores/furniture_stores",
  "/category/afghan_stores/cosmetics_stores",
  "/category/afghan_stores/supermarkets",
  "/category/afghan_stores/car_parts_stores",
  "/category/afghan_stores/children_stores",
  "/category/afghan_stores/heating_stores",
  "/category/afghan_stores/solar_stores",
  "/category/afghan_stores/carpet_stores",
  "/category/afghan_stores/dry_fruit_stores",
  "/category/afghan_stores/other_stores",
];

const PAGE_SIZE = 1000;      // سقف پیش‌فرض ردیف‌های Supabase در هر درخواست
const MAX_PAGES = 40;        // ≤ ۴۰ هزار آگهی؛ سقف هر sitemap ۵۰ هزار URL و سقف subrequest کلادفلر ۵۰ است

function xml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
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
  const m = raw.match(/https?:\/\/[^"'\\\s\],}]+/);
  return m ? m[0] : "";
}

// تاریخ ISO کامل (W3C Datetime) یا رشته‌ی خالی اگر نامعتبر بود
function iso(value) {
  const d = new Date(value);
  return value && !isNaN(d.getTime()) ? d.toISOString() : "";
}
function maxIso(a, b) { return !a ? b : (!b ? a : (a > b ? a : b)); }

function authHeaders(env) {
  const key = String(env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_KEY || env.SUPABASE_ANON_KEY || "");
  return { apikey: key, Authorization: `Bearer ${key}`, Accept: "application/json" };
}

async function restGet(env, table, params) {
  const base = String(env.SUPABASE_URL || "").replace(/\/+$/, "");
  if (!base) return null;
  const url = new URL(`${base}/rest/v1/${table}`);
  for (const [k, v] of params) url.searchParams.append(k, v);
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 8000);
  try {
    const r = await fetch(url, { headers: authHeaders(env), signal: controller.signal });
    if (!r.ok) return null;
    const rows = await r.json();
    return Array.isArray(rows) ? rows : null;
  } catch (_) {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

// فروشگاه‌های فعال: فقط پروفایل‌هایی که اشتراک فروشگاه معتبر دارند
async function fetchStores(env) {
  const nowIso = new Date().toISOString();
  const subs = await restGet(env, "seller_subscriptions", [
    ["select", "user_id,ends_at,starts_at"],
    ["status", "eq.active"],
    ["plan", "in.(store_monthly,store_yearly)"],
    ["ends_at", `gt.${nowIso}`],
    ["limit", "5000"],
  ]);
  const ids = [...new Set((subs || []).filter((x) => !x.starts_at || x.starts_at <= nowIso).map((x) => x.user_id).filter(Boolean))];
  const stores = [];
  for (let i = 0; i < ids.length; i += 100) {
    const chunk = ids.slice(i, i + 100);
    const rows = await restGet(env, "profiles", [
      ["select", "id,shop_name,full_name,updated_at,avatar_url,store_cover_url,store_category,store_name,store_logo_url"],
      ["id", `in.(${chunk.join(",")})`],
    ]);
    if (rows) stores.push(...rows);
  }
  return stores;
}

async function fetchListings(env) {
  const all = [];
  for (let page = 0; page < MAX_PAGES; page++) {
    const rows = await restGet(env, "products", [
      ["select", "id,title,category,subcategory,image_url,created_at,updated_at,vendor_id,is_store_product"],
      ["is_active", "eq.true"],
      ["order", "created_at.desc,id.asc"],
      ["limit", String(PAGE_SIZE)],
      ["offset", String(page * PAGE_SIZE)],
    ]);
    if (!rows || rows.length === 0) break;
    all.push(...rows);
    if (rows.length < PAGE_SIZE) break;
  }
  return all;
}

export async function onRequestGet(context) {
  const origin = new URL(context.request.url).origin;
  const env = context.env;

  let listings = [];
  let stores = [];
  try { listings = await fetchListings(env); } catch (_) { listings = []; }
  try { stores = await fetchStores(env); } catch (_) { stores = []; }

  const activeStoreIds = new Set(stores.map((s) => s.id));
  // محصول فروشگاهی فقط وقتی دیده می‌شود که فروشگاهش فعال باشد (مثل خود سایت)
  listings = listings.filter((x) => x && x.id && (x.is_store_product !== true || activeStoreIds.has(x.vendor_id)));

  // lastmod واقعی هر رکورد
  const lastmodOf = (x) => maxIso(iso(x.updated_at), iso(x.created_at));
  const catMod = new Map();   // category -> lastmod
  const subMod = new Map();   // category/sub -> lastmod
  const storeMod = new Map(); // vendor_id -> lastmod آخرین محصول
  let siteMod = "";
  for (const x of listings) {
    const m = lastmodOf(x);
    siteMod = maxIso(siteMod, m);
    if (x.category) {
      catMod.set(x.category, maxIso(catMod.get(x.category) || "", m));
      if (x.subcategory) {
        const k = `${x.category}/${x.subcategory}`;
        subMod.set(k, maxIso(subMod.get(k) || "", m));
      }
    }
    if (x.is_store_product === true) storeMod.set(x.vendor_id, maxIso(storeMod.get(x.vendor_id) || "", m));
  }
  for (const s of stores) siteMod = maxIso(siteMod, iso(s.updated_at));

  const out = [];
  out.push('<?xml version="1.0" encoding="UTF-8"?>');
  out.push('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">');
  const homeMod = siteMod ? `<lastmod>${siteMod}</lastmod>` : "";
  out.push(`  <url><loc>${origin}/</loc>${homeMod}<changefreq>hourly</changefreq><priority>1.0</priority></url>`);

  // دسته‌ها و زیردسته‌ها: فقط وقتی حداقل یک آگهی فعال دارند وارد می‌شوند (صفحه‌ی خالی برای گوگل Soft 404 می‌شود).
  // تاریخ lastmod = تاریخ آخرین آگهی همان دسته. با ثبت اولین آگهی، دسته خودکار اضافه می‌شود.
  for (const path of STATIC_PATHS) {
    const parts = path.split("/").filter(Boolean); // ["category", cat, sub?]
    const key = parts.slice(1).join("/");
    const m = (parts.length === 2 ? catMod.get(key) : subMod.get(key)) || "";
    if (!m) continue;
    out.push(`  <url><loc>${xml(origin + path)}</loc><lastmod>${m}</lastmod><changefreq>daily</changefreq><priority>${parts.length === 2 ? "0.8" : "0.7"}</priority></url>`);
  }

  // فروشگاه‌ها
  for (const s of stores) {
    if (!s.id) continue;
    const m = maxIso(iso(s.updated_at), storeMod.get(s.id) || "");
    let entry = `  <url><loc>${xml(origin + storePath(s))}</loc>`;
    if (m) entry += `<lastmod>${m}</lastmod>`;
    entry += "<changefreq>daily</changefreq><priority>0.7</priority>";
    const cover = String(s.store_cover_url || s.store_logo_url || s.avatar_url || "");
    if (/^https?:\/\//i.test(cover)) entry += `<image:image><image:loc>${xml(cover)}</image:loc></image:image>`;
    out.push(entry + "</url>");
  }

  // آگهی‌ها و محصولات فروشگاه‌ها
  for (const item of listings) {
    const m = lastmodOf(item);
    const img = firstImage(item.image_url);
    let entry = `  <url><loc>${xml(origin + listingPath(item))}</loc>`;
    if (m) entry += `<lastmod>${m}</lastmod>`;
    entry += "<changefreq>weekly</changefreq><priority>0.6</priority>";
    if (img && /^https?:\/\//i.test(img)) entry += `<image:image><image:loc>${xml(img)}</image:loc></image:image>`;
    out.push(entry + "</url>");
  }

  out.push("</urlset>");

  return new Response(out.join("\n"), {
    status: 200,
    headers: {
      "content-type": "application/xml; charset=utf-8",
      "cache-control": "public, max-age=300, s-maxage=900",
      "x-bazarek-sitemap": "dynamic-v4",
    },
  });
}
