-- Optional voice description for marketplace ads/products.
alter table if exists public.products
  add column if not exists description_audio_url text not null default '';

create index if not exists products_description_audio_idx
  on public.products(description_audio_url)
  where description_audio_url <> '';
