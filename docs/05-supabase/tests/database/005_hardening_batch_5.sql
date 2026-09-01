
begin;

do $test$
declare v_missing text[];
begin
    select array_agg(req.code)
    into v_missing
    from (values
        ('supported_by'),('produced'),('verified_by'),('issued_by'),
        ('attached_to'),('variant_of'),('scheduled_for'),('member_of')
    ) req(code)
    where not exists (
        select 1 from public.relationship_types rt
        where rt.code=req.code and rt.is_active=true
    );

    if v_missing is not null then
        raise exception 'FAIL: missing relationship types %',v_missing;
    end if;
end;
$test$;

do $test$
begin
    if not exists (
        select 1 from information_schema.columns
        where table_schema='public'
          and table_name='resume_content'
          and column_name='parent_resume_content_id'
    ) then
        raise exception 'FAIL: resume content lineage column missing';
    end if;

    if not exists (
        select 1 from pg_trigger
        where tgname='trg_resume_content__validate_lineage'
          and not tgisinternal
    ) then
        raise exception 'FAIL: resume lineage trigger missing';
    end if;
end;
$test$;

do $test$
begin
    if not exists (
        select 1 from pg_trigger
        where tgname='trg_application_material_items__validate_role'
          and not tgisinternal
    ) then
        raise exception 'FAIL: material-role compatibility trigger missing';
    end if;
end;
$test$;

do $test$
declare v_def text;
begin
    select pg_get_viewdef('public.campaign_source_performance_active'::regclass,true)
    into v_def;

    if v_def not ilike '%source_object.deleted_at IS NULL%'
       or v_def not ilike '%campaign_object.deleted_at IS NULL%' then
        raise exception 'FAIL: campaign-source lifecycle filtering missing';
    end if;
end;
$test$;

do $test$
declare r record;
begin
    for r in
        select c.relname,c.relrowsecurity
        from pg_class c
        join pg_namespace n on n.oid=c.relnamespace
        where n.nspname='public'
          and c.relkind='r'
          and c.relname in (
            'objects','projects','tasks','organizations','people','opportunities',
            'applications','interviews_assessments','offers','evidence_achievements',
            'notes_knowledge','documents','interactions_communications','resume_content',
            'resume_profiles','application_material_sets','career_preference_profiles',
            'discovery_sources','saved_searches','notification_rules','calendar_events',
            'career_campaigns'
          )
    loop
        if not r.relrowsecurity then
            raise exception 'FAIL: RLS disabled on public.%',r.relname;
        end if;
    end loop;
end;
$test$;

do $test$
declare r record;
begin
    for r in
        select p.proname,pg_get_functiondef(p.oid) as def
        from pg_proc p
        join pg_namespace n on n.oid=p.pronamespace
        where n.nspname='private'
          and p.prosecdef=true
    loop
        if r.def not ilike '%search_path%'
           or r.def not ilike '%pg_catalog%' then
            raise exception 'FAIL: SECURITY DEFINER function % lacks hardened search_path',r.proname;
        end if;
    end loop;
end;
$test$;

rollback;
