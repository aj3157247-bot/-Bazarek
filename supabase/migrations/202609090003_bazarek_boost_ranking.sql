-- Bazarek Boost v3: automatic paid ranking + global seller boost plans

-- Keep old packages for historical orders, but hide them from the new Boost UI.
update public.promotion_packages
set is_active = false
where id in ('featured7','featured30','pin7','pin30','boost7','boost30');

insert into public.promotion_packages
  (id,title,description,price_afn,feature_days,pin_days,boost_level,is_active)
values
  ('turbo24','⚡ توربو ۲۴ ساعته','برای ۲۴ ساعت آگهی‌ات با اولویت بیشتر نمایش داده می‌شود؛ مناسب فروش سریع.',20,1,1,1,true),
  ('blast3','🔥 انفجاری ۳ روزه','۳ روز دیده‌شدن بیشتر و جایگاه بالاتر در بین آگهی‌های فعال.',40,3,3,2,true),
  ('power7','💥 قدرتی ۷ روزه','۷ روز بیشترین اولویت را در بین بوست‌های تک‌آگهی می‌گیرد.',70,7,7,3,true)
on conflict (id) do update set
  title=excluded.title,
  description=excluded.description,
  price_afn=excluded.price_afn,
  feature_days=excluded.feature_days,
  pin_days=excluded.pin_days,
  boost_level=excluded.boost_level,
  is_active=true;

-- Existing subscriptions used basic/pro/business. Replace the check so Boost can use
-- dedicated monthly/yearly plans without affecting historical rows.
alter table public.seller_subscriptions drop constraint if exists seller_subscriptions_plan_check;
alter table public.seller_subscriptions
  add constraint seller_subscriptions_plan_check
  check (plan in ('basic','pro','business','monthly_boost','yearly_boost'));

create index if not exists seller_subscriptions_boost_active_idx
  on public.seller_subscriptions(user_id,status,ends_at desc)
  where plan in ('monthly_boost','yearly_boost');

-- Helpful metadata for future clients/admin screens.
comment on column public.seller_subscriptions.plan is 'Subscription plan: basic/pro/business or monthly_boost/yearly_boost';
