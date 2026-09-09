-- Admin moderation tables used by the existing report/warning API.
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.products(id) on delete cascade,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reason text not null check (char_length(reason) between 1 and 500),
  status text not null default 'open' check (status in ('open','reviewed','dismissed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists reports_status_created_idx on public.reports(status, created_at desc);
create index if not exists reports_listing_idx on public.reports(listing_id, created_at desc);
create index if not exists reports_reporter_idx on public.reports(reporter_id, created_at desc);

create table if not exists public.user_warnings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  message text not null check (char_length(message) between 1 and 1000),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists user_warnings_user_created_idx on public.user_warnings(user_id, created_at desc);

alter table public.reports enable row level security;
alter table public.user_warnings enable row level security;

drop policy if exists reports_insert_own on public.reports;
create policy reports_insert_own on public.reports for insert with check (auth.uid() = reporter_id);

drop policy if exists reports_select_own on public.reports;
create policy reports_select_own on public.reports for select using (auth.uid() = reporter_id);

drop policy if exists warnings_select_own on public.user_warnings;
create policy warnings_select_own on public.user_warnings for select using (auth.uid() = user_id);
