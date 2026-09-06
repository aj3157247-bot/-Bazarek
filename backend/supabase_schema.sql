-- Bazarek / Supabase schema
-- Run this once in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.vendors (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  shop_name text not null default '',
  phone text,
  city text,
  plan text not null default 'free' check (plan in ('free', 'pro', 'business')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid not null references public.vendors(id) on delete cascade,
  title text not null,
  description text not null default '',
  price numeric(14,2) not null default 0 check (price >= 0),
  stock integer not null default 0 check (stock >= 0),
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid not null references public.vendors(id) on delete cascade,
  name text not null,
  phone text,
  address text,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid not null references public.vendors(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  total_amount numeric(14,2) not null default 0 check (total_amount >= 0),
  status text not null default 'pending' check (status in ('pending','confirmed','delivered','cancelled')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  quantity integer not null default 1 check (quantity > 0),
  unit_price numeric(14,2) not null default 0 check (unit_price >= 0)
);

create table if not exists public.ai_usage (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid not null references public.vendors(id) on delete cascade,
  action text not null,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.vendors (id, full_name, shop_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'shop_name', '')
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    shop_name = excluded.shop_name,
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.vendors enable row level security;
alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.ai_usage enable row level security;

drop policy if exists vendors_select_own on public.vendors;
create policy vendors_select_own on public.vendors for select using (id = auth.uid());
drop policy if exists vendors_update_own on public.vendors;
create policy vendors_update_own on public.vendors for update using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists products_own_all on public.products;
create policy products_own_all on public.products for all using (vendor_id = auth.uid()) with check (vendor_id = auth.uid());

drop policy if exists customers_own_all on public.customers;
create policy customers_own_all on public.customers for all using (vendor_id = auth.uid()) with check (vendor_id = auth.uid());

drop policy if exists orders_own_all on public.orders;
create policy orders_own_all on public.orders for all using (vendor_id = auth.uid()) with check (vendor_id = auth.uid());

drop policy if exists order_items_own_all on public.order_items;
create policy order_items_own_all on public.order_items
for all using (
  exists (select 1 from public.orders o where o.id = order_id and o.vendor_id = auth.uid())
) with check (
  exists (select 1 from public.orders o where o.id = order_id and o.vendor_id = auth.uid())
);

drop policy if exists ai_usage_own_all on public.ai_usage;
create policy ai_usage_own_all on public.ai_usage for all using (vendor_id = auth.uid()) with check (vendor_id = auth.uid());

create index if not exists products_vendor_id_idx on public.products(vendor_id);
create index if not exists customers_vendor_id_idx on public.customers(vendor_id);
create index if not exists orders_vendor_id_idx on public.orders(vendor_id);
create index if not exists order_items_order_id_idx on public.order_items(order_id);
