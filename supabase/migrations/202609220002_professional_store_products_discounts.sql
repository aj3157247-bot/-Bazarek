-- Professional store product catalog:
-- keeps store products separate from ordinary marketplace ads and adds discounts.

alter table public.products
  add column if not exists is_store_product boolean not null default false;

alter table public.products
  add column if not exists discount_percent numeric(5,2) not null default 0;

alter table public.products
  add constraint products_discount_percent_check
  check (discount_percent >= 0 and discount_percent < 100);

create index if not exists products_store_product_idx
  on public.products(vendor_id, is_store_product, is_active, created_at desc);

-- Existing products owned by sellers who currently have an active paid store
-- become store products so an existing catalog is not lost after this upgrade.
update public.products p
set is_store_product = true
where exists (
  select 1
  from public.seller_subscriptions s
  where s.user_id = p.vendor_id
    and s.status = 'active'
    and s.plan in ('store_monthly','store_yearly')
    and (s.starts_at is null or s.starts_at <= now())
    and s.ends_at > now()
);
