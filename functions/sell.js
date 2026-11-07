// صفحه‌ی عمومی «فروشنده شوید» برای جذب فروشنده از جستجوی گوگل و لینک‌های اشتراکی.
// فقط محتوای ثابت و واقعی بازارک را نشان می‌دهد؛ بدون وعده‌ی امکانات هنوز نساخته‌شده.
const PAGE_TITLE = "فروشنده شوید | ثبت آگهی رایگان در بازارک، بازار آنلاین افغانستان";
const PAGE_DESC = "در بازارک آگهی رایگان ثبت کنید و کالای خود را به خریداران کابل، هرات، مزارشریف و سراسر افغانستان بفروشید. ثبت‌نام آسان با فیسبوک یا شماره تلفن، با امتیاز هدیه و امکان ویژه کردن آگهی.";

const POINTS = [
  ["ثبت آگهی رایگان", "هر کالا را با عکس و قیمت ثبت کنید. ثبت آگهی هزینه‌ای ندارد."],
  ["امتیاز هدیه", "با اولین آگهی ۳۰ امتیاز و یک روز ویژه‌ی رایگان می‌گیرید."],
  ["دیده شدن در شبکه‌ها", "آگهی‌های تازه در کانال‌های تلگرام و صفحه‌های فیسبوک بازارک منتشر می‌شوند."],
  ["فروشگاه حرفه‌ای", "اگر فروشگاه دارید، صفحه‌ی اختصاصی با عکس، لوگو و لیست محصولات بسازید."],
  ["دعوت دوستان", "با دعوت دوستان امتیاز بیشتری جمع کنید."],
];
const STEPS = [
  ["ثبت‌نام", "با فیسبوک یا شماره تلفن در کمتر از یک دقیقه."],
  ["ثبت آگهی", "عکس‌ها، عنوان، قیمت و محل را وارد کنید."],
  ["دیده شدن", "آگهی شما در سایت، گوگل و شبکه‌های بازارک دیده می‌شود."],
  ["فروش", "خریدار از طریق تماس یا واتساپ با شما تماس می‌گیرد."],
];
const FAQ = [
  ["آیا ثبت آگهی در بازارک رایگان است؟", "بله. ثبت آگهی عادی رایگان است. امکانات اضافی مثل ویژه کردن آگهی با امتیاز انجام می‌شود که خودتان جمع می‌کنید."],
  ["چه کالاهایی را می‌توانم بفروشم؟", "موتر، موترسایکل، بایسکل، خانه و زمین، موبایل و لپ‌تاپ، لوازم خانه، لباس، طلا، مواد غذایی، لوازم بخاری و زمستانی و خدمات."],
  ["فروشگاه حرفه‌ای چه فرقی با آگهی عادی دارد؟", "فروشگاه صفحه‌ی اختصاصی با عکس کاور، لوگو، معرفی و لیست محصولات دارد. برای فعال‌سازی هویت شما یک بار بررسی می‌شود."],
  ["اگر خریدار پیدا شد، پول را چطور دریافت کنم؟", "بازارک بین خریدار و فروشنده تماس برقرار می‌کند؛ توافق قیمت و تحویل کالا بین شما و خریدار است."],
];

function escHtml(v) { return String(v ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;"); }

function page(origin) {
  const canonical = `${origin}/sell`;
  const ld = [
    { "@context": "https://schema.org", "@type": "WebPage", name: PAGE_TITLE, description: PAGE_DESC, url: canonical, inLanguage: "fa-AF" },
    { "@context": "https://schema.org", "@type": "FAQPage", mainEntity: FAQ.map(([q, a]) => ({ "@type": "Question", name: q, acceptedAnswer: { "@type": "Answer", text: a } })) },
  ];
  const cards = (arr) => arr.map(([t, d]) => `<div class="card"><h3>${escHtml(t)}</h3><p>${escHtml(d)}</p></div>`).join("");
  const steps = STEPS.map(([t, d], i) => `<li><span class="n">${i + 1}</span><div><strong>${escHtml(t)}</strong><p>${escHtml(d)}</p></div></li>`).join("");
  const faq = FAQ.map(([q, a]) => `<details><summary>${escHtml(q)}</summary><p>${escHtml(a)}</p></details>`).join("");
  return `<!doctype html>
<html lang="fa" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${escHtml(PAGE_TITLE)}</title>
<meta name="description" content="${escHtml(PAGE_DESC)}">
<link rel="canonical" href="${escHtml(canonical)}">
<meta property="og:type" content="website">
<meta property="og:title" content="${escHtml(PAGE_TITLE)}">
<meta property="og:description" content="${escHtml(PAGE_DESC)}">
<meta property="og:url" content="${escHtml(canonical)}">
<meta property="og:image" content="${escHtml(origin)}/icons/rewards-share.jpg">
<meta property="og:site_name" content="بازارک">
<meta property="og:locale" content="fa_AF">
<meta name="twitter:card" content="summary_large_image">
<script type="application/ld+json">${JSON.stringify(ld)}</script>
<style>
  body{margin:0;font-family:system-ui,Tahoma,sans-serif;background:#f4f6f8;color:#131921;line-height:1.9}
  header{background:linear-gradient(135deg,#0f6b78,#172b3a);color:#fff;padding:44px 20px;text-align:center}
  header h1{margin:0 0 10px;font-size:30px}
  header p{margin:0 auto 22px;max-width:680px;opacity:.95}
  .cta{display:inline-block;background:#ffd814;color:#111;font-weight:900;padding:14px 28px;border-radius:14px;text-decoration:none;margin:4px}
  .cta.alt{background:transparent;color:#fff;border:2px solid #fff}
  main{max-width:920px;margin:0 auto;padding:24px 16px 40px}
  h2{font-size:22px;margin:30px 0 12px}
  .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:12px}
  .card{background:#fff;border:1px solid #e3e6e8;border-radius:16px;padding:16px}
  .card h3{margin:0 0 6px;font-size:17px}
  .card p{margin:0;color:#4b5563;font-size:14px}
  ol.steps{list-style:none;padding:0;margin:0;display:grid;gap:12px}
  ol.steps li{display:flex;gap:12px;align-items:flex-start;background:#fff;border-radius:16px;padding:14px;border:1px solid #e3e6e8}
  .n{background:#0f6b78;color:#fff;width:34px;height:34px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-weight:900;flex:0 0 34px}
  ol.steps p{margin:0;color:#4b5563;font-size:14px}
  details{background:#fff;border:1px solid #e3e6e8;border-radius:14px;padding:12px 16px;margin-bottom:10px}
  summary{font-weight:800;cursor:pointer}
  details p{color:#4b5563;margin:8px 0 0}
  .final{background:#131921;color:#fff;border-radius:20px;padding:26px;text-align:center;margin-top:30px}
</style>
</head>
<body>
<header>
  <h1>فروشنده شوید؛ کالای خود را در بازارک بفروشید</h1>
  <p>بازارک بازار آنلاین خرید و فروش افغانستان است. آگهی‌تان را رایگان ثبت کنید تا خریداران کابل، هرات و سراسر کشور آن را ببینند.</p>
  <a class="cta" href="${escHtml(origin)}/">ثبت آگهی رایگان</a>
  <a class="cta alt" href="${escHtml(origin)}/rewards">باشگاه امتیاز</a>
</header>
<main>
  <h2>چرا بازارک؟</h2>
  <div class="grid">${cards(POINTS)}</div>
  <h2>چطور شروع کنیم؟</h2>
  <ol class="steps">${steps}</ol>
  <h2>سوال‌های پرتکرار</h2>
  ${faq}
  <div class="final">
    <h2 style="margin-top:0">همین حالا شروع کنید</h2>
    <p>ثبت‌نام کنید، اولین آگهی‌تان را بگذارید و امتیاز هدیه بگیرید.</p>
    <a class="cta" href="${escHtml(origin)}/">ثبت آگهی رایگان</a>
  </div>
</main>
</body>
</html>`;
}

export async function onRequestGet(context) {
  const origin = new URL(context.request.url).origin;
  return new Response(page(origin), {
    status: 200,
    headers: { "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=3600, s-maxage=86400" },
  });
}
