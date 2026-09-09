alter table if exists public.products add column if not exists subcategory text default '';
create index if not exists products_subcategory_idx on public.products (subcategory);
