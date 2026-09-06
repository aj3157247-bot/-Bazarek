-- Bazaarak product management upgrade
alter table public.profiles add column if not exists business_type text not null default '';
alter table public.products add column if not exists cost_price numeric(14,2) not null default 0 check (cost_price >= 0);
alter table public.products add column if not exists category text not null default '';
alter table public.products add column if not exists is_active boolean not null default true;

create index if not exists products_vendor_created_idx on public.products(vendor_id, created_at desc);
create index if not exists products_vendor_category_idx on public.products(vendor_id, category);

create or replace function public.set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles for each row execute procedure public.set_updated_at();
drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at before update on public.products for each row execute procedure public.set_updated_at();
