
/*
Career OS regression tests — Hardening Batch 1.

Run against an isolated Supabase test database after all migrations.
The assertions intentionally inspect schema invariants without depending on
production user data.
*/

begin;

do $test$
declare
    v_def text;
begin
    select pg_catalog.pg_get_constraintdef(c.oid)
      into v_def
      from pg_catalog.pg_constraint c
      join pg_catalog.pg_class t on t.oid = c.conrelid
      join pg_catalog.pg_namespace n on n.oid = t.relnamespace
     where n.nspname = 'public'
       and t.relname = 'objects'
       and c.conname = 'ck_objects__object_type__supported';

    if v_def is null then
        raise exception 'FAIL: object type constraint missing';
    end if;

    if v_def not like '%calendar_event%'
       or v_def not like '%career_campaign%'
       or v_def not like '%notification_rule%'
       or v_def not like '%saved_search%' then
        raise exception 'FAIL: object type constraint lacks implemented types';
    end if;
end;
$test$;

do $test$
begin
    if not exists (
        select 1
        from pg_catalog.pg_trigger
        where tgname = 'trg_projects__owner_scoped_project_code'
          and not tgisinternal
    ) then
        raise exception 'FAIL: project-code owner uniqueness trigger missing';
    end if;

    if not exists (
        select 1
        from pg_catalog.pg_trigger
        where tgname = 'trg_organizations__owner_scoped_primary_domain'
          and not tgisinternal
    ) then
        raise exception 'FAIL: organization-domain owner uniqueness trigger missing';
    end if;

    if not exists (
        select 1
        from pg_catalog.pg_trigger
        where tgname = 'trg_tasks__validate_hierarchy'
          and not tgisinternal
    ) then
        raise exception 'FAIL: task hierarchy validation trigger missing';
    end if;
end;
$test$;

rollback;
