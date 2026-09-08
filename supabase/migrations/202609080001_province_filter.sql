alter table public.products add column if not exists province text;
create index if not exists products_province_idx on public.products(province);
