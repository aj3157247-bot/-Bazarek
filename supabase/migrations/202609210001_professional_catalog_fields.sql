-- Bazarek professional store catalog fields
-- Optional seller-entered metadata used by the professional storefront/catalog.

alter table public.products add column if not exists brand text not null default '';
alter table public.products add column if not exists model text not null default '';
alter table public.products add column if not exists sizes text not null default '';
alter table public.products add column if not exists colors text not null default '';
alter table public.products add column if not exists material text not null default '';
alter table public.products add column if not exists condition text not null default '';
alter table public.products add column if not exists product_code text not null default '';
alter table public.products add column if not exists specifications text not null default '';

create index if not exists products_product_code_idx on public.products(product_code);
