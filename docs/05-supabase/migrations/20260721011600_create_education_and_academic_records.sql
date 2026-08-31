
/*
Migration: 20260721011600_create_education_and_academic_records.sql
Purpose: Create structured education and academic history.
*/
begin;

create table if not exists public.education_academic_records (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    institution_id uuid not null
        references public.organizations(id)
        on update restrict
        on delete restrict,

    education_level text not null
        check (
            education_level in (
                'secondary',
                'certificate',
                'associate',
                'bachelor',
                'master',
                'doctorate',
                'professional',
                'exchange',
                'other'
            )
        ),

    degree_name text
        check (
            degree_name is null
            or length(btrim(degree_name)) > 0
        ),

    field_of_study text
        check (
            field_of_study is null
            or length(btrim(field_of_study)) > 0
        ),

    secondary_field text
        check (
            secondary_field is null
            or length(btrim(secondary_field)) > 0
        ),

    start_date date not null,
    end_date date,

    is_current boolean not null default false,

    graduation_status text not null default 'enrolled'
        check (
            graduation_status in (
                'enrolled',
                'expected',
                'graduated',
                'withdrawn',
                'deferred',
                'incomplete'
            )
        ),

    gpa numeric(6,3)
        check (
            gpa is null
            or gpa >= 0
        ),

    gpa_scale numeric(6,3)
        check (
            gpa_scale is null
            or gpa_scale > 0
        ),

    class_rank integer
        check (
            class_rank is null
            or class_rank > 0
        ),

    class_size integer
        check (
            class_size is null
            or class_size > 0
        ),

    honors jsonb not null default '[]'::jsonb
        check (jsonb_typeof(honors) = 'array'),

    relevant_coursework jsonb not null default '[]'::jsonb
        check (jsonb_typeof(relevant_coursework) = 'array'),

    activities jsonb not null default '[]'::jsonb
        check (jsonb_typeof(activities) = 'array'),

    thesis_title text
        check (
            thesis_title is null
            or length(btrim(thesis_title)) > 0
        ),

    description text,

    is_resume_ready boolean not null default false,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_education_academic_records__date_order
        check (
            end_date is null
            or end_date >= start_date
        ),

    constraint ck_education_academic_records__current_status
        check (
            is_current = false
            or graduation_status in ('enrolled', 'expected')
        ),

    constraint ck_education_academic_records__gpa_scale_pair
        check (
            gpa is null
            or gpa_scale is not null
        ),

    constraint ck_education_academic_records__gpa_not_above_scale
        check (
            gpa is null
            or gpa_scale is null
            or gpa <= gpa_scale
        ),

    constraint ck_education_academic_records__rank_size
        check (
            class_rank is null
            or class_size is null
            or class_rank <= class_size
        )
);

comment on table public.education_academic_records is
'Structured education, degree, GPA, coursework, honors, and academic history records.';

drop trigger if exists trg_education_academic_records__set_updated_at
on public.education_academic_records;

create trigger trg_education_academic_records__set_updated_at
before update on public.education_academic_records
for each row
execute function private.set_updated_at();

create or replace function private.validate_education_academic_record_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_institution_owner uuid;
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

    if v_type <> 'education' then
        raise exception 'Object % must have object_type education.', new.id
            using errcode = '23514';
    end if;

    select owner_user_id
      into v_institution_owner
      from public.objects
     where id = new.institution_id
       and object_type = 'organization'
       and deleted_at is null;

    if not found then
        raise exception 'Institution organization % does not exist or is deleted.',
            new.institution_id
            using errcode = '23503';
    end if;

    if v_institution_owner <> v_owner then
        raise exception 'Education record and institution must have the same owner.'
            using errcode = '42501';
    end if;

    if new.degree_name is not null then
        new.degree_name := btrim(new.degree_name);
    end if;

    if new.field_of_study is not null then
        new.field_of_study := btrim(new.field_of_study);
    end if;

    if new.secondary_field is not null then
        new.secondary_field := btrim(new.secondary_field);
    end if;

    if new.thesis_title is not null then
        new.thesis_title := btrim(new.thesis_title);
    end if;

    return new;
end;
$$;

drop trigger if exists trg_education_academic_records__validate
on public.education_academic_records;

create trigger trg_education_academic_records__validate
before insert or update
on public.education_academic_records
for each row
execute function private.validate_education_academic_record_object();

create index if not exists ix_education_academic_records__institution
    on public.education_academic_records(institution_id, start_date desc);

create index if not exists ix_education_academic_records__timeline
    on public.education_academic_records(start_date desc, end_date desc nulls first);

create index if not exists ix_education_academic_records__current
    on public.education_academic_records(start_date desc)
    where is_current = true;

create index if not exists ix_education_academic_records__level
    on public.education_academic_records(education_level);

create index if not exists ix_education_academic_records__graduation
    on public.education_academic_records(end_date)
    where graduation_status in ('enrolled', 'expected')
      and end_date is not null;

create index if not exists ix_education_academic_records__resume_ready
    on public.education_academic_records(start_date desc)
    where is_resume_ready = true;

alter table public.education_academic_records enable row level security;

create policy education_academic_records_select_owner
on public.education_academic_records
for select to authenticated
using (private.is_object_owner(id));

create policy education_academic_records_insert_owner
on public.education_academic_records
for insert to authenticated
with check (
    private.is_object_owner(id)
    and private.is_object_owner(institution_id)
);

create policy education_academic_records_update_owner
on public.education_academic_records
for update to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and private.is_object_owner(institution_id)
);

create policy education_academic_records_delete_owner
on public.education_academic_records
for delete to authenticated
using (private.is_object_owner(id));

revoke all on table public.education_academic_records from anon;

grant select, insert, update, delete
on table public.education_academic_records
to authenticated;

commit;
