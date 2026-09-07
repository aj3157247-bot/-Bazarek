-- Bazarek v2.5: affordable pricing + clear package descriptions.
update public.promotion_packages set
  price_afn = case id
    when 'featured7' then 30
    when 'featured30' then 80
    when 'pin7' then 50
    when 'pin30' then 120
    when 'boost7' then 80
    when 'boost30' then 180
    else price_afn
  end,
  description = case id
    when 'featured7' then '⭐ آگهی برای ۷ روز برجسته‌تر نمایش داده می‌شود تا سریع‌تر دیده شود.'
    when 'featured30' then '⭐ آگهی برای ۳۰ روز در جایگاه برجسته‌تر قرار می‌گیرد؛ مناسب فروش سریع‌تر.'
    when 'pin7' then '📌 آگهی برای ۷ روز در بخش‌های بالاتر/برجسته‌تر قرار می‌گیرد تا توجه بیشتری بگیرد.'
    when 'pin30' then '📌 آگهی برای ۳۰ روز پین می‌شود؛ مناسب کالاهای مهم و فروشنده‌های فعال.'
    when 'boost7' then '🚀 ویژه + پین برای ۷ روز؛ ترکیبی برای افزایش دیده‌شدن و جلب توجه خریداران.'
    when 'boost30' then '🚀 ویژه + پین برای ۳۰ روز؛ بهترین گزینه اقتصادی برای دیده‌شدن طولانی‌تر.'
    else description
  end
where id in ('featured7','featured30','pin7','pin30','boost7','boost30');

-- Subscription prices are kept affordable for early-stage sellers.
-- Basic: 150 AFN/month — starter sellers
-- Pro: 250 AFN/month — active sellers
-- Business: 450 AFN/month — shops and businesses
