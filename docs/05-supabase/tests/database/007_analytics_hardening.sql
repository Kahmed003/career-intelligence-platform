begin;

do $test$
declare v_count integer;
begin
  select count(*) into v_count
  from public.current_analytics_metric_definitions
  where metric_key in ('campaign_performance','pipeline_health','relationship_health');

  if v_count <> 3 then
    raise exception 'Expected three current core analytics metric definitions; got %', v_count;
  end if;

  if not exists (
    select 1 from public.current_analytics_metric_definitions
    where metric_key='campaign_performance'
      and known_limitations is not null
  ) then
    raise exception 'Campaign performance must remain explicitly marked with known limitations until consolidated.';
  end if;
end
$test$;

do $test$
begin
  begin
    insert into public.analytics_snapshot_execution_attempts
      (owner_user_id,snapshot_date,status,finished_at)
    values
      (gen_random_uuid(),current_date,'failed',statement_timestamp());
    raise exception 'Expected failed attempt without error_message to be rejected.';
  exception
    when check_violation or foreign_key_violation then
      null;
  end;
end
$test$;

rollback;
