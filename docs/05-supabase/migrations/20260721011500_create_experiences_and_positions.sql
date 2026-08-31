
/*
Migration: 20260721011500_create_experiences_and_positions.sql
Purpose: Create structured career experience and position history.
*/
begin;

create table if not exists public.experiences_positions (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    organization_id uuid
        references public.organizations(id)
        on update restrict
        on delete set null,

    experience_type text not null
        check (
            experience_type in (
                'internship',
                'employment',
                'research',
                'teaching',
                'leadership',
                'volunteer',
                'fellowship',
                'campus_role',
                'consulting_project',
                'independent_project',
                'other'
            )
        ),

    employment_type text
        check (
            employment_type is null
            or employment_type in (
                'full_time',
                'part_time',
                'contract',
                'temporary',
                'seasonal',
                'volunteer',
                'fellowship',
                'academic',
                'project_based',
                'other'
            )
        ),

    title text not null
        check (length(btrim(title)) > 0),

    department text
        check (
            department is null
            or length(btrim(department)) > 0
        ),

    location_text text
        check (
            location_text is null
            or length(btrim(location_text)) > 0
        ),

    country_code text
        check (
            country_code is null
            or country_code ~ '^[A-Z]{2}$'
        ),

    work_mode text not null default 'unspecified'
        check (
            work_mode in (
                'onsite',
                'hybrid',
                'remote',
                'unspecified'
            )
        ),

    start_date date not null,
    end_date date,

    is_current boolean not null default false,

    hours_per_week numeric(5,2)
        check (
            hours_per_week is null
            or hours_per_week between 0 and 168
        ),

    summary text
        check (
            summary is null
            or length(btrim(summary)) > 0
        ),

    responsibilities text,

    achievements jsonb not null default '[]'::jsonb
        check (
            jsonb_typeof(achievements) in ('array', 'object')
        ),

    is_resume_ready boolean not null default false,
    is_profile_ready boolean not null default false,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_experiences_positions__date_order
        check (
            end_date is null
            or end_date >= start_date
        ),

    constraint ck_experiences_positions__current_end_date
        check (
            (is_current = true and end_date is null)
            or
            (is_current = false and end_date is not null)
        )
);

comment on table public.experiences_positions is
'Structured career experience, employment, research, teaching, leadership, and volunteer history.';

drop trigger if exists trg_experiences_positions__set_updated_at
on public.experiences_positions;

create trigger trg_experiences_positions__set_updated_at
before update on public.experiences_positions
for each row
execute function private.set_updated_at();

create or replace function private.validate_experience_position_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_org_owner uuid;
begin
    select object_type, owner_user_id
      into v_type, v_owner
      from public.objects
     where id = new.id
       and deleted_at is null;

    if not found then
        raise exception 'Canonical object % does not exist or is deleted.', new.id
            using errcode = '23503';
    end if;

    if v_type <> 'experience' then
        raise exception 'Object % must have object_type experience.', new.id
            using errcode = '23514';
    end if;

    if new.organization_id is not null then
        select owner_user_id
          into v_org_owner
          from public.objects
         where id = new.organization_id
           and object_type = 'organization'
           and deleted_at is null;

        if not found then
            raise exception 'Organization % does not exist or is deleted.',
                new.organization_id
                using errcode = '23503';
        end if;

        if v_org_owner <> v_owner then
            raise exception 'Experience and organization must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    new.title := btrim(new.title);

    if new.department is not null then
        new.department := btrim(new.department);
    end if;

    if new.location_text is not null then
        new.location_text := btrim(new.location_text);
    end if;

    if new.country_code is not null then
        new.country_code := upper(btrim(new.country_code));
    end if;

    if new.summary is not null then
        new.summary := btrim(new.summary);
    end if;

    return new;
end;
$$;

drop trigger if exists trg_experiences_positions__validate
on public.experiences_positions;

create trigger trg_experiences_positions__validate
before insert or update
on public.experiences_positions
for each row
execute function private.validate_experience_position_object();

create index if not exists ix_experiences_positions__organization
    on public.experiences_positions(organization_id, start_date desc)
    where organization_id is not null;

create index if not exists ix_experiences_positions__timeline
    on public.experiences_positions(start_date desc, end_date desc nulls first);

create index if not exists ix_experiences_positions__current
    on public.experiences_positions(start_date desc)
    where is_current = true;

create index if not exists ix_experiences_positions__type
    on public.experiences_positions(experience_type);

create index if not exists ix_experiences_positions__resume_ready
    on public.experiences_positions(start_date desc)
    where is_resume_ready = true;

create index if not exists ix_experiences_positions__profile_ready
    on public.experiences_positions(start_date desc)
    where is_profile_ready = true;

create index if not exists ix_experiences_positions__country_mode
    on public.experiences_positions(country_code, work_mode)
    where country_code is not null;

alter table public.experiences_positions enable row level security;

create policy experiences_positions_select_owner
on public.experiences_positions
for select to authenticated
using (private.is_object_owner(id));

create policy experiences_positions_insert_owner
on public.experiences_positions
for insert to authenticated
with check (
    private.is_object_owner(id)
    and (
        organization_id is null
        or private.is_object_owner(organization_id)
    )
);

create policy experiences_positions_update_owner
on public.experiences_positions
for update to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and (
        organization_id is null
        or private.is_object_owner(organization_id)
    )
);

create policy experiences_positions_delete_owner
on public.experiences_positions
for delete to authenticated
using (private.is_object_owner(id));

revoke all on table public.experiences_positions from anon;

grant select, insert, update, delete
on table public.experiences_positions
to authenticated;

commit;
