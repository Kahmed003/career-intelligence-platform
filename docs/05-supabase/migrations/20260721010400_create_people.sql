
/*
===============================================================================
Career OS Database Migration

Migration ID:    20260721010400
Filename:        20260721010400_create_people.sql
Version:         1.0.0
Purpose:         Create the People and Contacts domain as a specialized
                 extension of the canonical Object Registry.

Dependencies:
  - 20260721000400_create_object_registry.sql
  - 20260721000800_create_shared_database_functions.sql
  - 20260721010300_create_organizations.sql

Affected Schemas:
  - public
  - private

Security Considerations:
  - RLS is enabled immediately.
  - Access is inherited through canonical object ownership.
  - Organization references must remain within the same user's ownership scope.
  - Anonymous access is not granted.

Rollback Strategy:
  Dropping the table is destructive. Use a dedicated forward migration after
  dependency and retention analysis.
===============================================================================
*/

begin;

create table if not exists public.people (
    id uuid
        constraint pk_people
        primary key
        constraint fk_people__id__objects
        references public.objects(id)
        on update restrict
        on delete restrict,

    organization_id uuid
        constraint fk_people__organization_id__organizations
        references public.organizations(id)
        on update restrict
        on delete set null,

    first_name text
        constraint ck_people__first_name__not_blank
        check (first_name is null or length(btrim(first_name)) > 0),

    middle_name text
        constraint ck_people__middle_name__not_blank
        check (middle_name is null or length(btrim(middle_name)) > 0),

    last_name text
        constraint ck_people__last_name__not_blank
        check (last_name is null or length(btrim(last_name)) > 0),

    preferred_name text
        constraint ck_people__preferred_name__not_blank
        check (preferred_name is null or length(btrim(preferred_name)) > 0),

    headline text
        constraint ck_people__headline__not_blank
        check (headline is null or length(btrim(headline)) > 0),

    job_title text
        constraint ck_people__job_title__not_blank
        check (job_title is null or length(btrim(job_title)) > 0),

    department text
        constraint ck_people__department__not_blank
        check (department is null or length(btrim(department)) > 0),

    email extensions.citext
        constraint ck_people__email__format
        check (
            email is null
            or email::text ~* '^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$'
        ),

    phone text
        constraint ck_people__phone__not_blank
        check (phone is null or length(btrim(phone)) > 0),

    linkedin_url text
        constraint ck_people__linkedin_url__http
        check (
            linkedin_url is null
            or linkedin_url ~* '^https?://'
        ),

    website_url text
        constraint ck_people__website_url__http
        check (
            website_url is null
            or website_url ~* '^https?://'
        ),

    city text
        constraint ck_people__city__not_blank
        check (city is null or length(btrim(city)) > 0),

    region text
        constraint ck_people__region__not_blank
        check (region is null or length(btrim(region)) > 0),

    country_code text
        constraint ck_people__country_code__format
        check (
            country_code is null
            or country_code ~ '^[A-Z]{2}$'
        ),

    relationship_stage text
        not null
        default 'uncontacted'
        constraint ck_people__relationship_stage__supported
        check (
            relationship_stage in (
                'uncontacted',
                'outreach_sent',
                'connected',
                'active_relationship',
                'dormant',
                'do_not_contact'
            )
        ),

    last_contacted_at timestamptz,

    next_follow_up_at timestamptz,

    notes text,

    created_at timestamptz
        not null
        default statement_timestamp(),

    updated_at timestamptz
        not null
        default statement_timestamp()
);

comment on table public.people is
'Professional contacts and relationship-management attributes for person objects.';

comment on column public.people.organization_id is
'Optional current organization. Historical affiliations should be modeled separately.';

comment on column public.people.relationship_stage is
'User-specific operational stage for outreach and relationship management.';

drop trigger if exists trg_people__set_updated_at
on public.people;

create trigger trg_people__set_updated_at
before update on public.people
for each row
execute function private.set_updated_at();

create or replace function private.validate_person_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
    v_object_type text;
    v_person_owner uuid;
    v_organization_owner uuid;
begin
    select object_type, owner_user_id
    into v_object_type, v_person_owner
    from public.objects
    where id = new.id
      and deleted_at is null;

    if not found then
        raise exception 'Canonical object % does not exist or is deleted.', new.id
            using errcode = '23503';
    end if;

    if v_object_type <> 'person' then
        raise exception 'Object % must have object_type person, not %.',
            new.id,
            v_object_type
            using errcode = '23514';
    end if;

    if new.organization_id is not null then
        select o.owner_user_id
        into v_organization_owner
        from public.objects o
        join public.organizations org
          on org.id = o.id
        where org.id = new.organization_id
          and o.deleted_at is null;

        if not found then
            raise exception 'Organization % does not exist or is deleted.',
                new.organization_id
                using errcode = '23503';
        end if;

        if v_organization_owner <> v_person_owner then
            raise exception 'Person and organization must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.email is not null then
        new.email := lower(btrim(new.email::text))::extensions.citext;
    end if;

    if new.country_code is not null then
        new.country_code := upper(btrim(new.country_code));
    end if;

    if new.first_name is not null then
        new.first_name := btrim(new.first_name);
    end if;

    if new.middle_name is not null then
        new.middle_name := btrim(new.middle_name);
    end if;

    if new.last_name is not null then
        new.last_name := btrim(new.last_name);
    end if;

    if new.preferred_name is not null then
        new.preferred_name := btrim(new.preferred_name);
    end if;

    return new;
end;
$function$;

comment on function private.validate_person_object() is
'Validates person object type, same-owner organization affiliation, and normalizes identity fields.';

drop trigger if exists trg_people__validate
on public.people;

create trigger trg_people__validate
before insert or update
on public.people
for each row
execute function private.validate_person_object();

create index if not exists ix_people__organization_id
    on public.people(organization_id)
    where organization_id is not null;

create index if not exists ix_people__relationship_stage
    on public.people(relationship_stage);

create index if not exists ix_people__next_follow_up_at
    on public.people(next_follow_up_at)
    where next_follow_up_at is not null
      and relationship_stage <> 'do_not_contact';

create index if not exists ix_people__last_contacted_at
    on public.people(last_contacted_at desc)
    where last_contacted_at is not null;

create index if not exists ix_people__email
    on public.people(email)
    where email is not null;

create index if not exists ix_people__name_search__trgm
    on public.people
    using gin (
        (
            coalesce(first_name, '') || ' ' ||
            coalesce(middle_name, '') || ' ' ||
            coalesce(last_name, '') || ' ' ||
            coalesce(preferred_name, '') || ' ' ||
            coalesce(job_title, '') || ' ' ||
            coalesce(headline, '')
        ) extensions.gin_trgm_ops
    );

alter table public.people enable row level security;

drop policy if exists people_select_owner
on public.people;

create policy people_select_owner
on public.people
for select
to authenticated
using (private.is_object_owner(id));

drop policy if exists people_insert_owner
on public.people;

create policy people_insert_owner
on public.people
for insert
to authenticated
with check (
    private.is_object_owner(id)
    and (
        organization_id is null
        or private.is_object_owner(organization_id)
    )
);

drop policy if exists people_update_owner
on public.people;

create policy people_update_owner
on public.people
for update
to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and (
        organization_id is null
        or private.is_object_owner(organization_id)
    )
);

drop policy if exists people_delete_owner
on public.people;

create policy people_delete_owner
on public.people
for delete
to authenticated
using (private.is_object_owner(id));

revoke all on table public.people from anon;

grant select, insert, update, delete
on table public.people
to authenticated;

commit;
