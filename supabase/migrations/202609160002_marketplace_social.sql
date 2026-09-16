-- Bazarek marketplace social layer: follows, likes, seller ratings and comments.
create table if not exists public.seller_follows (
  user_id uuid not null references auth.users(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, seller_id),
  check (user_id <> seller_id)
);
create index if not exists seller_follows_seller_idx on public.seller_follows(seller_id, created_at desc);
create index if not exists seller_follows_user_idx on public.seller_follows(user_id, created_at desc);

create table if not exists public.listing_likes (
  user_id uuid not null references auth.users(id) on delete cascade,
  listing_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);
create index if not exists listing_likes_listing_idx on public.listing_likes(listing_id, created_at desc);

create table if not exists public.seller_ratings (
  seller_id uuid not null references public.profiles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (seller_id, user_id),
  check (seller_id <> user_id)
);

create table if not exists public.seller_comments (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  comment text not null check (char_length(comment) between 1 and 500),
  created_at timestamptz not null default now(),
  check (seller_id <> user_id)
);
create index if not exists seller_comments_seller_idx on public.seller_comments(seller_id, created_at desc);

alter table public.seller_follows enable row level security;
alter table public.listing_likes enable row level security;
alter table public.seller_ratings enable row level security;
alter table public.seller_comments enable row level security;

drop policy if exists seller_follows_select on public.seller_follows;
create policy seller_follows_select on public.seller_follows for select using (true);
drop policy if exists seller_follows_self_write on public.seller_follows;
create policy seller_follows_self_write on public.seller_follows for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists listing_likes_select on public.listing_likes;
create policy listing_likes_select on public.listing_likes for select using (true);
drop policy if exists listing_likes_self_write on public.listing_likes;
create policy listing_likes_self_write on public.listing_likes for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists seller_ratings_select on public.seller_ratings;
create policy seller_ratings_select on public.seller_ratings for select using (true);
drop policy if exists seller_ratings_self_write on public.seller_ratings;
create policy seller_ratings_self_write on public.seller_ratings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists seller_comments_select on public.seller_comments;
create policy seller_comments_select on public.seller_comments for select using (true);
drop policy if exists seller_comments_self_write on public.seller_comments;
create policy seller_comments_self_write on public.seller_comments for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
