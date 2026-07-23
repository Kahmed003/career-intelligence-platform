/*
===============================================================================
Career OS Database Migration

Migration ID:    20260721010500
Filename:        20260721010500_create_opportunities.sql
Version:         1.0.0
Purpose:         Create the Opportunities domain as a specialized extension of
                 the canonical Object Registry.

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

create table if not exists public.opportunities (
    id uuid
        constraint pk_opportunities
        primary key
        constraint fk_opportunities__id__objects
        references public.objects(id)
        on update restrict
        on delete restrict,

    organization_id uuid
        constraint fk_opportunities__organization_id__organizations
        references public.organizations(id)
        on update restrict
        on delete set null,

    opportunity_type text
        not null
        constraint ck_opportunities__opportunity_type__supported
        check (
            opportunity_type in (
                'internship',
                'job',
                'fellowship',
                'scholarship',
                'research_program',
                'competition',
                'conference',
                'accelerator',
                'grant',
                'networking_program',
                'other'
            )
        ),

    status text
        not null
        default 'discovered'
        constraint ck_opportunities__status__supported
        check (
            status in (
                'discovered',
                'researching',
                'qualified',
                'pursuing',
                'not_pursuing',
                'closed',
                'archived'
            )
        ),

    external_id text
        constraint ck_opportunities__external_id__not_blank
        check (external_id is null or length(btrim(external_id)) > 0),

    source_name text
        constraint ck_opportunities__source_name__not_blank
        check (source_name is null or length(btrim(source_name)) > 0),

    source_url text
        constraint ck_opportunities__source_url__http
        check (
            source_url is null
            or source_url ~* '^https?://'
        ),

    description text,

    location_text text
        constraint ck_opportunities__location_text__not_blank
        check (location_text is null or length(btrim(location_text)) > 0),

    country_code text
        constraint ck_opportunities__country_code__format
        check (
            country_code is null
            or country_code ~ '^[A-Z]{2}$'
        ),

    work_mode text
        not null
        default 'unspecified'
        constraint ck_opportunities__work_mode__supported
        check (
            work_mode in (
                'onsite',
                'hybrid',
                'remote',
                'unspecified'
            )
        ),

    employment_type text
        constraint ck_opportunities__employment_type__supported
        check (
            employment_type is null
            or employment_type in (
                'internship',
                'full_time',
                'part_time',
                'contract',
                'temporary',
                'seasonal',
                'volunteer',
                'program',
                'other'
            )
        ),

    application_open_at timestamptz,

    application_deadline_at timestamptz,

    start_date date,

    end_date date,

    compensation_min numeric(14, 2)
        constraint ck_opportunities__compensation_min__nonnegative
        check (
            compensation_min is null
            or compensation_min >= 0
        ),

    compensation_max numeric(14, 2)
        constraint ck_opportunities__compensation_max__nonnegative
        check (
            compensation_max is null
            or compensation_max >= 0
        ),

    compensation_currency text
        constraint ck_opportunities__compensation_currency__format
        check (
            compensation_currency is null
            or compensation_currency ~ '^[A-Z]{3}$'
        ),

    compensation_period text
        constraint ck_opportunities__compensation_period__supported
        check (
            compensation_period is null
            or compensation_period in (
                'hour',
                'day',
                'week',
                'month',
                'year',
                'stipend',
                'total'
            )
        ),

    visa_sponsorship text
        not null
        default 'unknown'
        constraint ck_opportunities__visa_sponsorship__supported
        check (
            visa_sponsorship in (
                'yes',
                'no',
                'case_by_case',
                'unknown'
            )
        ),

    requires_work_authorization boolean,

    priority smallint
        not null
        default 3
        constraint ck_opportunities__priority__range
        check (priority between 1 and 5),

    fit_score numeric(5, 2)
        constraint ck_opportunities__fit_score__range
        check (
            fit_score is null
            or fit_score between 0 and 100
        ),

    notes text,

    created_at timestamptz
        not null
        default statement_timestamp(),

    updated_at timestamptz
        not null
        default statement_timestamp(),

    constraint ck_opportunities__application_window__ordered
        check (
            application_open_at is null
            or application_deadline_at is null
            or application_deadline_at >= application_open_at
        ),

    constraint ck_opportunities__program_dates__ordered
        check (
            start_date is null
            or end_date is null
            or end_date >= start_date
        ),

    constraint ck_opportunities__compensation_range__ordered
        check (
            compensation_min is null
            or compensation_max is null
            or compensation_max >= compensation_min
        ),

    constraint ck_opportunities__compensation_metadata__consistent
        check (
            (compensation_min is null and compensation_max is null)
            or compensation_currency is not null
        )
);

comment on table public.opportunities is
'Career, academic, and professional opportunities such as jobs, internships, fellowships, scholarships, and research programs.';

comment on column public.opportunities.status is
'Opportunity evaluation state. Application workflow states belong in public.applications.';

comment on column public.opportunities.fit_score is
'Optional user- or model-generated fit score from 0 to 100.';

drop trigger if exists trg_opportunities__set_updated_at
on public.opportunities;

create trigger trg_opportunities__set_updated_at
before update on public.opportunities
for each row
execute function private.set_updated_at();

create or replace function private.validate_opportunity_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
    v_object_type text;
    v_opportunity_owner uuid;
    v_organization_owner uuid;
begin
    select object_type, owner_user_id
    into v_object_type, v_opportunity_owner
    from public.objects
    where id = new.id
      and deleted_at is null;

    if not found then
        raise exception 'Canonical object % does not exist or is deleted.', new.id
            using errcode = '23503';
    end if;

    if v_object_type <> 'opportunity' then
        raise exception 'Object % must have object_type opportunity, not %.',
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

        if v_organization_owner <> v_opportunity_owner then
            raise exception 'Opportunity and organization must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.country_code is not null then
        new.country_code := upper(btrim(new.country_code));
    end if;

    if new.compensation_currency is not null then
        new.compensation_currency := upper(btrim(new.compensation_currency));
    end if;

    if new.external_id is not null then
        new.external_id := btrim(new.external_id);
    end if;

    if new.source_name is not null then
        new.source_name := btrim(new.source_name);
    end if;

    return new;
end;
$function$;

comment on function private.validate_opportunity_object() is
'Validates opportunity object type, same-owner organization linkage, and normalizes structured fields.';

drop trigger if exists trg_opportunities__validate
on public.opportunities;

create trigger trg_opportunities__validate
before insert or update
on public.opportunities
for each row
execute function private.validate_opportunity_object();

create index if not exists ix_opportunities__organization_id
    on public.opportunities(organization_id)
    where organization_id is not null;

create index if not exists ix_opportunities__type_status
    on public.opportunities(opportunity_type, status);

create index if not exists ix_opportunities__deadline
    on public.opportunities(application_deadline_at)
    where application_deadline_at is not null
      and status not in ('closed', 'archived', 'not_pursuing');

create index if not exists ix_opportunities__start_date
    on public.opportunities(start_date)
    where start_date is not null;

create index if not exists ix_opportunities__priority_fit
    on public.opportunities(priority, fit_score desc nulls last);

create index if not exists ix_opportunities__source_external
    on public.opportunities(source_name, external_id)
    where source_name is not null
      and external_id is not null;

create unique index if not exists uq_opportunities__organization_external
    on public.opportunities(organization_id, external_id)
    where organization_id is not null
      and external_id is not null;

create index if not exists ix_opportunities__search__trgm
    on public.opportunities
    using gin (
        (
            coalesce(description, '') || ' ' ||
            coalesce(location_text, '') || ' ' ||
            coalesce(source_name, '') || ' ' ||
            coalesce(external_id, '')
        ) extensions.gin_trgm_ops
    );

alter table public.opportunities enable row level security;

drop policy if exists opportunities_select_owner
on public.opportunities;

create policy opportunities_select_owner
on public.opportunities
for select
to authenticated
using (private.is_object_owner(id));

drop policy if exists opportunities_insert_owner
on public.opportunities;

create policy opportunities_insert_owner
on public.opportunities
for insert
to authenticated
with check (
    private.is_object_owner(id)
    and (
        organization_id is null
        or private.is_object_owner(organization_id)
    )
);

drop policy if exists opportunities_update_owner
on public.opportunities;

create policy opportunities_update_owner
on public.opportunities
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

drop policy if exists opportunities_delete_owner
on public.opportunities;

create policy opportunities_delete_owner
on public.opportunities
for delete
to authenticated
using (private.is_object_owner(id));

revoke all on table public.opportunities from anon;

grant select, insert, update, delete
on table public.opportunities
to authenticated;

commit;
