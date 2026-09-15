begin;
do $t$ declare x text; begin
 foreach x in array array['analytics_snapshot_runs','campaign_performance_snapshots',
 'relationship_health_snapshots','pipeline_health_snapshots'] loop
  if to_regclass('public.'||x) is null then raise exception 'FAIL: missing table %',x; end if;
 end loop;
end $t$;

do $t$ declare x text; r boolean; begin
 foreach x in array array['analytics_snapshot_runs','campaign_performance_snapshots',
 'relationship_health_snapshots','pipeline_health_snapshots'] loop
  select c.relrowsecurity into r from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname=x;
  if coalesce(r,false)=false then raise exception 'FAIL: RLS disabled on %',x; end if;
 end loop;
end $t$;

do $t$ begin
 if not exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='capture_daily_analytics_snapshot' and p.prosecdef)
 then raise exception 'FAIL: capture function missing/not SECURITY DEFINER'; end if;
end $t$;

do $t$ begin
 if not exists(select 1 from pg_indexes where schemaname='public'
  and indexname='ux_analytics_snapshot_runs__active_daily')
 then raise exception 'FAIL: idempotency index missing'; end if;
end $t$;

do $t$ declare x text; begin
 foreach x in array array['analytics_snapshot_runs','campaign_performance_snapshots',
 'relationship_health_snapshots','pipeline_health_snapshots'] loop
  if has_table_privilege('anon','public.'||x,'SELECT')
   or has_table_privilege('anon','public.'||x,'INSERT')
   or has_table_privilege('anon','public.'||x,'UPDATE')
   or has_table_privilege('anon','public.'||x,'DELETE')
  then raise exception 'FAIL: anon privilege remains on %',x; end if;
 end loop;
end $t$;
rollback;