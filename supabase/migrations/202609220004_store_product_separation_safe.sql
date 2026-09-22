-- Safe follow-up migration for Bazarek store-product separation.
-- IMPORTANT: do not reset existing is_store_product=true rows.
-- Those rows are already legitimate professional-store products.

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS is_store_product boolean NOT NULL DEFAULT false;

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS discount_percent numeric(5,2) NOT NULL DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'products_discount_percent_check'
      AND conrelid = 'public.products'::regclass
  ) THEN
    ALTER TABLE public.products
      ADD CONSTRAINT products_discount_percent_check
      CHECK (discount_percent >= 0 AND discount_percent < 100);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS products_store_product_idx
  ON public.products(vendor_id, is_store_product, is_active, created_at DESC);

-- Store products must never retain ordinary-ad promotion state.
UPDATE public.products
SET is_featured = false,
    is_pinned = false,
    featured_until = NULL,
    pinned_until = NULL,
    boost_level = 0,
    boost_until = NULL
WHERE is_store_product = true;
