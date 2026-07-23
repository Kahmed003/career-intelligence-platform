
/*
===============================================================================
Career OS Database Migration

Migration ID:    20260721010300
Filename:        20260721010300_create_organizations.sql
Version:         1.0.0
Purpose:         Create the Organizations domain as a specialized extension of
                 the canonical Object Registry.

Dependencies:
  - 20260721000400_create_object_registry.sql
  - 20260721000800_create_shared_database_functions.sql

Affected Schemas:
  - public
  - private

Security Considerations:
  - RLS is enabled immediately.
  - Access is inherited through canonical object ownership.
  - Anonymous access is not granted.

Rollback Strategy:
  Dropping the table is destructive. Use a dedicated forward migration after
  dependency and retention analysis.
===============================================================================
*/

begin;

create table if not exists public.organizations (
    id uuid
        constraint pk_organizations
        primary key
        constraint fk_organizations__id__objects
        references public.objects(id)
        on update restrict
        on delete restrict,

    legal_name text
        constraint ck_organizations__legal_name__not_blank
        check (legal_name is null or length(btrim(legal_name)) > 0),

    organization_type text
        not null
        default 'company'
        constraint ck_organizations__organization_type__supported
        check (
            organization_type in (
                'company',
                'university',
                'investment_firm',
                'research_institution',
                'nonprofit',
                'government',
                'professional_association',
                'recruiting_firm',
                'other'
            )
        ),

    website_url text
        constraint ck_organizations__website_url__http
        check (
            website_url is null
            or website_url ~* '^https?://'
        ),

    primary_domain extensions.citext
        constraint ck_organizations__primary_domain__format
        check (
            primary_domain is null
            or primary_domain::text ~ '^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$'
        ),

    industry text
        constraint ck_organizations__industry__not_blank
        check (industry is null or length(btrim(industry)) > 0),

    description text,

    city text
        constraint ck_organizations__city__not_blank
        check (city is null or length(btrim(city)) > 0),

    region text
        constraint ck_organizations__region__not_blank
        check (region is null or length(btrim(region)) > 0),

    country_code text
        constraint ck_organizations__country_code__format
        check (
            country_code is null
            or country_code ~ '^[A-Z]{2}$'
        ),

    linkedin_url text
        constraint ck_organizations__linkedin_url__http
        check (
            linkedin_url is null
            or linkedin_url ~* '^https?://'
        ),

    founded_year smallint
        constraint ck_organizations__founded_year__range
        check (
            founded_year is null
            or founded_year between 1000 and 2200
        ),

    employee_count integer
        constraint ck_organizations__employee_count__nonnegative
        check (
            employee_count is null
            or employee_count >= 0
        ),

    created_at timestamptz
        not null
        default statement_timestamp(),

    updated_at timestamptz
        not null
        default statement_timestamp()
);

comment on table public.organizations is
'Domain-specific attributes for organization objects such as companies, universities, investors, and research institutions.';

comment on column public.organizations.id is
'UUID shared one-to-one with a canonical public.objects row whose object_type is organization.';

comment on column public.organizations.primary_domain is
'Normalized primary web or email domain used for matching and deduplication.';

comment on column public.organizations.organization_type is
'Stable machine-readable institutional category.';

drop trigger if exists trg_organizations__set_updated_at
on public.organizations;

create trigger trg_organizations__set_updated_at
before update on public.organizations
for each row
execute function private.set_updated_at();

create or replace function private.validate_organization_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
    v_object_type text;
begin
    select object_type
    into v_object_type
    from public.objects
    where id = new.id
      and deleted_at is null;

    if not found then
        raise exception 'Canonical object % does not exist or is deleted.', new.id
            using errcode = '23503';
    end if;

    if v_object_type <> 'organization' then
        raise exception 'Object % must have object_type organization, not %.',
            new.id,
            v_object_type
            using errcode = '23514';
    end if;

    if new.primary_domain is not null then
        new.primary_domain := lower(btrim(new.primary_domain::text))::extensions.citext;
    end if;

    if new.country_code is not null then
        new.country_code := upper(btrim(new.country_code));
    end if;

    return new;
end;
$function$;

comment on function private.validate_organization_object() is
'Validates the canonical organization object and normalizes domain and country values.';

drop trigger if exists trg_organizations__validate
on public.organizations;

create trigger trg_organizations__validate
before insert or update
on public.organizations
for each row
execute function private.validate_organization_object();

create unique index if not exists uq_organizations__primary_domain__active
    on public.organizations(primary_domain)
    where primary_domain is not null;

create index if not exists ix_organizations__organization_type
    on public.organizations(organization_type);

create index if not exists ix_organizations__country_code
    on public.organizations(country_code)
    where country_code is not null;

create index if not exists ix_organizations__industry__lower
    on public.organizations(lower(industry))
    where industry is not null;

create index if not exists ix_organizations__legal_name__trgm
    on public.organizations
    using gin(legal_name extensions.gin_trgm_ops)
    where legal_name is not null;

alter table public.organizations enable row level security;

drop policy if exists organizations_select_owner
on public.organizations;

create policy organizations_select_owner
on public.organizations
for select
to authenticated
using (private.is_object_owner(id));

drop policy if exists organizations_insert_owner
on public.organizations;

create policy organizations_insert_owner
on public.organizations
for insert
to authenticated
with check (private.is_object_owner(id));

drop policy if exists organizations_update_owner
on public.organizations;

create policy organizations_update_owner
on public.organizations
for update
to authenticated
using (private.is_object_owner(id))
with check (private.is_object_owner(id));

drop policy if exists organizations_delete_owner
on public.organizations;

create policy organizations_delete_owner
on public.organizations
for delete
to authenticated
using (private.is_object_owner(id));

revoke all on table public.organizations from anon;
grant select, insert, update, delete
on table public.organizations
to authenticated;

commit;
