-- Bazarek professional-store customer experience:
-- product reviews/ratings with seller replies + saved professional stores.

create table if not exists public.product_reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  review text not null check (char_length(review) between 1 and 1200),
  seller_reply text,
  seller_replied_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(product_id, user_id)
);
create index if not exists product_reviews_product_idx on public.product_reviews(product_id, created_at desc);
create index if not exists product_reviews_user_idx on public.product_reviews(user_id, created_at desc);

create table if not exists public.saved_stores (
  user_id uuid not null references auth.users(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, seller_id),
  check (user_id <> seller_id)
);
create index if not exists saved_stores_seller_idx on public.saved_stores(seller_id, created_at desc);
create index if not exists saved_stores_user_idx on public.saved_stores(user_id, created_at desc);

alter table public.product_reviews enable row level security;
alter table public.saved_stores enable row level security;

drop policy if exists product_reviews_select on public.product_reviews;
create policy product_reviews_select on public.product_reviews for select using (true);
drop policy if exists product_reviews_self_write on public.product_reviews;
create policy product_reviews_self_write on public.product_reviews for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists saved_stores_select on public.saved_stores;
create policy saved_stores_select on public.saved_stores for select using (true);
drop policy if exists saved_stores_self_write on public.saved_stores;
create policy saved_stores_self_write on public.saved_stores for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
