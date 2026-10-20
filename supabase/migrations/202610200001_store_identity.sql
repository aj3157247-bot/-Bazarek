-- هویت فروشگاه حرفه‌ای: نوع فروشگاه (بخاری‌فروشی، لباس‌فروشی، ...) و عکس روی فروشگاه (کاور).
alter table public.profiles add column if not exists store_category  text not null default '';
alter table public.profiles add column if not exists store_cover_url text not null default '';
create index if not exists profiles_store_category_idx on public.profiles (store_category) where store_category <> '';
