// Cloudflare Worker: هر ۱۰ دقیقه سرور Render را بیدار نگه می‌دارد تا اولین ورود کاربران کند نباشد.
// ساخت: Cloudflare Dashboard ← Workers & Pages ← Create ← Worker ← این کد را جایگزین کنید ← Deploy
// بعد: Settings ← Triggers ← Cron Triggers ← Add ← */10 * * * *
export default {
  async scheduled(event, env, ctx) {
    ctx.waitUntil(
      fetch("https://bazarek.onrender.com/api/version", { headers: { "User-Agent": "bazarek-keepalive" } })
        .then((r) => console.log("keepalive", r.status))
        .catch((e) => console.log("keepalive failed", String(e)))
    );
  },
  async fetch() {
    return new Response("bazarek keepalive ok");
  },
};
