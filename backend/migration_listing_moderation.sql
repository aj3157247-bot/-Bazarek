-- بازارک: کنترل وضعیت آگهی توسط کاربر و مدیریت
-- این SQL را فقط یک‌بار در Supabase SQL Editor اجرا کنید.

alter table public.products
  add column if not exists is_active boolean not null default true;

alter table public.products
  add column if not exists moderation_disabled boolean not null default false;

alter table public.products
  add column if not exists moderation_reason text;

create index if not exists idx_products_vendor_active
  on public.products(vendor_id, is_active);

create index if not exists idx_products_moderation_disabled
  on public.products(moderation_disabled)
  where moderation_disabled = true;
