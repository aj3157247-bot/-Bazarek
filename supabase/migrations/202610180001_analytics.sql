-- آمار داخلی بازارک (بدون سرویس خارجی): رویدادهای بازدید و تعامل کاربران.
-- این فایل را یک بار در Supabase SQL Editor اجرا کنید.
create table if not exists public.analytics_events (
  id bigserial primary key,
  created_at timestamptz not null default now(),
  event text not null,                 -- page_view | listing_view | chat_click | call_click | share_click | search
  path text not null default '',
  listing_id text not null default '',
  category text not null default '',
  query text not null default '',
  referrer text not null default '',   -- فقط نام دامنه‌ی منبع، مثلاً google.com
  device text not null default '',     -- mobile | desktop
  visitor_id text not null default '', -- شناسه‌ی تصادفی مرورگر؛ بدون اطلاعات شخصی
  lang text not null default ''
);
create index if not exists analytics_events_created_idx on public.analytics_events (created_at desc);
create index if not exists analytics_events_event_idx on public.analytics_events (event, created_at desc);
create index if not exists analytics_events_listing_idx on public.analytics_events (listing_id) where listing_id <> '';
alter table public.analytics_events enable row level security;  -- فقط بک‌اند (service role) دسترسی دارد

create or replace function public.admin_analytics(p_days int default 7)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  d int := least(greatest(coalesce(p_days, 7), 1), 365);
  now_local timestamp := (now() at time zone 'Asia/Kabul');
  since_local timestamp := date_trunc('day', (now() at time zone 'Asia/Kabul')) - ((d - 1) || ' days')::interval;
  prev_since_local timestamp := since_local - (d || ' days')::interval;
  result jsonb;
begin
  with ev as (
    select *, (created_at at time zone 'Asia/Kabul') as lt
    from analytics_events
    where (created_at at time zone 'Asia/Kabul') >= prev_since_local
  ),
  cur as (select * from ev where lt >= since_local),
  prev as (select * from ev where lt < since_local),
  days as (select generate_series(date_trunc('day', since_local), date_trunc('day', now_local), interval '1 day') as day)
  select jsonb_build_object(
    'days', d,
    'totals', jsonb_build_object(
      'page_views',    (select count(*) from cur where event = 'page_view'),
      'visitors',      (select count(distinct visitor_id) from cur where visitor_id <> ''),
      'listing_views', (select count(*) from cur where event = 'listing_view'),
      'chat_clicks',   (select count(*) from cur where event = 'chat_click'),
      'call_clicks',   (select count(*) from cur where event = 'call_click'),
      'share_clicks',  (select count(*) from cur where event = 'share_click'),
      'searches',      (select count(*) from cur where event = 'search')
    ),
    'previous', jsonb_build_object(
      'page_views', (select count(*) from prev where event = 'page_view'),
      'visitors',   (select count(distinct visitor_id) from prev where visitor_id <> ''),
      'listing_views', (select count(*) from prev where event = 'listing_view')
    ),
    'today', jsonb_build_object(
      'page_views', (select count(*) from cur where event = 'page_view' and lt >= date_trunc('day', now_local)),
      'visitors',   (select count(distinct visitor_id) from cur where visitor_id <> '' and lt >= date_trunc('day', now_local))
    ),
    'online_now', (select count(distinct visitor_id) from analytics_events where created_at >= now() - interval '5 minutes' and visitor_id <> ''),
    'daily', coalesce((
      select jsonb_agg(jsonb_build_object(
        'day', to_char(days.day, 'YYYY-MM-DD'),
        'views', (select count(*) from cur c where c.event = 'page_view' and date_trunc('day', c.lt) = days.day),
        'visitors', (select count(distinct c.visitor_id) from cur c where c.visitor_id <> '' and date_trunc('day', c.lt) = days.day),
        'listing_views', (select count(*) from cur c where c.event = 'listing_view' and date_trunc('day', c.lt) = days.day)
      ) order by days.day)
      from days), '[]'::jsonb),
    'hours', coalesce((
      select jsonb_agg(jsonb_build_object('hour', h, 'views', coalesce(x.n, 0)) order by h)
      from generate_series(0, 23) h
      left join (select extract(hour from lt)::int as hr, count(*) as n from cur where event = 'page_view' group by 1) x on x.hr = h
    ), '[]'::jsonb),
    'top_listings', coalesce((
      select jsonb_agg(t) from (
        select c.listing_id as id,
               coalesce(max(p.title), 'آگهی حذف‌شده') as title,
               count(*) filter (where c.event = 'listing_view') as views,
               count(distinct c.visitor_id) filter (where c.event = 'listing_view') as visitors,
               count(*) filter (where c.event = 'chat_click') as chats,
               count(*) filter (where c.event = 'call_click') as calls,
               count(*) filter (where c.event = 'share_click') as shares
        from cur c left join products p on p.id::text = c.listing_id
        where c.listing_id <> ''
        group by c.listing_id
        order by views desc, chats desc
        limit 10
      ) t), '[]'::jsonb),
    'top_categories', coalesce((
      select jsonb_agg(t) from (
        select category, count(*) as views from cur
        where category <> '' and event in ('listing_view', 'page_view')
        group by category order by views desc limit 8
      ) t), '[]'::jsonb),
    'sources', coalesce((
      select jsonb_agg(t) from (
        select case when referrer = '' then 'direct' else referrer end as source,
               count(distinct visitor_id) as visitors, count(*) as views
        from cur where event = 'page_view'
        group by 1 order by visitors desc limit 8
      ) t), '[]'::jsonb),
    'devices', coalesce((
      select jsonb_agg(t) from (
        select case when device = '' then 'unknown' else device end as device, count(distinct visitor_id) as visitors
        from cur where event = 'page_view' group by 1 order by visitors desc
      ) t), '[]'::jsonb),
    'top_searches', coalesce((
      select jsonb_agg(t) from (
        select lower(query) as query, count(*) as count from cur
        where event = 'search' and query <> ''
        group by 1 order by count desc limit 10
      ) t), '[]'::jsonb)
  ) into result;
  return result;
end;
$$;
revoke all on function public.admin_analytics(int) from public, anon, authenticated;
