function json(data, status = 200) {
  return Response.json(data, {
    status,
    headers: {
      "Cache-Control": "no-store",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Accept, Content-Type, Authorization",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    },
  });
}

export function onRequestOptions() {
  return new Response(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Accept, Content-Type, Authorization",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    },
  });
}

async function getUser(env, request) {
  const token = String(request.headers.get("Authorization") || "")
    .replace(/^Bearer\s+/i, "")
    .trim();
  const url = String(env.SUPABASE_URL || "").replace(/\/$/, "");
  const key = String(
    env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || env.SUPABASE_KEY || ""
  ).trim();

  if (!token || !url || !key) return null;

  const response = await fetch(`${url}/auth/v1/user`, {
    headers: {
      apikey: key,
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
    },
  });

  if (!response.ok) return null;
  const user = await response.json().catch(() => null);
  return user && user.id ? user : null;
}

function dbHeaders(serviceKey) {
  return {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    "Content-Type": "application/json",
    Accept: "application/json",
    Prefer: "return=representation",
  };
}

export async function onRequestPost({ request, env }) {
  try {
    const url = String(env.SUPABASE_URL || "").replace(/\/$/, "");
    const serviceKey = String(env.SUPABASE_SERVICE_ROLE_KEY || "").trim();

    if (!url || !serviceKey) {
      return json(
        { error: "تنظیمات پایگاه‌داده Cloudflare کامل نیست.", code: "SUPABASE_CONFIG_MISSING" },
        500
      );
    }

    const user = await getUser(env, request);
    if (!user) {
      return json({ error: "جلسه ورود شما معتبر نیست؛ لطفاً دوباره وارد حساب شوید." }, 401);
    }

    const body = await request.json().catch(() => null);
    if (!body || typeof body !== "object") {
      return json({ error: "اطلاعات خرید نامعتبر است." }, 400);
    }

    const plan = String(body.plan || "").trim().toLowerCase();
    const reference = String(body.payment_reference || "").trim();
    const plans = {
      store_monthly: { price: 600 },
      store_yearly: { price: 6000 },
    };

    if (!plans[plan]) return json({ error: "پلن نامعتبر است." }, 400);
    if (!reference) return json({ error: "لطفاً شماره پیگیری پرداخت را وارد کنید." }, 400);

    const base = `${url}/rest/v1/seller_subscriptions`;
    const headers = dbHeaders(serviceKey);

    const checkUrl = new URL(base);
    checkUrl.searchParams.set("select", "id");
    checkUrl.searchParams.set("user_id", `eq.${user.id}`);
    checkUrl.searchParams.set("plan", `eq.${plan}`);
    checkUrl.searchParams.set("status", "eq.pending");
    checkUrl.searchParams.set("limit", "1");

    const check = await fetch(checkUrl, { headers });
    const checkText = await check.text();
    let existing = [];
    try {
      existing = JSON.parse(checkText);
    } catch (_) {}

    if (!check.ok) {
      return json({ error: "خطا در بررسی درخواست قبلی فروشگاه." }, 502);
    }

    if (Array.isArray(existing) && existing.length) {
      return json({ error: "یک درخواست پرداخت برای این پلن در انتظار تأیید است." }, 409);
    }

    const insert = await fetch(base, {
      method: "POST",
      headers,
      body: JSON.stringify([
        {
          user_id: user.id,
          plan,
          price_afn: plans[plan].price,
          starts_at: null,
          ends_at: null,
          status: "pending",
          payment_method: "manual",
          payment_reference: reference.slice(0, 200),
        },
      ]),
    });

    const insertText = await insert.text();
    let result = null;
    try {
      result = JSON.parse(insertText);
    } catch (_) {}

    if (!insert.ok) return json({ error: "خطا در ثبت درخواست فروشگاه." }, 500);

    return json(Array.isArray(result) ? result[0] : result, 201);
  } catch (error) {
    console.error("store subscription purchase failed:", error);
    return json({ error: "خطا در ثبت درخواست فروشگاه." }, 500);
  }
}
