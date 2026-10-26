-- Bazarek loyalty wallet + mobile credit request placeholder.
-- Points are server-managed. No telecom top-up is executed by this migration or API.
create table if not exists public.loyalty_wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  points integer not null default 0 check (points >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.loyalty_point_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  points_delta integer not null check (points_delta <> 0),
  reason text not null,
  reference_id text,
  created_at timestamptz not null default now()
);
create index if not exists loyalty_point_transactions_user_created_idx
  on public.loyalty_point_transactions(user_id, created_at desc);

create table if not exists public.mobile_credit_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  phone text not null,
  carrier text not null check (carrier in ('AWCC','Roshan','Etisalat','Salaam','ATOMA')),
  points_at_request integer not null check (points_at_request >= 0),
  status text not null default 'development_placeholder' check (status in ('development_placeholder','cancelled')),
  created_at timestamptz not null default now()
);
create index if not exists mobile_credit_requests_user_created_idx
  on public.mobile_credit_requests(user_id, created_at desc);

alter table public.loyalty_wallets enable row level security;
alter table public.loyalty_point_transactions enable row level security;
alter table public.mobile_credit_requests enable row level security;
-- No client-side policies: only the trusted backend service role can read/write these tables.

-- Seed a zero-point wallet lazily from the backend. Admin/service-role can maintain balances.
