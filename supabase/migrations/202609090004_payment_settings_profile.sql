-- Bazarek payment destination shown to users during Boost/subscription checkout.
-- Fill the single row below with your real payment information in Supabase.
create table if not exists public.payment_settings (
  id integer primary key check (id = 1),
  bank_name text not null default '',
  account_name text not null default '',
  account_number text not null default '',
  card_number text not null default '',
  branch text not null default '',
  swift_code text not null default '',
  instructions text not null default '',
  updated_at timestamptz not null default now()
);

insert into public.payment_settings (id) values (1)
on conflict (id) do nothing;

-- This table is read through the backend service role only.
alter table public.payment_settings enable row level security;

-- New global Boost prices.
update public.seller_subscriptions set price_afn=300 where plan='boost_monthly' and status='pending';
update public.seller_subscriptions set price_afn=2500 where plan='boost_yearly' and status='pending';
