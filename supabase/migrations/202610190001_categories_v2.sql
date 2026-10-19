-- دسته‌بندی جدید (متناسب با بازار افغانستان): انتقال آگهی‌های قبلی به شناسه‌های جدید.
-- می‌توانید با خیال راحت چند بار اجرا کنید (فقط ردیف‌های قدیمی را تغییر می‌دهد).
begin;

-- موبایل از «الکترونیک» به دسته‌ی مستقل «موبایل و تبلت»
update public.products set category = 'mobile_tablets' where category = 'electronics' and subcategory = 'mobile';

-- بایسکل از «ورزش» به «وسایط نقلیه»
update public.products set category = 'vehicles', subcategory = 'bicycles' where category = 'sports_hobbies' and subcategory = 'bicycles';

-- گیم و کنسول به الکترونیک
update public.products set category = 'electronics', subcategory = 'gaming' where category = 'sports_hobbies' and subcategory = 'gaming';

-- جنراتور و سولر به دسته‌ی «انرژی و سولر»
update public.products set category = 'energy_solar', subcategory = 'generators'   where category = 'construction_tools' and subcategory = 'generators';
update public.products set category = 'energy_solar', subcategory = 'solar_panels' where category = 'construction_tools' and subcategory = 'solar';

-- وسایل شخصی ← لباس و پوشاک / ساعت، عینک و کیف
update public.products set category = 'fashion', subcategory = 'accessories' where category = 'personal';

-- پرنده‌ها و ماهی زینتی
update public.products set subcategory = 'parrots'      where category = 'animals_pets' and subcategory = 'birds';
update public.products set subcategory = 'pet_supplies' where category = 'animals_pets' and subcategory = 'ornamental_fish';

-- آموزش از «خدمات» به «تعلیم و آموزش»
update public.products set category = 'education', subcategory = 'courses' where category = 'services' and subcategory = 'education';

commit;

-- توجه: آگهی‌های دسته‌های حذف‌شده (social_pages, lost_found) دست نخورده‌اند؛
-- در صفحه‌ی اصلی دیده می‌شوند ولی در فهرست دسته‌ها نیستند.
