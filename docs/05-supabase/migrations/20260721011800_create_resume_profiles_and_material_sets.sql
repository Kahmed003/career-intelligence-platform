
/*
Migration: 20260721011800_create_resume_profiles_and_material_sets.sql
Purpose: Create reusable resume configurations and application material packages.
*/
begin;

create table if not exists public.resume_profiles (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    profile_type text not null default 'resume'
        check (
            profile_type in (
                'resume',
                'cv',
                'one_page_resume',
                'two_page_resume',
                'academic_cv',
                'other'
            )
        ),

    status text not null default 'draft'
        check (
            status in (
                'draft',
                'active',
                'archived'
            )
        ),

    target_function text,
    target_role_family text,
    target_industry text,
    target_location text,

    max_pages smallint
        check (
            max_pages is null
            or max_pages between 1 and 20
        ),

    is_default boolean not null default false,

    summary_content_id uuid
        references public.resume_content(id)
        on update restrict
        on delete set null,

    resume_document_id uuid
        references public.documents(id)
        on update restrict
        on delete set null,

    notes text,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp()
);

create table if not exists public.resume_profile_items (
    resume_profile_id uuid not null
        references public.resume_profiles(id)
        on update restrict
        on delete cascade,

    object_id uuid not null
        references public.objects(id)
        on update restrict
        on delete restrict,

    section_type text not null
        check (
            section_type in (
                'summary',
                'education',
                'experience',
                'projects',
                'research',
                'leadership',
                'skills',
                'awards',
                'publications',
                'other'
            )
        ),

    position integer not null default 0
        check (position >= 0),

    is_visible boolean not null default true,

    custom_label text,

    metadata jsonb not null default '{}'::jsonb
        check (jsonb_typeof(metadata) = 'object'),

    primary key (resume_profile_id, object_id, section_type)
);

create table if not exists public.application_material_sets (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    application_id uuid
        references public.applications(id)
        on update restrict
        on delete set null,

    opportunity_id uuid
        references public.opportunities(id)
        on update restrict
        on delete set null,

    resume_profile_id uuid
        references public.resume_profiles(id)
        on update restrict
        on delete set null,

    status text not null default 'draft'
        check (
            status in (
                'draft',
                'ready',
                'submitted',
                'archived'
            )
        ),

    label text not null
        check (length(btrim(label)) > 0),

    notes text,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_application_material_sets__submitted_requires_application
        check (
            status <> 'submitted'
            or application_id is not null
        )
);

create table if not exists public.application_material_items (
    material_set_id uuid not null
        references public.application_material_sets(id)
        on update restrict
        on delete cascade,

    object_id uuid not null
        references public.objects(id)
        on update restrict
        on delete restrict,

    material_role text not null
        check (
            material_role in (
                'resume',
                'cover_letter',
                'transcript',
                'writing_sample',
                'portfolio',
                'certificate',
                'reference',
                'application_response',
                'supporting_document',
                'other'
            )
        ),

    position integer not null default 0
        check (position >= 0),

    is_required boolean not null default false,
    is_submitted boolean not null default false,
    submitted_at timestamptz,

    metadata jsonb not null default '{}'::jsonb
        check (jsonb_typeof(metadata) = 'object'),

    primary key (material_set_id, object_id, material_role),

    constraint ck_application_material_items__submission_time
        check (
            submitted_at is null
            or is_submitted = true
        )
);

drop trigger if exists trg_resume_profiles__set_updated_at
on public.resume_profiles;

create trigger trg_resume_profiles__set_updated_at
before update on public.resume_profiles
for each row
execute function private.set_updated_at();

drop trigger if exists trg_application_material_sets__set_updated_at
on public.application_material_sets;

create trigger trg_application_material_sets__set_updated_at
before update on public.application_material_sets
for each row
execute function private.set_updated_at();

create or replace function private.validate_resume_profile()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_linked_owner uuid;
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

    if v_type <> 'resume_profile' then
        raise exception 'Object % must have object_type resume_profile.', new.id
            using errcode = '23514';
    end if;

    if new.summary_content_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.summary_content_id
           and object_type = 'resume_content'
           and deleted_at is null;

        if not found then
            raise exception 'Summary content % does not exist or is deleted.',
                new.summary_content_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Resume profile and summary content must share owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.resume_document_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.resume_document_id
           and object_type = 'document'
           and deleted_at is null;

        if not found then
            raise exception 'Resume document % does not exist or is deleted.',
                new.resume_document_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Resume profile and resume document must share owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.target_function is not null then
        new.target_function := lower(btrim(new.target_function));
    end if;

    if new.target_role_family is not null then
        new.target_role_family := btrim(new.target_role_family);
    end if;

    if new.target_industry is not null then
        new.target_industry := btrim(new.target_industry);
    end if;

    if new.target_location is not null then
        new.target_location := btrim(new.target_location);
    end if;

    return new;
end;
$$;

drop trigger if exists trg_resume_profiles__validate
on public.resume_profiles;

create trigger trg_resume_profiles__validate
before insert or update on public.resume_profiles
for each row
execute function private.validate_resume_profile();

create or replace function private.validate_resume_profile_item()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_profile_owner uuid;
    v_object_owner uuid;
    v_object_type text;
begin
    select o.owner_user_id
      into v_profile_owner
      from public.objects o
      join public.resume_profiles rp on rp.id = o.id
     where rp.id = new.resume_profile_id
       and o.deleted_at is null;

    if not found then
        raise exception 'Resume profile % does not exist or is deleted.',
            new.resume_profile_id
            using errcode = '23503';
    end if;

    select owner_user_id, object_type
      into v_object_owner, v_object_type
      from public.objects
     where id = new.object_id
       and deleted_at is null;

    if not found then
        raise exception 'Profile item object % does not exist or is deleted.',
            new.object_id
            using errcode = '23503';
    end if;

    if v_profile_owner <> v_object_owner then
        raise exception 'Resume profile and item must share owner.'
            using errcode = '42501';
    end if;

    if v_object_type not in (
        'resume_content',
        'experience',
        'education',
        'project',
        'skill',
        'evidence_achievement',
        'document'
    ) then
        raise exception 'Object type % cannot be used as a resume profile item.',
            v_object_type
            using errcode = '23514';
    end if;

    if new.custom_label is not null then
        new.custom_label := btrim(new.custom_label);
        if new.custom_label = '' then
            new.custom_label := null;
        end if;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_resume_profile_items__validate
on public.resume_profile_items;

create trigger trg_resume_profile_items__validate
before insert or update on public.resume_profile_items
for each row
execute function private.validate_resume_profile_item();

create or replace function private.validate_application_material_set()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_linked_owner uuid;
    v_application_opportunity uuid;
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

    if v_type <> 'material_set' then
        raise exception 'Object % must have object_type material_set.', new.id
            using errcode = '23514';
    end if;

    if new.application_id is not null then
        select o.owner_user_id, a.opportunity_id
          into v_linked_owner, v_application_opportunity
          from public.objects o
          join public.applications a on a.id = o.id
         where a.id = new.application_id
           and o.deleted_at is null;

        if not found then
            raise exception 'Application % does not exist or is deleted.',
                new.application_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Material set and application must share owner.'
                using errcode = '42501';
        end if;

        if new.opportunity_id is null then
            new.opportunity_id := v_application_opportunity;
        elsif new.opportunity_id <> v_application_opportunity then
            raise exception 'Material set opportunity must match application opportunity.'
                using errcode = '23514';
        end if;
    end if;

    if new.opportunity_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.opportunity_id
           and object_type = 'opportunity'
           and deleted_at is null;

        if not found then
            raise exception 'Opportunity % does not exist or is deleted.',
                new.opportunity_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Material set and opportunity must share owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.resume_profile_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.resume_profile_id
           and object_type = 'resume_profile'
           and deleted_at is null;

        if not found then
            raise exception 'Resume profile % does not exist or is deleted.',
                new.resume_profile_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Material set and resume profile must share owner.'
                using errcode = '42501';
        end if;
    end if;

    new.label := btrim(new.label);
    return new;
end;
$$;

drop trigger if exists trg_application_material_sets__validate
on public.application_material_sets;

create trigger trg_application_material_sets__validate
before insert or update on public.application_material_sets
for each row
execute function private.validate_application_material_set();

create or replace function private.validate_application_material_item()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_set_owner uuid;
    v_object_owner uuid;
    v_object_type text;
begin
    select o.owner_user_id
      into v_set_owner
      from public.objects o
      join public.application_material_sets s on s.id = o.id
     where s.id = new.material_set_id
       and o.deleted_at is null;

    if not found then
        raise exception 'Material set % does not exist or is deleted.',
            new.material_set_id
            using errcode = '23503';
    end if;

    select owner_user_id, object_type
      into v_object_owner, v_object_type
      from public.objects
     where id = new.object_id
       and deleted_at is null;

    if not found then
        raise exception 'Material object % does not exist or is deleted.',
            new.object_id
            using errcode = '23503';
    end if;

    if v_set_owner <> v_object_owner then
        raise exception 'Material set and material item must share owner.'
            using errcode = '42501';
    end if;

    if v_object_type not in ('document', 'resume_content') then
        raise exception 'Material item must be document or resume_content, not %.',
            v_object_type
            using errcode = '23514';
    end if;

    return new;
end;
$$;

drop trigger if exists trg_application_material_items__validate
on public.application_material_items;

create trigger trg_application_material_items__validate
before insert or update on public.application_material_items
for each row
execute function private.validate_application_material_item();

create index if not exists ix_resume_profiles__active_target
    on public.resume_profiles(target_function, target_role_family)
    where status = 'active';

create index if not exists ix_resume_profiles__default
    on public.resume_profiles(target_function)
    where is_default = true
      and status = 'active';

create index if not exists ix_resume_profile_items__render_order
    on public.resume_profile_items(resume_profile_id, section_type, position);

create index if not exists ix_resume_profile_items__object
    on public.resume_profile_items(object_id);

create index if not exists ix_application_material_sets__application
    on public.application_material_sets(application_id, created_at desc)
    where application_id is not null;

create index if not exists ix_application_material_sets__opportunity
    on public.application_material_sets(opportunity_id, created_at desc)
    where opportunity_id is not null;

create index if not exists ix_application_material_sets__status
    on public.application_material_sets(status, updated_at desc);

create index if not exists ix_application_material_items__set_order
    on public.application_material_items(material_set_id, position);

create index if not exists ix_application_material_items__missing_required
    on public.application_material_items(material_set_id, material_role)
    where is_required = true
      and is_submitted = false;

alter table public.resume_profiles enable row level security;
alter table public.resume_profile_items enable row level security;
alter table public.application_material_sets enable row level security;
alter table public.application_material_items enable row level security;

create policy resume_profiles_owner_all
on public.resume_profiles
for all to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and (summary_content_id is null or private.is_object_owner(summary_content_id))
    and (resume_document_id is null or private.is_object_owner(resume_document_id))
);

create policy resume_profile_items_owner_all
on public.resume_profile_items
for all to authenticated
using (
    private.is_object_owner(resume_profile_id)
    and private.is_object_owner(object_id)
)
with check (
    private.is_object_owner(resume_profile_id)
    and private.is_object_owner(object_id)
);

create policy application_material_sets_owner_all
on public.application_material_sets
for all to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and (application_id is null or private.is_object_owner(application_id))
    and (opportunity_id is null or private.is_object_owner(opportunity_id))
    and (resume_profile_id is null or private.is_object_owner(resume_profile_id))
);

create policy application_material_items_owner_all
on public.application_material_items
for all to authenticated
using (
    private.is_object_owner(material_set_id)
    and private.is_object_owner(object_id)
)
with check (
    private.is_object_owner(material_set_id)
    and private.is_object_owner(object_id)
);

revoke all on table public.resume_profiles from anon;
revoke all on table public.resume_profile_items from anon;
revoke all on table public.application_material_sets from anon;
revoke all on table public.application_material_items from anon;

grant select, insert, update, delete on public.resume_profiles to authenticated;
grant select, insert, update, delete on public.resume_profile_items to authenticated;
grant select, insert, update, delete on public.application_material_sets to authenticated;
grant select, insert, update, delete on public.application_material_items to authenticated;

commit;
