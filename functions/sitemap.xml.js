// sitemap.xml پویا: هر آگهی فعال بلافاصله بعد از ثبت (حداکثر تا ~۱۵ دقیقه، مدت کش) خودکار در sitemap قرار می‌گیرد.
// آگهی‌های غیرفعال/حذف‌شده هم خودکار از آن خارج می‌شوند. نیازی به ویرایش دستی نیست.
import { listingPath } from "./_listing_url.js";

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
const MAX_PAGES = 45;        // ≤ ۴۵ هزار آگهی؛ سقف هر sitemap ۵۰ هزار URL و سقف subrequest کلادفلر ۵۰ است

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

function day(value) {
  const d = new Date(value);
  return isNaN(d.getTime()) ? "" : d.toISOString().slice(0, 10);
}

async function fetchListings(env) {
  const base = String(env.SUPABASE_URL || "").replace(/\/+$/, "");
  const key = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_KEY || env.SUPABASE_ANON_KEY;
  if (!base || !key) return [];

  const all = [];
  for (let page = 0; page < MAX_PAGES; page++) {
    const url = new URL(`${base}/rest/v1/products`);
    url.searchParams.set("select", "id,title,category,subcategory,image_url,created_at");
    url.searchParams.set("is_active", "eq.true");
    url.searchParams.set("order", "created_at.desc,id.asc");
    url.searchParams.set("limit", String(PAGE_SIZE));
    url.searchParams.set("offset", String(page * PAGE_SIZE));

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 8000);
    let rows;
    try {
      const r = await fetch(url, {
        headers: { apikey: String(key), Authorization: `Bearer ${String(key)}`, Accept: "application/json" },
        signal: controller.signal,
      });
      if (!r.ok) break;
      rows = await r.json();
    } catch (_) {
      break;
    } finally {
      clearTimeout(timer);
    }
    if (!Array.isArray(rows) || rows.length === 0) break;
    all.push(...rows);
    if (rows.length < PAGE_SIZE) break;
  }
  return all;
}

export async function onRequestGet(context) {
  const origin = new URL(context.request.url).origin;
  const today = new Date().toISOString().slice(0, 10);

  let listings = [];
  try {
    listings = await fetchListings(context.env);
  } catch (_) {
    listings = [];
  }

  const out = [];
  out.push('<?xml version="1.0" encoding="UTF-8"?>');
  out.push('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">');
  out.push(`  <url><loc>${origin}/</loc><lastmod>${today}</lastmod><changefreq>hourly</changefreq><priority>1.0</priority></url>`);

  for (const path of STATIC_PATHS) {
    const depth = path.split("/").filter(Boolean).length;
    out.push(`  <url><loc>${xml(origin + path)}</loc><lastmod>${today}</lastmod><changefreq>daily</changefreq><priority>${depth === 2 ? "0.8" : "0.7"}</priority></url>`);
  }

  for (const item of listings) {
    if (!item || !item.id) continue;
    const loc = origin + listingPath(item);
    const lastmod = day(item.created_at);
    const img = firstImage(item.image_url);
    let entry = `  <url><loc>${xml(loc)}</loc>`;
    if (lastmod) entry += `<lastmod>${lastmod}</lastmod>`;
    entry += "<changefreq>weekly</changefreq><priority>0.6</priority>";
    if (img && /^https?:\/\//i.test(img)) {
      entry += `<image:image><image:loc>${xml(img)}</image:loc></image:image>`;
    }
    entry += "</url>";
    out.push(entry);
  }

  out.push("</urlset>");

  return new Response(out.join("\n"), {
    status: 200,
    headers: {
      "content-type": "application/xml; charset=utf-8",
      "cache-control": "public, max-age=300, s-maxage=900",
    },
  });
}
