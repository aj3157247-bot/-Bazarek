-- Bazarek admin moderation, notifications, finance cleanup and security audit.

alter table public.wallet_transactions
  add column if not exists is_archived boolean not null default false;

create index if not exists wallet_tx_archived_created_idx
  on public.wallet_transactions(is_archived, created_at desc);

alter table public.reports
  add column if not exists resolution_note text not null default '';

create table if not exists public.user_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null default 'system' check (type in ('system','report','warning','payment','security')),
  title text not null default 'اعلان بازارک',
  message text not null check (char_length(message) between 1 and 2000),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists user_notifications_user_idx
  on public.user_notifications(user_id, is_read, created_at desc);

alter table public.user_notifications enable row level security;
drop policy if exists user_notifications_select_own on public.user_notifications;
create policy user_notifications_select_own on public.user_notifications for select using (auth.uid() = user_id);
drop policy if exists user_notifications_update_own on public.user_notifications;
create policy user_notifications_update_own on public.user_notifications for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists user_notifications_delete_own on public.user_notifications;
create policy user_notifications_delete_own on public.user_notifications for delete using (auth.uid() = user_id);

create table if not exists public.admin_login_events (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  success boolean not null default false,
  ip_address text,
  user_agent text,
  created_at timestamptz not null default now()
);
create index if not exists admin_login_events_created_idx
  on public.admin_login_events(created_at desc);
