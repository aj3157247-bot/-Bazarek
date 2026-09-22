-- Bazarek: saved professional stores.
-- Safe/idempotent: run once in Supabase SQL Editor.
CREATE TABLE IF NOT EXISTS public.saved_stores (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  seller_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, seller_id),
  CHECK (user_id <> seller_id)
);
CREATE INDEX IF NOT EXISTS saved_stores_user_idx ON public.saved_stores(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS saved_stores_seller_idx ON public.saved_stores(seller_id, created_at DESC);
ALTER TABLE public.saved_stores ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS saved_stores_select_own ON public.saved_stores;
CREATE POLICY saved_stores_select_own ON public.saved_stores FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS saved_stores_self_write ON public.saved_stores;
CREATE POLICY saved_stores_self_write ON public.saved_stores FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
