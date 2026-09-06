create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  shop_name text,
  city text,
  plan text not null default 'free' check (plan in ('free','pro','business')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text not null default '',
  price numeric(14,2) not null default 0 check (price >= 0),
  stock integer not null default 0 check (stock >= 0),
  image_url text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists products_vendor_id_idx on public.products(vendor_id);

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name) values (new.id, coalesce(new.raw_user_meta_data->>'full_name','')) on conflict (id) do update set full_name=excluded.full_name;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.products enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "products_select_own" on public.products;
create policy "products_select_own" on public.products for select using (auth.uid() = vendor_id);
drop policy if exists "products_insert_own" on public.products;
create policy "products_insert_own" on public.products for insert with check (auth.uid() = vendor_id);
drop policy if exists "products_update_own" on public.products;
create policy "products_update_own" on public.products for update using (auth.uid() = vendor_id) with check (auth.uid() = vendor_id);
drop policy if exists "products_delete_own" on public.products;
create policy "products_delete_own" on public.products for delete using (auth.uid() = vendor_id);
