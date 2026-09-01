
/* Career OS regression tests — Hardening Batch 4 */
begin;

do $test$
begin
    if not exists (
        select 1 from information_schema.columns
        where table_schema='public'
          and table_name='discovered_opportunities'
          and column_name='duplicate_of_record_id'
    ) then raise exception 'FAIL: duplicate provenance column missing'; end if;
end;
$test$;

do $test$
declare v_def text;
begin
    select pg_get_viewdef('public.notes_knowledge_search'::regclass,true) into v_def;
    if v_def not ilike '%o.title%' then
        raise exception 'FAIL: notes search does not include canonical title';
    end if;
end;
$test$;

do $test$
declare v_def text;
begin
    select pg_get_viewdef('public.pipeline_application_summary'::regclass,true) into v_def;
    if v_def not ilike '%org_obj.deleted_at IS NULL%' then
        raise exception 'FAIL: pipeline summary does not filter deleted organizations';
    end if;
end;
$test$;

do $test$
begin
    if not exists (
        select 1 from pg_trigger
        where tgname='trg_notifications__validate_transition'
          and not tgisinternal
    ) then raise exception 'FAIL: notification transition trigger missing'; end if;
end;
$test$;

do $test$
begin
    if to_regclass('public.campaign_deadline_pressure') is null then
        raise exception 'FAIL: campaign deadline pressure view missing';
    end if;
end;
$test$;

rollback;
