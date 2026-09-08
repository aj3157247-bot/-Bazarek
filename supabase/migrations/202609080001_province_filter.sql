-- Bazarek: Afghanistan province support
-- Adds a dedicated province field to listings so filtering is exact and reliable.

alter table public.products
  add column if not exists province text;

create index if not exists products_province_idx
  on public.products(province);

-- Best-effort backfill for older listings whose location text starts with a province name.
update public.products set province = case
  when province is null and location_text ilike 'بدخشان%' then 'بدخشان'
  when province is null and location_text ilike 'بادغیس%' then 'بادغیس'
  when province is null and location_text ilike 'بغلان%' then 'بغلان'
  when province is null and location_text ilike 'بلخ%' then 'بلخ'
  when province is null and location_text ilike 'بامیان%' then 'بامیان'
  when province is null and location_text ilike 'دایکندی%' then 'دایکندی'
  when province is null and location_text ilike 'فراه%' then 'فراه'
  when province is null and location_text ilike 'فاریاب%' then 'فاریاب'
  when province is null and location_text ilike 'غزنی%' then 'غزنی'
  when province is null and location_text ilike 'غور%' then 'غور'
  when province is null and location_text ilike 'هلمند%' then 'هلمند'
  when province is null and location_text ilike 'هرات%' then 'هرات'
  when province is null and location_text ilike 'جوزجان%' then 'جوزجان'
  when province is null and location_text ilike 'کابل%' then 'کابل'
  when province is null and location_text ilike 'کندهار%' then 'کندهار'
  when province is null and location_text ilike 'کاپیسا%' then 'کاپیسا'
  when province is null and location_text ilike 'خوست%' then 'خوست'
  when province is null and (location_text ilike 'کنر%' or location_text ilike 'کونړ%') then 'کنر'
  when province is null and location_text ilike 'کندز%' then 'کندز'
  when province is null and location_text ilike 'لغمان%' then 'لغمان'
  when province is null and location_text ilike 'لوگر%' then 'لوگر'
  when province is null and (location_text ilike 'ننگرهار%' or location_text ilike 'ننګرهار%') then 'ننگرهار'
  when province is null and location_text ilike 'نیمروز%' then 'نیمروز'
  when province is null and location_text ilike 'نورستان%' then 'نورستان'
  when province is null and location_text ilike 'پکتیکا%' then 'پکتیکا'
  when province is null and location_text ilike 'پکتیا%' then 'پکتیا'
  when province is null and (location_text ilike 'پنجشیر%' or location_text ilike 'پنجشېر%') then 'پنجشیر'
  when province is null and location_text ilike 'پروان%' then 'پروان'
  when province is null and location_text ilike 'سمنگان%' then 'سمنگان'
  when province is null and location_text ilike 'سرپل%' then 'سرپل'
  when province is null and location_text ilike 'تخار%' then 'تخار'
  when province is null and (location_text ilike 'ارزگان%' or location_text ilike 'اروزگان%') then 'ارزگان'
  when province is null and (location_text ilike 'وردک%' or location_text ilike 'وردګ%') then 'وردک'
  when province is null and location_text ilike 'زابل%' then 'زابل'
  else province end
where province is null;
