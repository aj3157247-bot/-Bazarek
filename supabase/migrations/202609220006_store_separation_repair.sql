-- Bazarek final repair: store-product separation + saved stores.
-- Safe/idempotent. Does not convert ordinary ads automatically.
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_store_product boolean NOT NULL DEFAULT false;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS discount_percent numeric(5,2) NOT NULL DEFAULT 0;
CREATE INDEX IF NOT EXISTS products_store_product_idx ON public.products(vendor_id,is_store_product,is_active,created_at DESC);

CREATE TABLE IF NOT EXISTS public.saved_stores (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  seller_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id,seller_id),
  CHECK (user_id <> seller_id)
);
CREATE INDEX IF NOT EXISTS saved_stores_user_idx ON public.saved_stores(user_id,created_at DESC);
CREATE INDEX IF NOT EXISTS saved_stores_seller_idx ON public.saved_stores(seller_id,created_at DESC);
ALTER TABLE public.saved_stores ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS saved_stores_select_own ON public.saved_stores;
CREATE POLICY saved_stores_select_own ON public.saved_stores FOR SELECT USING (auth.uid()=user_id);
DROP POLICY IF EXISTS saved_stores_self_write ON public.saved_stores;
CREATE POLICY saved_stores_self_write ON public.saved_stores FOR ALL USING (auth.uid()=user_id) WITH CHECK (auth.uid()=user_id);

UPDATE public.products SET is_featured=false,is_pinned=false,featured_until=NULL,pinned_until=NULL,boost_level=0,boost_until=NULL WHERE is_store_product=true;
