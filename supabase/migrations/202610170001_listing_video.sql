-- ویدیوی کوتاه آگهی/محصول (آگهی عادی ≤ ۳۰ ثانیه، فروشگاه حرفه‌ای ≤ ۶۰ ثانیه).
-- این فایل را قبل از Deploy بک‌اند یک بار در Supabase SQL Editor اجرا کنید.
alter table public.products
  add column if not exists video_url text not null default '';

-- bucket عمومی ویدیو؛ در صورت نبود، خود بک‌اند هنگام اولین آپلود هم می‌سازد.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('listing-videos', 'listing-videos', true, 41943040, array['video/mp4','video/webm','video/quicktime'])
on conflict (id) do update
  set public = true,
      file_size_limit = 41943040,
      allowed_mime_types = array['video/mp4','video/webm','video/quicktime'];
