
/*
Migration: 20260721011000_create_skills_and_competencies.sql
Purpose: Create the Skills and Competencies domain.
*/
begin;

create table if not exists public.skills_competencies (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    skill_category text not null
        check (
            skill_category in (
                'programming',
                'data',
                'quantitative',
                'engineering',
                'energy',
                'finance',
                'consulting',
                'research',
                'communication',
                'leadership',
                'project_management',
                'language',
                'other'
            )
        ),

    proficiency_level text not null default 'beginner'
        check (
            proficiency_level in (
                'awareness',
                'beginner',
                'intermediate',
                'advanced',
                'expert'
            )
        ),

    target_proficiency_level text
        check (
            target_proficiency_level is null
            or target_proficiency_level in (
                'awareness',
                'beginner',
                'intermediate',
                'advanced',
                'expert'
            )
        ),

    development_status text not null default 'active'
        check (
            development_status in (
                'active',
                'maintaining',
                'learning',
                'planned',
                'paused',
                'retired'
            )
        ),

    years_experience numeric(5,2)
        check (
            years_experience is null
            or years_experience >= 0
        ),

    last_used_at timestamptz,

    evidence_status text not null default 'none'
        check (
            evidence_status in (
                'none',
                'self_reported',
                'project_evidence',
                'work_evidence',
                'academic_evidence',
                'certified'
            )
        ),

    evidence_summary text
        check (
            evidence_summary is null
            or length(btrim(evidence_summary)) > 0
        ),

    certification_name text
        check (
            certification_name is null
            or length(btrim(certification_name)) > 0
        ),

    certification_expires_at date,

    notes text,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_skills_competencies__certification_expiry_requires_name
        check (
            certification_expires_at is null
            or certification_name is not null
        )
);

comment on table public.skills_competencies is
'Structured inventory of user skills, proficiency, development targets, and evidence readiness.';

drop trigger if exists trg_skills_competencies__set_updated_at
on public.skills_competencies;

create trigger trg_skills_competencies__set_updated_at
before update on public.skills_competencies
for each row
execute function private.set_updated_at();

create or replace function private.validate_skill_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
begin
    select object_type
      into v_type
      from public.objects
     where id = new.id
       and deleted_at is null;

    if not found then
        raise exception 'Canonical object % does not exist or is deleted.', new.id
            using errcode = '23503';
    end if;

    if v_type <> 'skill' then
        raise exception 'Object % must have object_type skill.', new.id
            using errcode = '23514';
    end if;

    if new.evidence_summary is not null then
        new.evidence_summary := btrim(new.evidence_summary);
    end if;

    if new.certification_name is not null then
        new.certification_name := btrim(new.certification_name);
    end if;

    return new;
end;
$$;

drop trigger if exists trg_skills_competencies__validate
on public.skills_competencies;

create trigger trg_skills_competencies__validate
before insert or update
on public.skills_competencies
for each row
execute function private.validate_skill_object();

create index if not exists ix_skills_competencies__category
    on public.skills_competencies(skill_category);

create index if not exists ix_skills_competencies__proficiency
    on public.skills_competencies(proficiency_level);

create index if not exists ix_skills_competencies__development_status
    on public.skills_competencies(development_status);

create index if not exists ix_skills_competencies__evidence_status
    on public.skills_competencies(evidence_status);

create index if not exists ix_skills_competencies__certification_expiry
    on public.skills_competencies(certification_expires_at)
    where certification_expires_at is not null;

create index if not exists ix_skills_competencies__last_used
    on public.skills_competencies(last_used_at desc)
    where last_used_at is not null;

alter table public.skills_competencies enable row level security;

create policy skills_competencies_select_owner
on public.skills_competencies
for select to authenticated
using (private.is_object_owner(id));

create policy skills_competencies_insert_owner
on public.skills_competencies
for insert to authenticated
with check (private.is_object_owner(id));

create policy skills_competencies_update_owner
on public.skills_competencies
for update to authenticated
using (private.is_object_owner(id))
with check (private.is_object_owner(id));

create policy skills_competencies_delete_owner
on public.skills_competencies
for delete to authenticated
using (private.is_object_owner(id));

revoke all on table public.skills_competencies from anon;
grant select, insert, update, delete
on table public.skills_competencies
to authenticated;

commit;
