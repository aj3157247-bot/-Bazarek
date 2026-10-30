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


const PAGE_TITLE = "باشگاه امتیاز بازارک | کریدت موبایل رایگان و ویژه کردن آگهی";
const PAGE_DESC = "در بازارک با دعوت دوستان، ثبت آگهی و ورود روزانه امتیاز جمع کنید؛ با امتیاز آگهی‌تان را ویژه کنید یا کریدت موبایل AWCC، روشان، اتصالات، سلام و آتوما دریافت کنید. ثبت‌نام رایگان است.";

const FAQ = [
  ["باشگاه امتیاز بازارک چیست؟", "باشگاه امتیاز بخشی از بازارک است که به کاربران برای فعالیت‌هایی مثل ثبت آگهی، دعوت دوستان و ورود روزانه امتیاز می‌دهد. این امتیازها را می‌توانید برای ویژه کردن آگهی یا دریافت کریدت موبایل خرج کنید."],
  ["چطور امتیاز بگیرم؟", "با ثبت آگهی (۱۰ امتیاز برای هر آگهی، تا ۳ آگهی در روز)، دعوت دوستان (۵۰ امتیاز برای هر دوستی که اولین آگهی‌اش را منتشر کند)، ورود روزانه (۳ امتیاز و پاداش ۷ روز پشت‌سرهم)، تکمیل پروفایل و فعال‌سازی فروشگاه."],
  ["کریدت موبایل برای کدام شبکه‌ها است؟", "کریدت برای شبکه‌های AWCC، روشان، اتصالات، سلام و آتوما قابل درخواست است. شماره و شبکه را خودتان وارد می‌کنید."],
  ["کریدت چطور ارسال می‌شود؟", "بعد از ثبت درخواست، مدیریت بازارک آن را بررسی و شماره را شارژ می‌کند. اگر درخواست انجام نشود، امتیازتان کامل برگردانده می‌شود."],
  ["آگهی را چطور با امتیاز ویژه کنم؟", "در صفحه‌ی باشگاه امتیاز یکی از بسته‌های ۳، ۷ یا ۳۰ روزه را انتخاب کنید و آگهی فعال خود را مشخص کنید. آگهی ویژه بالاتر دیده می‌شود."],
];

function buildRewardsSeo(shell, requestUrl) {
  const canonical = `${requestUrl.origin}/rewards`;
  const image = `${requestUrl.origin}/icons/rewards-share.jpg`;
  let html = shell;
  html = replaceTitle(html, PAGE_TITLE);
  html = replaceMeta(html, "name", "description", PAGE_DESC);
  html = replaceMeta(html, "property", "og:type", "website");
  html = replaceMeta(html, "property", "og:title", PAGE_TITLE);
  html = replaceMeta(html, "property", "og:description", PAGE_DESC);
  html = replaceMeta(html, "property", "og:url", canonical);
  html = replaceMeta(html, "property", "og:image", image);
  html = replaceMeta(html, "property", "og:image:secure_url", image);
  html = replaceMeta(html, "property", "og:image:type", "image/jpeg");
  html = replaceMeta(html, "property", "og:image:width", "1200");
  html = replaceMeta(html, "property", "og:image:height", "630");
  html = replaceMeta(html, "property", "og:image:alt", "باشگاه امتیاز بازارک؛ امتیاز بگیر و کریدت موبایل رایگان ببر");
  html = replaceMeta(html, "property", "og:site_name", "بازارک");
  html = replaceMeta(html, "property", "og:locale", "fa_AF");
  html = replaceMeta(html, "name", "twitter:card", "summary_large_image");
  html = replaceMeta(html, "name", "twitter:image", image);
  html = replaceMeta(html, "name", "robots", "index,follow,max-image-preview:large");
  html = replaceMeta(html, "name", "twitter:title", PAGE_TITLE);
  html = replaceMeta(html, "name", "twitter:description", PAGE_DESC);
  html = replaceCanonical(html, canonical);
  html = addJsonLd(html, {
    "@context": "https://schema.org",
    "@type": "WebPage",
    name: PAGE_TITLE,
    description: PAGE_DESC,
    url: canonical,
    inLanguage: "fa-AF",
    isPartOf: { "@type": "WebSite", name: "بازارک", url: requestUrl.origin + "/" },
  });
  html = addJsonLd(html, {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: FAQ.map(([q, a]) => ({ "@type": "Question", name: q, acceptedAnswer: { "@type": "Answer", text: a } })),
  });
  // متن قابل‌خواندن برای ربات‌ها و کاربرانی که جاوااسکریپت ندارند (همان محتوای صفحه، به‌صورت ساختارمند)
  const earn = [
    ["ثبت آگهی", "۱۰ امتیاز برای هر آگهی عادی (حداکثر ۳ آگهی در روز)"],
    ["دعوت دوستان", "۵۰ امتیاز برای هر دوست که اولین آگهی‌اش را منتشر کند؛ دوست شما هم ۲۰ امتیاز هدیه می‌گیرد"],
    ["ورود روزانه", "۳ امتیاز هر روز و ۲۰ امتیاز پاداش برای هر ۷ روز پشت‌سرهم"],
    ["تکمیل پروفایل", "۲۰ امتیاز (یک‌بار)"],
    ["فعال‌سازی فروشگاه", "۱۰۰ امتیاز بعد از تأیید فروشگاه"],
    ["هدیه‌ی خوش‌آمد", "۲۰ امتیاز در اولین ورود به باشگاه"],
  ];
  const spend = [
    ["کریدت ۵۰ افغانی", "۲٬۰۰۰ امتیاز"],
    ["کریدت ۱۰۰ افغانی", "۳٬۸۰۰ امتیاز"],
    ["کریدت ۲۰۰ افغانی", "۷٬۰۰۰ امتیاز"],
    ["ویژه کردن آگهی ۳ روزه", "۱۵۰ امتیاز"],
    ["ویژه کردن آگهی ۷ روزه", "۳۰۰ امتیاز"],
    ["ویژه کردن آگهی ۳۰ روزه", "۱٬۰۰۰ امتیاز"],
  ];
  const noscript = `<noscript><main dir="rtl" style="font-family:sans-serif;max-width:760px;margin:24px auto;padding:0 16px;line-height:1.9">` +
    `<h1>باشگاه امتیاز بازارک؛ امتیاز بگیر، کریدت موبایل رایگان ببر</h1><p>${escHtml(PAGE_DESC)}</p>` +
    `<h2>چطور امتیاز بگیریم؟</h2><ul>${earn.map(([a, b]) => `<li><strong>${escHtml(a)}:</strong> ${escHtml(b)}</li>`).join("")}</ul>` +
    `<h2>امتیاز را کجا خرج کنیم؟</h2><ul>${spend.map(([a, b]) => `<li><strong>${escHtml(a)}:</strong> ${escHtml(b)}</li>`).join("")}</ul>` +
    `<h2>شبکه‌های پشتیبانی‌شده برای کریدت موبایل</h2><p>AWCC، روشان (Roshan)، اتصالات (Etisalat)، سلام (Salaam) و آتوما (ATOMA).</p>` +
    FAQ.map(([q, a]) => `<h2>${escHtml(q)}</h2><p>${escHtml(a)}</p>`).join("") +
    `<p><a href="${escHtml(requestUrl.origin)}/">بازگشت به بازارک؛ بازار آنلاین خرید و فروش افغانستان</a></p></main></noscript>`;
  html = html.replace(/<body([^>]*)>/i, (m) => `${m}\n${noscript}`);
  return html;
}

export async function onRequestGet(context) {
  let shell = null;
  try { shell = await getShell(context); } catch (_) { shell = null; }
  if (!shell) {
    return new Response('<!doctype html><html><head><meta charset="utf-8"></head><body></body></html>', {
      status: 200, headers: { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" },
    });
  }
  let html = shell;
  try { html = buildRewardsSeo(shell, new URL(context.request.url)); } catch (_) {}
  return new Response(html, {
    status: 200,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "public, max-age=300, s-maxage=3600",
      "x-bazarek-seo": html === shell ? "rewards-shell" : "rewards-v1",
    },
  });
}
