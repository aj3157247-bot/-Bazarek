-- Professional marketplace catalog fields.
-- Keeps normal listings compatible while allowing professional stores to
-- present structured product specifications and variants.
alter table public.products
  add column if not exists product_specs jsonb not null default '{}'::jsonb,
  add column if not exists product_variants jsonb not null default '[]'::jsonb,
  add column if not exists watermark_enabled boolean not null default true;

create index if not exists products_product_specs_gin_idx
  on public.products using gin (product_specs);
