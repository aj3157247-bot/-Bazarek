-- Bazarek: strictly separate ordinary ads from professional-store products.
-- Existing products were ordinary ads before the professional product flow existed.
-- Reset any accidental/backfilled store classification and remove boost state from them.
UPDATE public.products
SET
  is_store_product = false,
  is_featured = false,
  is_pinned = false,
  featured_until = NULL,
  pinned_until = NULL,
  boost_level = 0,
  boost_until = NULL
WHERE is_store_product = true;

-- From this point forward, only /api/products with is_store_product=true
-- (the professional "افزودن محصول" flow) can create store products.
