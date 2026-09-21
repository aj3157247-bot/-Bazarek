function esc(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function cleanText(value) {
  if (value == null) return "";
  if (Array.isArray(value)) return value.join(", ");
  if (typeof value === "object") return JSON.stringify(value);
  return String(value);
}

function pick(obj, names) {
  for (const name of names) {
    if (obj && Object.prototype.hasOwnProperty.call(obj, name)) {
      const value = obj[name];
      if (value !== null && value !== undefined && String(value).trim() !== "") {
        return value;
      }
    }
  }
  return "";
}

async function getProduct(id, env) {
  const supabaseUrl = String(env.SUPABASE_URL || "").replace(/\/+$/, "");
  const serviceKey = String(
    env.SUPABASE_SERVICE_ROLE_KEY ||
    env.SUPABASE_KEY ||
    env.SUPABASE_ANON_KEY ||
    ""
  );

  if (!supabaseUrl || !serviceKey) {
    return {
      ok: false,
      stage: "env",
      error: "SUPABASE_URL or SUPABASE key is missing",
      env: {
        SUPABASE_URL: !!supabaseUrl,
        SUPABASE_SERVICE_ROLE_KEY: !!env.SUPABASE_SERVICE_ROLE_KEY,
        SUPABASE_KEY: !!env.SUPABASE_KEY,
        SUPABASE_ANON_KEY: !!env.SUPABASE_ANON_KEY
      }
    };
  }

  const endpoint =
    `${supabaseUrl}/rest/v1/products?id=eq.${encodeURIComponent(id)}&select=*`;

  try {
    const response = await fetch(endpoint, {
      headers: {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
        Accept: "application/json"
      }
    });

    const raw = await response.text();

    let data = null;
    try {
      data = JSON.parse(raw);
    } catch (_) {}

    if (!response.ok) {
      return {
        ok: false,
        stage: "supabase",
        httpStatus: response.status,
        error: raw.slice(0, 1200),
        endpoint: endpoint.replace(/(apikey=|Bearer )[^&\s]+/gi, "$1[redacted]")
      };
    }

    if (!Array.isArray(data)) {
      return {
        ok: false,
        stage: "supabase-json",
        httpStatus: response.status,
        error: "Supabase returned a non-array response",
        preview: raw.slice(0, 1200)
      };
    }

    if (!data.length) {
      return {
        ok: false,
        stage: "not-found",
        httpStatus: response.status,
        error: "No product row matched this ID",
        count: 0
      };
    }

    const product = data[0];

    return {
      ok: true,
      stage: "success",
      httpStatus: response.status,
      count: data.length,
      keys: Object.keys(product),
      sample: {
        id: pick(product, ["id"]),
        title: pick(product, ["title", "name", "product_name"]),
        description: pick(product, ["description", "details", "body"]),
        price: pick(product, ["price", "amount"]),
        currency: pick(product, ["currency", "price_currency"]),
        category: pick(product, ["category", "category_name"]),
        subcategory: pick(product, ["subcategory", "subcategory_name"]),
        location: pick(product, ["location_text", "location", "city", "province", "address"]),
        image: pick(product, [
          "image_url", "thumbnail", "cover_image", "cover_image_url",
          "photo", "image", "images", "image_urls", "photos", "photo_urls"
        ])
      }
    };
  } catch (error) {
    return {
      ok: false,
      stage: "fetch",
      error: String(error?.message || error)
    };
  }
}

export async function onRequestGet(context) {
  const id = String(context.params?.id || "").trim();
  const url = new URL(context.request.url);

  // Diagnostic is enabled only with ?debug=1.
  // Normal visitors still receive the Flutter app shell.
  if (url.searchParams.get("debug") !== "1") {
    return context.env.ASSETS.fetch("/");
  }

  const result = await getProduct(id, context.env);

  const safe = {
    route: "/listing/[id].js",
    requestedId: id,
    diagnostic: result
  };

  return new Response(JSON.stringify(safe, null, 2), {
    status: result.ok ? 200 : 500,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "x-bazarek-seo-diagnostic": "1"
    }
  });
}
