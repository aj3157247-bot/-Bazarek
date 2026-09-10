-- Bazarek: HesabPay online payments. Manual payment remains available.
alter table public.promotion_orders drop constraint if exists promotion_orders_payment_method_check;
alter table public.promotion_orders add constraint promotion_orders_payment_method_check check (payment_method in ('wallet','manual','gateway','hesabpay','bank_transfer'));
alter table public.promotion_orders add column if not exists checkout_url text;
alter table public.promotion_orders add column if not exists external_transaction_id text;
alter table public.promotion_orders add column if not exists paid_at timestamptz;
alter table public.seller_subscriptions add column if not exists checkout_url text;
alter table public.seller_subscriptions add column if not exists external_transaction_id text;
alter table public.seller_subscriptions add column if not exists paid_at timestamptz;
create index if not exists promotion_orders_external_transaction_id_idx on public.promotion_orders(external_transaction_id);
create index if not exists seller_subscriptions_external_transaction_id_idx on public.seller_subscriptions(external_transaction_id);
