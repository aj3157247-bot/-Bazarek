import { idFromSegment, applyIdFilter } from '../../_listing_url.js';

function json(data, status = 200) {
  return Response.json(data, { status, headers: { 'Cache-Control': 'no-store', 'Access-Control-Allow-Origin': '*' } });
}

export async function onRequestGet({ params, env }) {
  const id = idFromSegment(params.id);
  if (!id) return json({ error: 'شناسه فروشگاه نامعتبر است.' }, 400);
  const base = String(env.SUPABASE_URL || '').replace(/\/$/, '');
  const key = String(env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_KEY || env.SUPABASE_ANON_KEY || '');
  if (!base || !key) return json({ error: 'تنظیمات پایگاه‌داده کامل نیست.' }, 500);
  const url = new URL(`${base}/rest/v1/profiles`);
  url.searchParams.set('select', 'id,shop_name,full_name,city,bio,avatar_url,store_cover_url,store_category,store_name,store_bio,store_logo_url,store_city,store_whatsapp,store_phone');
  applyIdFilter(url, id);
  url.searchParams.set('limit', '1');
  const r = await fetch(url, { headers: { apikey: key, Authorization: `Bearer ${key}`, Accept: 'application/json' } });
  const rows = await r.json().catch(() => []);
  if (!r.ok) return json({ error: 'خطا در دریافت فروشگاه.' }, 502);
  const store = Array.isArray(rows) ? rows[0] : null;
  if (!store) return json({ error: 'فروشگاه پیدا نشد.' }, 404);
  return json({ ...store, shop_name: store.store_name || store.shop_name || '', bio: store.store_bio || store.bio || '', avatar_url: store.store_logo_url || store.avatar_url || '', city: store.store_city || store.city || '' });
}
