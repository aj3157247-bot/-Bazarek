-- Bazarek professional profile + support inbox
alter table public.profiles add column if not exists bio text not null default '';
alter table public.profiles add column if not exists verified boolean not null default false;
create table if not exists public.support_requests (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 type text not null default 'support' check (type in ('bug','suggestion','support','report')),
 title text not null,
 message text not null,
 admin_reply text not null default '',
 status text not null default 'open' check (status in ('open','in_progress','answered','resolved','closed')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists support_requests_user_idx on public.support_requests(user_id,created_at desc);
create index if not exists support_requests_status_idx on public.support_requests(status,created_at desc);
alter table public.support_requests enable row level security;
drop policy if exists support_requests_own on public.support_requests;
create policy support_requests_own on public.support_requests for all using (auth.uid()=user_id) with check (auth.uid()=user_id);
