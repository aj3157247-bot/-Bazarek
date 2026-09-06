-- Bazarek marketplace moderation + monetization controls
alter table public.profiles
  add column if not exists is_blocked boolean not null default false,
  add column if not exists blocked_until timestamptz,
  add column if not exists block_reason text;

alter table public.products
  add column if not exists is_featured boolean not null default false,
  add column if not exists is_pinned boolean not null default false,
  add column if not exists featured_until timestamptz,
  add column if not exists pinned_until timestamptz;

create index if not exists idx_products_featured on public.products(is_featured, featured_until);
create index if not exists idx_products_pinned on public.products(is_pinned, pinned_until);
create index if not exists idx_profiles_blocked on public.profiles(is_blocked, blocked_until);

-- Keep expired paid/administrative promotions from remaining active forever.
create or replace function public.clear_expired_bazarek_promotions()
returns void
language sql
security definer
set search_path = public
as $$
  update public.products
  set is_featured = false
  where is_featured = true and featured_until is not null and featured_until <= now();

  update public.products
  set is_pinned = false
  where is_pinned = true and pinned_until is not null and pinned_until <= now();
$$;
