-- Bazarek Boost 2.0: paid ranking levels + global seller boost subscriptions.
-- Short-term packages apply to one listing; monthly/yearly apply to all active listings of the seller.

alter table if exists public.products add column if not exists boost_level integer not null default 0;
alter table if exists public.products add column if not exists boost_until timestamptz;
create index if not exists products_boost_idx on public.products(boost_level desc, boost_until desc);

-- The original migration only allowed basic/pro/business and did not store payment reference fields.
alter table if exists public.seller_subscriptions add column if not exists payment_method text not null default 'manual';
alter table if exists public.seller_subscriptions add column if not exists payment_reference text;
alter table if exists public.seller_subscriptions drop constraint if exists seller_subscriptions_plan_check;
alter table if exists public.seller_subscriptions add constraint seller_subscriptions_plan_check check (plan in ('basic','pro','business','boost_monthly','boost_yearly'));

-- Replace the old promotion catalog with the simpler Boost catalog.
update public.promotion_packages set is_active=false
where id not in ('boost24','boost3','boost7');

insert into public.promotion_packages(id,title,description,price_afn,feature_days,pin_days,boost_level,is_active)
values
('boost24','⚡ توربو ۲۴ ساعته','۲۴ ساعت نمایش با اولویت بالاتر؛ فقط برای همین آگهی.',20,1,1,1,true),
('boost3','🔥 انفجاری ۳ روزه','۳ روز نمایش پرقدرت با اولویت بالاتر؛ فقط برای همین آگهی.',40,3,3,2,true),
('boost7','💥 قدرتی ۷ روزه','۷ روز بیشترین اولویت تک‌آگهی در بین بوست‌های کوتاه‌مدت.',70,7,7,3,true)
on conflict (id) do update set
title=excluded.title,
description=excluded.description,
price_afn=excluded.price_afn,
feature_days=excluded.feature_days,
pin_days=excluded.pin_days,
boost_level=excluded.boost_level,
is_active=true;

create index if not exists seller_subscriptions_boost_idx on public.seller_subscriptions(user_id,status,ends_at desc);
