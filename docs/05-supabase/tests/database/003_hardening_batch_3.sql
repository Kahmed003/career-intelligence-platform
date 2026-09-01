
/* Career OS regression tests — Hardening Batch 3 */
begin;

do $test$
begin
    if not exists (
        select 1
        from pg_indexes
        where schemaname='public'
          and indexname='ux_document_attachments__one_primary_per_role'
    ) then
        raise exception 'FAIL: primary attachment uniqueness index missing';
    end if;
end;
$test$;

do $test$
declare v_def text;
begin
    select pg_get_viewdef('public.person_relationship_health'::regclass,true)
      into v_def;

    if v_def not ilike '%io.deleted_at IS NULL%' then
        raise exception 'FAIL: relationship health does not exclude deleted interactions';
    end if;
end;
$test$;

do $test$
declare v_def text;
begin
    select pg_get_viewdef('public.relationship_warm_intro_candidates'::regclass,true)
      into v_def;

    if v_def not ilike '%relationship_type_code%' then
        raise exception 'FAIL: warm intro view does not use relationship_type_code';
    end if;
end;
$test$;

do $test$
begin
    if exists (
        select 1 from pg_indexes
        where schemaname='public'
          and indexname='ux_external_calendar_links__provider_event'
    ) then
        raise exception 'FAIL: globally scoped external calendar uniqueness still exists';
    end if;

    if not exists (
        select 1 from pg_indexes
        where schemaname='public'
          and indexname='ux_external_calendar_links__event_provider_calendar'
    ) then
        raise exception 'FAIL: event/provider/calendar uniqueness index missing';
    end if;
end;
$test$;

do $test$
begin
    if not exists (
        select 1 from pg_trigger
        where tgname='trg_interactions_communications__validate'
          and not tgisinternal
    ) then
        raise exception 'FAIL: interaction validation trigger missing';
    end if;

    if not exists (
        select 1 from pg_trigger
        where tgname='trg_calendar_events__validate'
          and not tgisinternal
    ) then
        raise exception 'FAIL: calendar validation trigger missing';
    end if;
end;
$test$;

rollback;
