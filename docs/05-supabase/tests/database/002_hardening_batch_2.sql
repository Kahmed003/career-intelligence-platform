
/* Career OS regression tests — Hardening Batch 2 */
begin;

do $test$
declare v_def text;
begin
    select pg_get_viewdef('public.opportunity_preference_evaluations'::regclass,true)
      into v_def;

    if v_def ilike '%op.industry%' then
        raise exception 'FAIL: opportunity matching still references op.industry';
    end if;

    if v_def not ilike '%org.industry%' then
        raise exception 'FAIL: opportunity matching does not reference organization industry';
    end if;
end;
$test$;

do $test$
declare r record;
begin
    for r in
        select p.oid, p.proname, pg_get_functiondef(p.oid) as definition
        from pg_proc p
        join pg_namespace n on n.oid=p.pronamespace
        where n.nspname='private'
          and p.proname in (
              'is_object_owner','assert_object_owner','touch_object','soft_delete_object'
          )
    loop
        if r.definition not ilike '%SECURITY DEFINER%' then
            raise exception 'FAIL: % is not SECURITY DEFINER',r.proname;
        end if;
        if r.definition not ilike '%search_path TO ''pg_catalog'', ''public''%'
           and r.definition not ilike '%search_path = pg_catalog, public%' then
            raise exception 'FAIL: % search_path not hardened',r.proname;
        end if;
    end loop;
end;
$test$;

do $test$
begin
    if not exists (
        select 1 from pg_trigger
        where tgname='trg_resume_profiles__single_default' and not tgisinternal
    ) then raise exception 'FAIL: resume default trigger missing'; end if;

    if not exists (
        select 1 from pg_trigger
        where tgname='trg_career_preference_profiles__single_default' and not tgisinternal
    ) then raise exception 'FAIL: preference default trigger missing'; end if;
end;
$test$;

rollback;
