
/*
Migration: 20260721011100_create_evidence_and_achievements.sql
Purpose: Create structured evidence and achievement records.
*/
begin;

create table if not exists public.evidence_achievements (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    evidence_type text not null
        check (
            evidence_type in (
                'project_outcome',
                'work_achievement',
                'research_output',
                'publication',
                'presentation',
                'award',
                'scholarship',
                'certification',
                'competition_result',
                'academic_achievement',
                'leadership_impact',
                'testimonial',
                'credential',
                'other'
            )
        ),

    verification_status text not null default 'unverified'
        check (
            verification_status in (
                'unverified',
                'self_verified',
                'documented',
                'third_party_verified',
                'official'
            )
        ),

    issued_by_organization_id uuid
        references public.organizations(id)
        on update restrict
        on delete set null,

    related_person_id uuid
        references public.people(id)
        on update restrict
        on delete set null,

    occurred_on date,
    valid_from date,
    valid_until date,

    quantified_value numeric(18,4),

    quantified_unit text
        check (
            quantified_unit is null
            or length(btrim(quantified_unit)) > 0
        ),

    summary text not null
        check (length(btrim(summary)) > 0),

    details text,

    source_url text
        check (
            source_url is null
            or source_url ~* '^https?://'
        ),

    storage_path text
        check (
            storage_path is null
            or length(btrim(storage_path)) > 0
        ),

    credential_id text
        check (
            credential_id is null
            or length(btrim(credential_id)) > 0
        ),

    is_resume_ready boolean not null default false,
    is_portfolio_ready boolean not null default false,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_evidence_achievements__validity_order
        check (
            valid_from is null
            or valid_until is null
            or valid_until >= valid_from
        ),

    constraint ck_evidence_achievements__quantified_unit_required
        check (
            quantified_value is null
            or quantified_unit is not null
        )
);

comment on table public.evidence_achievements is
'Structured evidence and achievements supporting skills, projects, applications, goals, and professional narratives.';

drop trigger if exists trg_evidence_achievements__set_updated_at
on public.evidence_achievements;

create trigger trg_evidence_achievements__set_updated_at
before update on public.evidence_achievements
for each row
execute function private.set_updated_at();

create or replace function private.validate_evidence_achievement_object()
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

    if v_type <> 'evidence_achievement' then
        raise exception 'Object % must have object_type evidence_achievement.', new.id
            using errcode = '23514';
    end if;

    if new.issued_by_organization_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.issued_by_organization_id
           and object_type = 'organization'
           and deleted_at is null;

        if not found then
            raise exception 'Issuer organization % does not exist or is deleted.',
                new.issued_by_organization_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Evidence and issuer organization must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.related_person_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.related_person_id
           and object_type = 'person'
           and deleted_at is null;

        if not found then
            raise exception 'Related person % does not exist or is deleted.',
                new.related_person_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Evidence and related person must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    new.summary := btrim(new.summary);

    if new.quantified_unit is not null then
        new.quantified_unit := btrim(new.quantified_unit);
    end if;

    if new.storage_path is not null then
        new.storage_path := btrim(new.storage_path);
    end if;

    if new.credential_id is not null then
        new.credential_id := btrim(new.credential_id);
    end if;

    return new;
end;
$$;

drop trigger if exists trg_evidence_achievements__validate
on public.evidence_achievements;

create trigger trg_evidence_achievements__validate
before insert or update
on public.evidence_achievements
for each row
execute function private.validate_evidence_achievement_object();

create index if not exists ix_evidence_achievements__type
    on public.evidence_achievements(evidence_type);

create index if not exists ix_evidence_achievements__verification
    on public.evidence_achievements(verification_status);

create index if not exists ix_evidence_achievements__issuer
    on public.evidence_achievements(issued_by_organization_id)
    where issued_by_organization_id is not null;

create index if not exists ix_evidence_achievements__related_person
    on public.evidence_achievements(related_person_id)
    where related_person_id is not null;

create index if not exists ix_evidence_achievements__resume_ready
    on public.evidence_achievements(is_resume_ready)
    where is_resume_ready = true;

create index if not exists ix_evidence_achievements__portfolio_ready
    on public.evidence_achievements(is_portfolio_ready)
    where is_portfolio_ready = true;

create index if not exists ix_evidence_achievements__valid_until
    on public.evidence_achievements(valid_until)
    where valid_until is not null;

create index if not exists ix_evidence_achievements__occurred_on
    on public.evidence_achievements(occurred_on desc)
    where occurred_on is not null;

alter table public.evidence_achievements enable row level security;

create policy evidence_achievements_select_owner
on public.evidence_achievements
for select to authenticated
using (private.is_object_owner(id));

create policy evidence_achievements_insert_owner
on public.evidence_achievements
for insert to authenticated
with check (
    private.is_object_owner(id)
    and (
        issued_by_organization_id is null
        or private.is_object_owner(issued_by_organization_id)
    )
    and (
        related_person_id is null
        or private.is_object_owner(related_person_id)
    )
);

create policy evidence_achievements_update_owner
on public.evidence_achievements
for update to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and (
        issued_by_organization_id is null
        or private.is_object_owner(issued_by_organization_id)
    )
    and (
        related_person_id is null
        or private.is_object_owner(related_person_id)
    )
);

create policy evidence_achievements_delete_owner
on public.evidence_achievements
for delete to authenticated
using (private.is_object_owner(id));

revoke all on table public.evidence_achievements from anon;
grant select, insert, update, delete
on table public.evidence_achievements
to authenticated;

commit;
