-- Bazarek Boost + Payment hardening.
-- Keeps short Boosts per listing and monthly/yearly Boost as seller-wide plans.

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

insert into public.payment_settings (id, bank_name, account_name, account_number, card_number, instructions)
values (1, '', '', '', '', 'مبلغ دقیق را به کارت/حساب بالا انتقال دهید، رسید یا شماره پیگیری را نگه دارید، آن را در برنامه وارد کنید و منتظر تأیید مدیریت بمانید. پس از تأیید، Boost فعال می‌شود.')
on conflict (id) do nothing;

alter table public.payment_settings enable row level security;

-- Ensure the three short Boost packages exist with the agreed low prices.
insert into public.promotion_packages(id,title,description,price_afn,feature_days,pin_days,boost_level,is_active)
values
('boost24','⚡ توربو ۲۴ ساعته','۲۴ ساعت؛ فقط برای همین آگهی، ارزان‌ترین راه برای بیشتر دیده‌شدن.',10,1,1,1,true),
('boost3','🔥 انفجاری ۳ روزه','۳ روز؛ فقط برای همین آگهی، با اولویت بیشتر در نمایش.',20,3,3,2,true),
('boost7','💥 قدرتی ۷ روزه','۷ روز؛ فقط برای همین آگهی، قوی‌ترین Boost کوتاه‌مدت.',35,7,7,3,true)
on conflict (id) do update set
  title=excluded.title,
  description=excluded.description,
  price_afn=excluded.price_afn,
  feature_days=excluded.feature_days,
  pin_days=excluded.pin_days,
  boost_level=excluded.boost_level,
  is_active=true;

-- Global Boost plans: monthly 300 AFN / yearly 2500 AFN.
alter table if exists public.seller_subscriptions drop constraint if exists seller_subscriptions_plan_check;
alter table if exists public.seller_subscriptions
  add constraint seller_subscriptions_plan_check
  check (plan in ('basic','pro','business','boost_monthly','boost_yearly'));

update public.seller_subscriptions
set price_afn = 300
where plan = 'boost_monthly' and status = 'pending';

update public.seller_subscriptions
set price_afn = 2500
where plan = 'boost_yearly' and status = 'pending';

create index if not exists products_boost_rank_idx
  on public.products (boost_level desc, boost_until desc, created_at desc);
