-- ۱) دکمه‌ی واتساپ برای آگهی و محصول
alter table public.products add column if not exists show_whatsapp   boolean not null default false;
alter table public.products add column if not exists whatsapp_number text    not null default '';

-- ۲) پروفایل فروشگاه جدا از پروفایل شخصی
alter table public.profiles add column if not exists store_name      text not null default '';
alter table public.profiles add column if not exists store_bio       text not null default '';
alter table public.profiles add column if not exists store_logo_url  text not null default '';
alter table public.profiles add column if not exists store_phone     text not null default '';
alter table public.profiles add column if not exists store_whatsapp  text not null default '';
alter table public.profiles add column if not exists store_city      text not null default '';
alter table public.profiles add column if not exists store_address   text not null default '';
