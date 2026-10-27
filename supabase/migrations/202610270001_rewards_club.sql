-- باشگاه امتیاز بازارک: کسب امتیاز (ثبت آگهی، دعوت دوستان، ورود روزانه، ...) و مصرف آن
-- (ویژه کردن آگهی، کریدت موبایل). همه‌ی تغییرات امتیاز فقط از طریق سرور و تابع زیر انجام می‌شود.

-- ۱) کد دعوت
alter table public.profiles add column if not exists referral_code text;
alter table public.profiles add column if not exists referred_by uuid references auth.users(id) on delete set null;
create unique index if not exists profiles_referral_code_uidx on public.profiles (referral_code) where referral_code is not null;

-- ۲) هر رویداد امتیازدهی فقط یک‌بار (جلوگیری از امتیاز تکراری برای یک آگهی/دعوت/روز)
create unique index if not exists loyalty_tx_once_idx
  on public.loyalty_point_transactions (user_id, reason, reference_id) where reference_id is not null;

-- ۳) درخواست‌های کریدت موبایل (واقعی؛ مدیریت بعد از شارژ، «انجام شد» می‌زند)
alter table public.mobile_credit_requests drop constraint if exists mobile_credit_requests_status_check;
alter table public.mobile_credit_requests
  add constraint mobile_credit_requests_status_check
  check (status in ('development_placeholder','pending','completed','rejected','cancelled'));
alter table public.mobile_credit_requests add column if not exists amount_afn integer not null default 0;
alter table public.mobile_credit_requests add column if not exists points_spent integer not null default 0;
alter table public.mobile_credit_requests add column if not exists admin_note text not null default '';
alter table public.mobile_credit_requests add column if not exists updated_at timestamptz not null default now();
create index if not exists mobile_credit_requests_status_idx on public.mobile_credit_requests (status, created_at desc);

-- ۴) تغییر امتیاز به‌صورت اتمیک؛ اگر همان رویداد قبلاً ثبت شده باشد یا موجودی کم باشد، تغییری نمی‌دهد.
create or replace function public.loyalty_adjust(p_user uuid, p_delta int, p_reason text, p_ref text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  new_points int;
begin
  if p_delta = 0 then
    return jsonb_build_object('ok', false, 'error', 'zero');
  end if;
  insert into loyalty_wallets (user_id, points) values (p_user, 0) on conflict (user_id) do nothing;
  -- قفل ردیف کیف امتیاز تا دو درخواست هم‌زمان موجودی را خراب نکنند
  perform 1 from loyalty_wallets where user_id = p_user for update;
  if p_delta < 0 and (select points from loyalty_wallets where user_id = p_user) + p_delta < 0 then
    return jsonb_build_object('ok', false, 'error', 'insufficient');
  end if;
  begin
    insert into loyalty_point_transactions (user_id, points_delta, reason, reference_id)
    values (p_user, p_delta, p_reason, p_ref);
  exception when unique_violation then
    return jsonb_build_object('ok', false, 'error', 'duplicate');
  end;
  update loyalty_wallets set points = points + p_delta, updated_at = now()
  where user_id = p_user returning points into new_points;
  return jsonb_build_object('ok', true, 'points', new_points);
end;
$$;
revoke all on function public.loyalty_adjust(uuid, int, text, text) from public, anon, authenticated;
