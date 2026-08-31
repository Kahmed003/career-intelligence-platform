
/*
Migration: 20260721010800_create_offers.sql
Purpose: Create Offers and Decisions domain.
*/
begin;

create table if not exists public.offers (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    application_id uuid not null
        references public.applications(id)
        on update restrict
        on delete restrict,

    organization_id uuid
        references public.organizations(id)
        on update restrict
        on delete set null,

    status text not null default 'received'
        check (
            status in (
                'received',
                'reviewing',
                'negotiating',
                'accepted',
                'declined',
                'expired',
                'rescinded'
            )
        ),

    offer_received_at timestamptz not null default statement_timestamp(),
    decision_deadline_at timestamptz,
    decision_at timestamptz,

    decision text
        check (
            decision is null
            or decision in (
                'accepted',
                'declined',
                'expired',
                'rescinded'
            )
        ),

    start_date date,
    end_date date,

    base_compensation numeric(14,2)
        check (base_compensation is null or base_compensation >= 0),

    compensation_currency text
        check (
            compensation_currency is null
            or compensation_currency ~ '^[A-Z]{3}$'
        ),

    compensation_period text
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

    signing_bonus numeric(14,2)
        check (signing_bonus is null or signing_bonus >= 0),

    performance_bonus_target numeric(14,2)
        check (performance_bonus_target is null or performance_bonus_target >= 0),

    equity_value numeric(14,2)
        check (equity_value is null or equity_value >= 0),

    relocation_amount numeric(14,2)
        check (relocation_amount is null or relocation_amount >= 0),

    housing_amount numeric(14,2)
        check (housing_amount is null or housing_amount >= 0),

    other_compensation jsonb not null default '{}'::jsonb
        check (jsonb_typeof(other_compensation) = 'object'),

    work_mode text not null default 'unspecified'
        check (
            work_mode in (
                'onsite',
                'hybrid',
                'remote',
                'unspecified'
            )
        ),

    location_text text
        check (
            location_text is null
            or length(btrim(location_text)) > 0
        ),

    negotiation_status text not null default 'not_started'
        check (
            negotiation_status in (
                'not_started',
                'considering',
                'requested',
                'in_progress',
                'completed',
                'not_applicable'
            )
        ),

    negotiated_at timestamptz,

    offer_letter_storage_path text
        check (
            offer_letter_storage_path is null
            or length(btrim(offer_letter_storage_path)) > 0
        ),

    comparison_score numeric(5,2)
        check (
            comparison_score is null
            or comparison_score between 0 and 100
        ),

    notes text,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_offers__decision_deadline_order
        check (
            decision_deadline_at is null
            or decision_deadline_at >= offer_received_at
        ),

    constraint ck_offers__dates_order
        check (
            start_date is null
            or end_date is null
            or end_date >= start_date
        ),

    constraint ck_offers__decision_requires_timestamp
        check (
            decision is null
            or decision_at is not null
        ),

    constraint ck_offers__status_decision_consistency
        check (
            (status in ('received','reviewing','negotiating') and decision is null)
            or (status = 'accepted' and decision = 'accepted')
            or (status = 'declined' and decision = 'declined')
            or (status = 'expired' and decision = 'expired')
            or (status = 'rescinded' and decision = 'rescinded')
        ),

    constraint ck_offers__compensation_currency_required
        check (
            (
                base_compensation is null
                and signing_bonus is null
                and performance_bonus_target is null
                and equity_value is null
                and relocation_amount is null
                and housing_amount is null
            )
            or compensation_currency is not null
        )
);

comment on table public.offers is
'Offers and user decisions resulting from applications, including compensation and negotiation terms.';

drop trigger if exists trg_offers__set_updated_at
on public.offers;

create trigger trg_offers__set_updated_at
before update on public.offers
for each row
execute function private.set_updated_at();

create or replace function private.validate_offer_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_application_owner uuid;
    v_application_org uuid;
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

    if v_type <> 'offer' then
        raise exception 'Object % must have object_type offer.', new.id
            using errcode = '23514';
    end if;

    select o.owner_user_id, a.organization_id
      into v_application_owner, v_application_org
      from public.objects o
      join public.applications a
        on a.id = o.id
     where a.id = new.application_id
       and o.deleted_at is null;

    if not found then
        raise exception 'Application % does not exist or is deleted.', new.application_id
            using errcode = '23503';
    end if;

    if v_application_owner <> v_owner then
        raise exception 'Offer and application must have the same owner.'
            using errcode = '42501';
    end if;

    if new.organization_id is null and v_application_org is not null then
        new.organization_id := v_application_org;
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
            raise exception 'Offer and organization must have the same owner.'
                using errcode = '42501';
        end if;

        if v_application_org is not null
           and new.organization_id <> v_application_org then
            raise exception 'Offer organization must match application organization.'
                using errcode = '23514';
        end if;
    end if;

    if new.compensation_currency is not null then
        new.compensation_currency := upper(btrim(new.compensation_currency));
    end if;

    if new.location_text is not null then
        new.location_text := btrim(new.location_text);
    end if;

    if new.offer_letter_storage_path is not null then
        new.offer_letter_storage_path := btrim(new.offer_letter_storage_path);
    end if;

    return new;
end;
$$;

drop trigger if exists trg_offers__validate
on public.offers;

create trigger trg_offers__validate
before insert or update
on public.offers
for each row
execute function private.validate_offer_object();

create index if not exists ix_offers__application
    on public.offers(application_id);

create index if not exists ix_offers__organization_status
    on public.offers(organization_id, status)
    where organization_id is not null;

create index if not exists ix_offers__decision_deadline
    on public.offers(decision_deadline_at)
    where decision_deadline_at is not null
      and status in ('received','reviewing','negotiating');

create index if not exists ix_offers__status
    on public.offers(status);

create index if not exists ix_offers__negotiation_status
    on public.offers(negotiation_status);

create index if not exists ix_offers__comparison_score
    on public.offers(comparison_score desc nulls last)
    where comparison_score is not null;

alter table public.offers enable row level security;

create policy offers_select_owner
on public.offers
for select to authenticated
using (private.is_object_owner(id));

create policy offers_insert_owner
on public.offers
for insert to authenticated
with check (
    private.is_object_owner(id)
    and private.is_object_owner(application_id)
    and (
        organization_id is null
        or private.is_object_owner(organization_id)
    )
);

create policy offers_update_owner
on public.offers
for update to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and private.is_object_owner(application_id)
    and (
        organization_id is null
        or private.is_object_owner(organization_id)
    )
);

create policy offers_delete_owner
on public.offers
for delete to authenticated
using (private.is_object_owner(id));

revoke all on table public.offers from anon;
grant select, insert, update, delete
on table public.offers
to authenticated;

commit;
