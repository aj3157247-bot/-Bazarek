-- Bazarek monetization: wallet, paid promotions, subscriptions and banner campaigns
create table if not exists public.wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  balance_afn bigint not null default 0 check (balance_afn >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('credit','debit','refund','welcome','payment')),
  amount_afn bigint not null check (amount_afn > 0),
  description text not null,
  reference_id text,
  created_at timestamptz not null default now()
);
create index if not exists wallet_tx_user_idx on public.wallet_transactions(user_id, created_at desc);

create table if not exists public.promotion_packages (
  id text primary key,
  title text not null,
  description text not null default '',
  price_afn bigint not null check (price_afn > 0),
  feature_days integer not null default 0,
  pin_days integer not null default 0,
  boost_level integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.promotion_packages(id,title,description,price_afn,feature_days,pin_days,boost_level)
values
('featured7','ویژه ۷ روزه','نمایش برجسته در نتایج',100,7,0,0),
('featured30','ویژه ۳۰ روزه','نمایش برجسته برای یک ماه',300,30,0,0),
('pin7','پین ۷ روزه','نمایش بالاتر از آگهی‌های عادی',150,0,7,0),
('pin30','پین ۳۰ روزه','پین یک‌ماهه',400,0,30,0),
('boost7','بوست ۷ روزه','ویژه + پین + اولویت بیشتر',250,7,7,1),
('boost30','بوست ۳۰ روزه','ویژه + پین + اولویت بیشتر',600,30,30,2)
on conflict (id) do update set title=excluded.title,description=excluded.description,price_afn=excluded.price_afn,feature_days=excluded.feature_days,pin_days=excluded.pin_days,boost_level=excluded.boost_level;

create table if not exists public.promotion_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  listing_id uuid not null references public.products(id) on delete cascade,
  package_id text not null references public.promotion_packages(id),
  amount_afn bigint not null check (amount_afn > 0),
  payment_method text not null default 'wallet' check (payment_method in ('wallet','manual','gateway')),
  payment_reference text,
  status text not null default 'pending' check (status in ('pending','paid','rejected','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists promotion_orders_user_idx on public.promotion_orders(user_id,created_at desc);
create index if not exists promotion_orders_status_idx on public.promotion_orders(status,created_at desc);

create table if not exists public.seller_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan text not null check (plan in ('basic','pro','business')),
  price_afn bigint not null check (price_afn > 0),
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  status text not null default 'active' check (status in ('pending','active','expired','cancelled')),
  created_at timestamptz not null default now()
);
create index if not exists seller_subscriptions_user_idx on public.seller_subscriptions(user_id,ends_at desc);

create table if not exists public.banner_ads (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  image_url text,
  target_url text,
  price_afn bigint not null check (price_afn > 0),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'pending' check (status in ('pending','active','rejected','expired')),
  created_at timestamptz not null default now()
);
create index if not exists banner_ads_active_idx on public.banner_ads(status,starts_at,ends_at);

alter table public.wallets enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.promotion_packages enable row level security;
alter table public.promotion_orders enable row level security;
alter table public.seller_subscriptions enable row level security;
alter table public.banner_ads enable row level security;

drop policy if exists wallets_self on public.wallets;
create policy wallets_self on public.wallets for select using (auth.uid() = user_id);
drop policy if exists wallet_tx_self on public.wallet_transactions;
create policy wallet_tx_self on public.wallet_transactions for select using (auth.uid() = user_id);
drop policy if exists promotion_packages_public on public.promotion_packages;
create policy promotion_packages_public on public.promotion_packages for select using (is_active = true);
drop policy if exists promotion_orders_self on public.promotion_orders;
create policy promotion_orders_self on public.promotion_orders for select using (auth.uid() = user_id);
drop policy if exists subscriptions_self on public.seller_subscriptions;
create policy subscriptions_self on public.seller_subscriptions for select using (auth.uid() = user_id);
drop policy if exists banner_ads_self on public.banner_ads;
create policy banner_ads_self on public.banner_ads for select using (auth.uid() = owner_id);

-- New sellers receive a small welcome credit exactly once when the backend creates their profile.
create or replace function public.bazarek_grant_welcome_credit(p_user_id uuid, p_amount bigint default 100)
returns void language plpgsql security definer set search_path=public as $$
begin
  insert into public.wallets(user_id,balance_afn) values(p_user_id,p_amount)
  on conflict(user_id) do nothing;
  insert into public.wallet_transactions(user_id,type,amount_afn,description,reference_id)
  select p_user_id,'welcome',p_amount,'اعتبار خوش‌آمدگویی بازارک',p_user_id::text
  where not exists(select 1 from public.wallet_transactions where user_id=p_user_id and type='welcome');
end; $$;

create or replace function public.bazarek_wallet_credit(p_user_id uuid,p_amount bigint,p_type text,p_description text,p_reference text default null)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_balance bigint;
begin
  if p_amount <= 0 then raise exception 'invalid amount'; end if;
  insert into wallets(user_id,balance_afn) values(p_user_id,0) on conflict(user_id) do nothing;
  update wallets set balance_afn=balance_afn+p_amount,updated_at=now() where user_id=p_user_id returning balance_afn into v_balance;
  insert into wallet_transactions(user_id,type,amount_afn,description,reference_id) values(p_user_id,p_type,p_amount,p_description,p_reference);
  return v_balance;
end; $$;

create or replace function public.bazarek_wallet_debit(p_user_id uuid,p_amount bigint,p_description text,p_reference text default null)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_balance bigint;
begin
  if p_amount <= 0 then raise exception 'invalid amount'; end if;
  insert into wallets(user_id,balance_afn) values(p_user_id,0) on conflict(user_id) do nothing;
  update wallets set balance_afn=balance_afn-p_amount,updated_at=now() where user_id=p_user_id and balance_afn>=p_amount returning balance_afn into v_balance;
  if v_balance is null then raise exception 'insufficient balance'; end if;
  insert into wallet_transactions(user_id,type,amount_afn,description,reference_id) values(p_user_id,'debit',p_amount,p_description,p_reference);
  return v_balance;
end; $$;
