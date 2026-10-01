-- Bazarek voice messages for ordinary ads and professional store products.
alter table if exists public.products
  add column if not exists audio_url text not null default '';

create index if not exists products_audio_url_idx
  on public.products (audio_url)
  where audio_url <> '';
