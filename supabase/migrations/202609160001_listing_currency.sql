-- Bazarek listing currency support: sellers choose AFN or USD per listing.
alter table public.products
  add column if not exists currency text not null default 'AFN';

update public.products set currency = 'AFN' where currency is null or currency not in ('AFN','USD');

alter table public.products
  drop constraint if exists products_currency_check;

alter table public.products
  add constraint products_currency_check check (currency in ('AFN','USD'));

create index if not exists products_currency_idx on public.products(currency);
