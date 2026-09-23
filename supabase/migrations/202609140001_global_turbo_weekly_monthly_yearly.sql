-- Bazarek Global Turbo plans 1.0
-- Replaces the old 24-hour / 3-day short Boost choices in the user-facing
-- monetization flow with seller-wide weekly/monthly/yearly plans.
-- The Turbo clock starts ONLY when management approves the payment.

-- Keep the existing subscription table, but allow pending requests to have
-- no start/end time until management approval.
alter table if exists public.seller_subscriptions
  alter column starts_at drop not null;
alter table if exists public.seller_subscriptions
  alter column ends_at drop not null;

-- Add the new weekly plan while preserving the existing subscription plans.
alter table if exists public.seller_subscriptions
  drop constraint if exists seller_subscriptions_plan_check;

alter table if exists public.seller_subscriptions
  add constraint seller_subscriptions_plan_check
  check (plan in ('basic','pro','business','monthly_boost','yearly_boost','boost_weekly','boost_monthly','boost_yearly','store_monthly','store_yearly'));

-- Existing pending Boost requests should not have a clock running before approval.
update public.seller_subscriptions
set starts_at = null,
    ends_at = null
where status = 'pending'
  and plan in ('boost_weekly','boost_monthly','boost_yearly');

-- New agreed prices.
update public.seller_subscriptions
set price_afn = 500
where plan = 'boost_monthly'
  and status = 'pending';

update public.seller_subscriptions
set price_afn = 4500
where plan = 'boost_yearly'
  and status = 'pending';

-- Old per-listing packages are no longer offered in the monetization UI.
-- We deactivate them instead of deleting them so historical orders remain intact.
update public.promotion_packages
set is_active = false
where id in ('boost24','boost3','boost7');

create index if not exists seller_subscriptions_turbo_idx
  on public.seller_subscriptions(user_id, status, plan, starts_at, ends_at desc);

comment on column public.seller_subscriptions.starts_at is
  'Turbo start time. For pending payments this remains NULL until management approval.';
comment on column public.seller_subscriptions.ends_at is
  'Turbo end time. Calculated from the exact management approval time.';
