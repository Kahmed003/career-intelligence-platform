\
/*
Migration: 20260721010600_create_applications.sql
Purpose: Create the Applications domain.
*/
begin;

create table if not exists public.applications (
    id uuid primary key
        references public.objects(id) on update restrict on delete restrict,

    opportunity_id uuid not null
        references public.opportunities(id) on update restrict on delete restrict,

    organization_id uuid
        references public.organizations(id) on update restrict on delete set null,

    status text not null default 'draft'
        check (status in (
            'draft','preparing','submitted','assessment','interviewing',
            'offer','accepted','rejected','withdrawn','closed'
        )),

    application_method text
        check (application_method is null or application_method in (
            'company_portal','email','referral','recruiter','campus_portal',
            'linkedin','handshake','other'
        )),

    submitted_at timestamptz,
    withdrawn_at timestamptz,
    decision_at timestamptz,

    outcome text
        check (outcome is null or outcome in (
            'offer','accepted','rejected','withdrawn','expired','cancelled'
        )),

    requisition_id text
        check (requisition_id is null or length(btrim(requisition_id)) > 0),

    portal_url text
        check (portal_url is null or portal_url ~* '^https?://'),

    resume_storage_path text
        check (resume_storage_path is null or length(btrim(resume_storage_path)) > 0),

    cover_letter_storage_path text
        check (cover_letter_storage_path is null or length(btrim(cover_letter_storage_path)) > 0),

    additional_materials jsonb not null default '{}'::jsonb
        check (jsonb_typeof(additional_materials) = 'object'),

    referral_person_id uuid
        references public.people(id) on update restrict on delete set null,

    recruiter_person_id uuid
        references public.people(id) on update restrict on delete set null,

    priority smallint not null default 3 check (priority between 1 and 5),

    fit_score numeric(5,2)
        check (fit_score is null or fit_score between 0 and 100),

    next_action_at timestamptz,
    notes text,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_applications_submitted_timestamp
        check (
            status not in ('submitted','assessment','interviewing','offer',
                           'accepted','rejected','closed')
            or submitted_at is not null
        ),

    constraint ck_applications_withdrawn_timestamp
        check (status <> 'withdrawn' or withdrawn_at is not null),

    constraint ck_applications_decision_timestamp
        check (
            status not in ('offer','accepted','rejected','closed')
            or decision_at is not null
        ),

    constraint ck_applications_outcome_status
        check (
            outcome is null
            or (outcome = 'offer' and status in ('offer','accepted','closed'))
            or (outcome = 'accepted' and status in ('accepted','closed'))
            or (outcome = 'rejected' and status in ('rejected','closed'))
            or (outcome = 'withdrawn' and status in ('withdrawn','closed'))
            or (outcome in ('expired','cancelled') and status = 'closed')
        )
);

comment on table public.applications is
'Application attempts, recruiting lifecycle, materials, contacts, decisions, and outcomes.';

drop trigger if exists trg_applications__set_updated_at on public.applications;
create trigger trg_applications__set_updated_at
before update on public.applications
for each row execute function private.set_updated_at();

create or replace function private.validate_application_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_opp_owner uuid;
    v_opp_org uuid;
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

    if v_type <> 'application' then
        raise exception 'Object % must have object_type application.', new.id
            using errcode = '23514';
    end if;

    select o.owner_user_id, opp.organization_id
      into v_opp_owner, v_opp_org
      from public.objects o
      join public.opportunities opp on opp.id = o.id
     where opp.id = new.opportunity_id
       and o.deleted_at is null;

    if not found then
        raise exception 'Opportunity % does not exist or is deleted.', new.opportunity_id
            using errcode = '23503';
    end if;

    if v_opp_owner <> v_owner then
        raise exception 'Application and opportunity must have the same owner.'
            using errcode = '42501';
    end if;

    if new.organization_id is null and v_opp_org is not null then
        new.organization_id := v_opp_org;
    end if;

    if new.organization_id is not null then
        select owner_user_id into v_linked_owner
          from public.objects
         where id = new.organization_id
           and object_type = 'organization'
           and deleted_at is null;

        if not found or v_linked_owner <> v_owner then
            raise exception 'Invalid application organization ownership.'
                using errcode = '42501';
        end if;

        if v_opp_org is not null and new.organization_id <> v_opp_org then
            raise exception 'Application organization must match opportunity organization.'
                using errcode = '23514';
        end if;
    end if;

    if new.referral_person_id is not null then
        select owner_user_id into v_linked_owner
          from public.objects
         where id = new.referral_person_id
           and object_type = 'person'
           and deleted_at is null;

        if not found or v_linked_owner <> v_owner then
            raise exception 'Invalid referral person ownership.'
                using errcode = '42501';
        end if;
    end if;

    if new.recruiter_person_id is not null then
        select owner_user_id into v_linked_owner
          from public.objects
         where id = new.recruiter_person_id
           and object_type = 'person'
           and deleted_at is null;

        if not found or v_linked_owner <> v_owner then
            raise exception 'Invalid recruiter person ownership.'
                using errcode = '42501';
        end if;
    end if;

    if new.requisition_id is not null then
        new.requisition_id := btrim(new.requisition_id);
    end if;

    return new;
end;
$$;

drop trigger if exists trg_applications__validate on public.applications;
create trigger trg_applications__validate
before insert or update on public.applications
for each row execute function private.validate_application_object();

create index if not exists ix_applications__opportunity
    on public.applications(opportunity_id);

create index if not exists ix_applications__organization_status
    on public.applications(organization_id, status)
    where organization_id is not null;

create index if not exists ix_applications__status
    on public.applications(status);

create index if not exists ix_applications__submitted_at
    on public.applications(submitted_at desc)
    where submitted_at is not null;

create index if not exists ix_applications__next_action
    on public.applications(next_action_at)
    where next_action_at is not null
      and status not in ('accepted','rejected','withdrawn','closed');

create index if not exists ix_applications__priority_fit
    on public.applications(priority, fit_score desc nulls last);

create index if not exists ix_applications__recruiter
    on public.applications(recruiter_person_id)
    where recruiter_person_id is not null;

create index if not exists ix_applications__referral
    on public.applications(referral_person_id)
    where referral_person_id is not null;

create index if not exists ix_applications__outcome
    on public.applications(outcome)
    where outcome is not null;

alter table public.applications enable row level security;

create policy applications_select_owner
on public.applications for select to authenticated
using (private.is_object_owner(id));

create policy applications_insert_owner
on public.applications for insert to authenticated
with check (
    private.is_object_owner(id)
    and private.is_object_owner(opportunity_id)
    and (organization_id is null or private.is_object_owner(organization_id))
    and (referral_person_id is null or private.is_object_owner(referral_person_id))
    and (recruiter_person_id is null or private.is_object_owner(recruiter_person_id))
);

create policy applications_update_owner
on public.applications for update to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and private.is_object_owner(opportunity_id)
    and (organization_id is null or private.is_object_owner(organization_id))
    and (referral_person_id is null or private.is_object_owner(referral_person_id))
    and (recruiter_person_id is null or private.is_object_owner(recruiter_person_id))
);

create policy applications_delete_owner
on public.applications for delete to authenticated
using (private.is_object_owner(id));

revoke all on table public.applications from anon;
grant select, insert, update, delete on table public.applications to authenticated;

commit;
