-- Bazarek: profile avatar storage fix.
-- The backend stores the public avatar URL in profiles.avatar_url.
alter table public.profiles
  add column if not exists avatar_url text not null default '';
