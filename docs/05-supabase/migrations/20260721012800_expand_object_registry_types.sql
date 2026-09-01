
/*
Migration ID: 20260721012800
Purpose: Expand the Object Registry type constraint for implemented first-class domains.
Dependencies: 20260721012700_create_campaign_performance_intelligence.sql
*/
begin;

do $migration$
declare
    v_constraint record;
begin
    /* Remove only CHECK constraints on public.objects that reference object_type. */
    for v_constraint in
        select c.conname
        from pg_catalog.pg_constraint c
        join pg_catalog.pg_class t on t.oid = c.conrelid
        join pg_catalog.pg_namespace n on n.oid = t.relnamespace
        where n.nspname = 'public'
          and t.relname = 'objects'
          and c.contype = 'c'
          and pg_catalog.pg_get_constraintdef(c.oid) ilike '%object_type%'
    loop
        execute format(
            'alter table public.objects drop constraint %I',
            v_constraint.conname
        );
    end loop;
end;
$migration$;

alter table public.objects
add constraint ck_objects__object_type__supported
check (
    object_type in (
        'project',
        'task',
        'person',
        'organization',
        'opportunity',
        'application',
        'knowledge',
        'evidence',
        'recommendation',
        'interview_assessment',
        'offer',
        'goal_milestone',
        'skill',
        'evidence_achievement',
        'note',
        'document',
        'interaction',
        'experience',
        'education',
        'resume_content',
        'resume_profile',
        'material_set',
        'career_preference_profile',
        'discovery_source',
        'saved_search',
        'notification_rule',
        'calendar_event',
        'career_campaign'
    )
);

comment on constraint ck_objects__object_type__supported on public.objects is
'Supported first-class Career OS object types implemented through migration 20260721012700.';

commit;
