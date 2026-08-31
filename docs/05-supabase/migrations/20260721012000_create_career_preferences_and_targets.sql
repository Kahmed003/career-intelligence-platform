
/*
Migration: 20260721012000_create_career_preferences_and_targets.sql
Purpose: Create user-specific career preference profiles and weighted criteria.
*/
begin;

create table if not exists public.career_preference_profiles (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    profile_name text not null
        check (length(btrim(profile_name)) > 0),

    status text not null default 'draft'
        check (
            status in (
                'draft',
                'active',
                'archived'
            )
        ),

    is_default boolean not null default false,

    target_start_date date,
    target_end_date date,

    minimum_compensation numeric(14,2)
        check (
            minimum_compensation is null
            or minimum_compensation >= 0
        ),

    preferred_compensation numeric(14,2)
        check (
            preferred_compensation is null
            or preferred_compensation >= 0
        ),

    compensation_currency text,
    compensation_period text
        check (
            compensation_period is null
            or compensation_period in (
                'hourly',
                'daily',
                'weekly',
                'monthly',
                'annual',
                'stipend',
                'total_program',
                'other'
            )
        ),

    requires_sponsorship boolean,
    work_authorization_notes text,

    minimum_fit_score numeric(5,2)
        check (
            minimum_fit_score is null
            or minimum_fit_score between 0 and 100
        ),

    notes text,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_career_preference_profiles__target_dates
        check (
            target_start_date is null
            or target_end_date is null
            or target_end_date >= target_start_date
        ),

    constraint ck_career_preference_profiles__compensation_order
        check (
            minimum_compensation is null
            or preferred_compensation is null
            or preferred_compensation >= minimum_compensation
        ),

    constraint ck_career_preference_profiles__currency_required
        check (
            (
                minimum_compensation is null
                and preferred_compensation is null
            )
            or compensation_currency is not null
        )
);

comment on table public.career_preference_profiles is
'User-specific career search profiles containing target timing, compensation, sponsorship, and scoring preferences.';

create table if not exists public.career_preference_criteria (
    preference_profile_id uuid not null
        references public.career_preference_profiles(id)
        on update restrict
        on delete cascade,

    criterion_type text not null
        check (
            criterion_type in (
                'function',
                'role_family',
                'industry',
                'location',
                'country',
                'work_mode',
                'employment_type',
                'opportunity_type',
                'company_size',
                'organization',
                'skill',
                'compensation',
                'sponsorship',
                'other'
            )
        ),

    criterion_value text not null
        check (length(btrim(criterion_value)) > 0),

    preference_level text not null default 'preference'
        check (
            preference_level in (
                'must_have',
                'strong_preference',
                'preference',
                'neutral',
                'avoid'
            )
        ),

    weight numeric(5,2) not null default 50
        check (weight between 0 and 100),

    is_exclusion boolean not null default false,

    notes text,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    primary key (
        preference_profile_id,
        criterion_type,
        criterion_value
    )
);

comment on table public.career_preference_criteria is
'Weighted career search criteria and exclusions belonging to a preference profile.';

drop trigger if exists trg_career_preference_profiles__set_updated_at
on public.career_preference_profiles;

create trigger trg_career_preference_profiles__set_updated_at
before update on public.career_preference_profiles
for each row
execute function private.set_updated_at();

drop trigger if exists trg_career_preference_criteria__set_updated_at
on public.career_preference_criteria;

create trigger trg_career_preference_criteria__set_updated_at
before update on public.career_preference_criteria
for each row
execute function private.set_updated_at();

create or replace function private.validate_career_preference_profile()
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

    if v_type <> 'career_preference_profile' then
        raise exception 'Object % must have object_type career_preference_profile.', new.id
            using errcode = '23514';
    end if;

    new.profile_name := btrim(new.profile_name);

    if new.compensation_currency is not null then
        new.compensation_currency := upper(btrim(new.compensation_currency));

        if new.compensation_currency !~ '^[A-Z]{3}$' then
            raise exception 'Compensation currency must be a 3-letter ISO-style code.'
                using errcode = '23514';
        end if;
    end if;

    if new.work_authorization_notes is not null then
        new.work_authorization_notes := btrim(new.work_authorization_notes);
        if new.work_authorization_notes = '' then
            new.work_authorization_notes := null;
        end if;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_career_preference_profiles__validate
on public.career_preference_profiles;

create trigger trg_career_preference_profiles__validate
before insert or update
on public.career_preference_profiles
for each row
execute function private.validate_career_preference_profile();

create or replace function private.validate_career_preference_criterion()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_profile_owner uuid;
begin
    select o.owner_user_id
      into v_profile_owner
      from public.objects o
      join public.career_preference_profiles p
        on p.id = o.id
     where p.id = new.preference_profile_id
       and o.deleted_at is null;

    if not found then
        raise exception 'Preference profile % does not exist or is deleted.',
            new.preference_profile_id
            using errcode = '23503';
    end if;

    new.criterion_value := btrim(new.criterion_value);

    if new.criterion_type in (
        'function',
        'role_family',
        'industry',
        'country',
        'work_mode',
        'employment_type',
        'opportunity_type',
        'company_size',
        'sponsorship'
    ) then
        new.criterion_value := lower(new.criterion_value);
    end if;

    return new;
end;
$$;

drop trigger if exists trg_career_preference_criteria__validate
on public.career_preference_criteria;

create trigger trg_career_preference_criteria__validate
before insert or update
on public.career_preference_criteria
for each row
execute function private.validate_career_preference_criterion();

create index if not exists ix_career_preference_profiles__status
    on public.career_preference_profiles(status, updated_at desc);

create index if not exists ix_career_preference_profiles__default_active
    on public.career_preference_profiles(updated_at desc)
    where is_default = true
      and status = 'active';

create index if not exists ix_career_preference_profiles__target_window
    on public.career_preference_profiles(target_start_date, target_end_date)
    where target_start_date is not null
       or target_end_date is not null;

create index if not exists ix_career_preference_criteria__type
    on public.career_preference_criteria(preference_profile_id, criterion_type);

create index if not exists ix_career_preference_criteria__weighted
    on public.career_preference_criteria(preference_profile_id, weight desc);

create index if not exists ix_career_preference_criteria__exclusions
    on public.career_preference_criteria(preference_profile_id, criterion_type)
    where is_exclusion = true;

alter table public.career_preference_profiles enable row level security;
alter table public.career_preference_criteria enable row level security;

create policy career_preference_profiles_select_owner
on public.career_preference_profiles
for select to authenticated
using (private.is_object_owner(id));

create policy career_preference_profiles_insert_owner
on public.career_preference_profiles
for insert to authenticated
with check (private.is_object_owner(id));

create policy career_preference_profiles_update_owner
on public.career_preference_profiles
for update to authenticated
using (private.is_object_owner(id))
with check (private.is_object_owner(id));

create policy career_preference_profiles_delete_owner
on public.career_preference_profiles
for delete to authenticated
using (private.is_object_owner(id));

create policy career_preference_criteria_select_owner
on public.career_preference_criteria
for select to authenticated
using (private.is_object_owner(preference_profile_id));

create policy career_preference_criteria_insert_owner
on public.career_preference_criteria
for insert to authenticated
with check (private.is_object_owner(preference_profile_id));

create policy career_preference_criteria_update_owner
on public.career_preference_criteria
for update to authenticated
using (private.is_object_owner(preference_profile_id))
with check (private.is_object_owner(preference_profile_id));

create policy career_preference_criteria_delete_owner
on public.career_preference_criteria
for delete to authenticated
using (private.is_object_owner(preference_profile_id));

revoke all on table public.career_preference_profiles from anon;
revoke all on table public.career_preference_criteria from anon;

grant select, insert, update, delete
on table public.career_preference_profiles
to authenticated;

grant select, insert, update, delete
on table public.career_preference_criteria
to authenticated;

commit;
