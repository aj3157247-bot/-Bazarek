-- Bazarek automatic Boost expiry.
-- IMPORTANT: A Boost starts only when management changes its promotion order to paid.
-- The end timestamp is calculated from that approval moment. This migration makes
-- expiration automatic at database level as well as in the Render backend worker.

create or replace function public.bazarek_expire_time_based_boosts()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  now_ts timestamptz := now();
  expired_boosts integer := 0;
  expired_featured integer := 0;
  expired_pinned integer := 0;
  expired_subscriptions integer := 0;
begin
  update public.products
     set boost_level = 0,
         boost_until = null,
         updated_at = now_ts
   where boost_until is not null
     and boost_until <= now_ts;
  get diagnostics expired_boosts = row_count;

  update public.products
     set is_featured = false,
         featured_until = null,
         updated_at = now_ts
   where is_featured = true
     and featured_until is not null
     and featured_until <= now_ts;
  get diagnostics expired_featured = row_count;

  update public.products
     set is_pinned = false,
         pinned_until = null,
         updated_at = now_ts
   where is_pinned = true
     and pinned_until is not null
     and pinned_until <= now_ts;
  get diagnostics expired_pinned = row_count;

  update public.seller_subscriptions
     set status = 'expired'
   where status = 'active'
     and ends_at <= now_ts;
  get diagnostics expired_subscriptions = row_count;

  return jsonb_build_object(
    'expired_boosts', expired_boosts,
    'expired_featured', expired_featured,
    'expired_pinned', expired_pinned,
    'expired_subscriptions', expired_subscriptions,
    'ran_at', now_ts
  );
end;
$$;

revoke all on function public.bazarek_expire_time_based_boosts() from public;
grant execute on function public.bazarek_expire_time_based_boosts() to service_role;

-- Supabase normally provides pg_cron. Install/schedule only when the extension is
-- available, so this migration does not fail on projects where pg_cron is disabled.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    begin
      perform cron.unschedule(jobid)
      from cron.job
      where jobname = 'bazarek-automatic-boost-expiry';
    exception when others then
      null;
    end;

    begin
      perform cron.schedule(
        'bazarek-automatic-boost-expiry',
        '* * * * *',
        $job$select public.bazarek_expire_time_based_boosts();$job$
      );
    exception when others then
      raise notice 'Bazarek pg_cron schedule could not be created; Render worker remains active.';
    end;
  else
    raise notice 'pg_cron is not enabled; Render backend expiry worker remains active.';
  end if;
end;
$$;
