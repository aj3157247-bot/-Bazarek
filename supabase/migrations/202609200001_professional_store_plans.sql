-- Bazarek professional storefront plans
-- Monthly: 600 AFN / 30 days
-- Yearly: 6000 AFN / 365 days

alter table public.seller_subscriptions
  drop constraint if exists seller_subscriptions_plan_check;

alter table public.seller_subscriptions
  add constraint seller_subscriptions_plan_check
  check (plan in ('basic','pro','business','monthly_boost','yearly_boost','boost_weekly','boost_monthly','boost_yearly','store_monthly','store_yearly'));
