-- Bazarek listing engagement and contact enhancements
alter table public.products
  add column if not exists contact_phone text not null default '',
  add column if not exists location_text text not null default '',
  add column if not exists is_negotiable boolean not null default false,
  add column if not exists views_count bigint not null default 0;

create table if not exists public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  listing_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);
create index if not exists favorites_user_idx on public.favorites(user_id, created_at desc);
create index if not exists favorites_listing_idx on public.favorites(listing_id);
alter table public.favorites enable row level security;
drop policy if exists favorites_self on public.favorites;
create policy favorites_self on public.favorites for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create or replace function public.bazarek_increment_listing_view(p_listing_id uuid)
returns bigint language sql security definer set search_path=public as $$
  update public.products set views_count = views_count + 1, updated_at = now() where id = p_listing_id and is_active = true returning views_count;
$$;
