-- فروشگاه‌های قدیمی: نام/معرفی/شهر/لوگوی فروشگاه از پروفایل شخصی کپی می‌شود تا
-- «پروفایل فروشگاه» از «پروفایل شخصی» جدا باشد و آگهی‌های عادی نام شخصی را نشان بدهند.
-- (فقط فیلدهای خالیِ پروفایل فروشگاه پر می‌شوند؛ چند بار اجرا کردن مشکلی ندارد.)
update public.profiles p
set store_name     = case when p.store_name     = '' then coalesce(p.shop_name, '')  else p.store_name     end,
    store_bio      = case when p.store_bio      = '' then coalesce(p.bio, '')        else p.store_bio      end,
    store_city     = case when p.store_city     = '' then coalesce(p.city, '')       else p.store_city     end,
    store_logo_url = case when p.store_logo_url = '' then coalesce(p.avatar_url, '') else p.store_logo_url end,
    store_phone    = case when p.store_phone    = '' then coalesce(p.phone, '')      else p.store_phone    end
where p.id in (
  select user_id from public.seller_subscriptions
  where plan in ('store_monthly', 'store_yearly')
)
and coalesce(p.shop_name, '') <> '';
