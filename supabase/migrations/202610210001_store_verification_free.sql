-- فعال‌سازی رایگان فروشگاه با تأیید هویت (عکس تذکره + سلفی) توسط مدیریت.
create table if not exists public.store_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  id_card_path text not null default '',
  selfie_path  text not null default '',
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  admin_note text not null default '',
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);
create index if not exists store_verifications_status_idx on public.store_verifications (status, created_at desc);
create unique index if not exists store_verifications_one_pending on public.store_verifications (user_id) where status = 'pending';
alter table public.store_verifications enable row level security;  -- فقط بک‌اند (service role)

-- مخزن «خصوصی» برای مدارک؛ هیچ آدرس عمومی ندارد و فقط با لینک موقت مدیریت دیده می‌شود.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('store-kyc', 'store-kyc', false, 10485760, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = false;

-- اشتراک رایگان فروشگاه قیمت صفر دارد؛ اگر محدودیت قدیمی (price_afn > 0) وجود داشت آن را نرم می‌کنیم.
alter table public.seller_subscriptions drop constraint if exists seller_subscriptions_price_afn_check;
alter table public.seller_subscriptions add constraint seller_subscriptions_price_afn_check check (price_afn >= 0);
