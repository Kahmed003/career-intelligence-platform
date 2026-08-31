
/*
Migration: 20260721012600_create_career_campaigns.sql
Purpose: Create recruiting campaigns and generic campaign membership.
*/
begin;

create table if not exists public.career_campaigns (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    campaign_type text not null default 'general'
        check (
            campaign_type in (
                'internship_search',
                'full_time_search',
                'fellowship_search',
                'graduate_school',
                'networking',
                'industry_strategy',
                'geography_strategy',
                'company_targeting',
                'general',
                'other'
            )
        ),

    status text not null default 'planned'
        check (
            status in (
                'planned',
                'active',
                'paused',
                'completed',
                'cancelled',
                'archived'
            )
        ),

    start_date date,
    end_date date,

    target_application_count integer
        check (
            target_application_count is null
            or target_application_count >= 0
        ),

    target_networking_count integer
        check (
            target_networking_count is null
            or target_networking_count >= 0
        ),

    target_interview_count integer
        check (
            target_interview_count is null
            or target_interview_count >= 0
        ),

    preference_profile_id uuid
        references public.career_preference_profiles(id)
        on update restrict
        on delete set null,

    description text,
    notes text,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_career_campaigns__date_order
        check (
            start_date is null
            or end_date is null
            or end_date >= start_date
        )
);

comment on table public.career_campaigns is
'Strategic recruiting-cycle containers grouping Career OS activity without replacing underlying domain state.';

create table if not exists public.career_campaign_members (
    campaign_id uuid not null
        references public.career_campaigns(id)
        on update restrict
        on delete cascade,

    object_id uuid not null
        references public.objects(id)
        on update restrict
        on delete restrict,

    member_role text not null default 'target'
        check (
            member_role in (
                'target',
                'supporting',
                'networking',
                'application',
                'search',
                'task',
                'research',
                'material',
                'calendar',
                'other'
            )
        ),

    priority smallint not null default 3
        check (priority between 1 and 5),

    status text not null default 'active'
        check (
            status in (
                'active',
                'completed',
                'dropped',
                'archived'
            )
        ),

    added_at timestamptz not null default statement_timestamp(),

    metadata jsonb not null default '{}'::jsonb
        check (jsonb_typeof(metadata) = 'object'),

    primary key (
        campaign_id,
        object_id,
        member_role
    ),

    constraint ck_career_campaign_members__not_self
        check (campaign_id <> object_id)
);

comment on table public.career_campaign_members is
'Generic owner-scoped membership linking canonical Career OS objects to recruiting campaigns.';

drop trigger if exists trg_career_campaigns__set_updated_at
on public.career_campaigns;

create trigger trg_career_campaigns__set_updated_at
before update on public.career_campaigns
for each row
execute function private.set_updated_at();

create or replace function private.validate_career_campaign()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_pref_owner uuid;
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

    if v_type <> 'career_campaign' then
        raise exception 'Object % must have object_type career_campaign.', new.id
            using errcode = '23514';
    end if;

    if new.preference_profile_id is not null then
        select owner_user_id
          into v_pref_owner
          from public.objects
         where id = new.preference_profile_id
           and object_type = 'career_preference_profile'
           and deleted_at is null;

        if not found then
            raise exception 'Preference profile % does not exist or is deleted.',
                new.preference_profile_id
                using errcode = '23503';
        end if;

        if v_pref_owner <> v_owner then
            raise exception 'Campaign and preference profile must share owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.description is not null then
        new.description := btrim(new.description);
        if new.description = '' then
            new.description := null;
        end if;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_career_campaigns__validate
on public.career_campaigns;

create trigger trg_career_campaigns__validate
before insert or update
on public.career_campaigns
for each row
execute function private.validate_career_campaign();

create or replace function private.validate_career_campaign_member()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_campaign_owner uuid;
    v_member_owner uuid;
begin
    select o.owner_user_id
      into v_campaign_owner
      from public.objects o
      join public.career_campaigns c
        on c.id = o.id
     where c.id = new.campaign_id
       and o.deleted_at is null;

    if not found then
        raise exception 'Campaign % does not exist or is deleted.',
            new.campaign_id
            using errcode = '23503';
    end if;

    select owner_user_id
      into v_member_owner
      from public.objects
     where id = new.object_id
       and deleted_at is null;

    if not found then
        raise exception 'Campaign member object % does not exist or is deleted.',
            new.object_id
            using errcode = '23503';
    end if;

    if v_campaign_owner <> v_member_owner then
        raise exception 'Campaign and member object must share owner.'
            using errcode = '42501';
    end if;

    return new;
end;
$$;

drop trigger if exists trg_career_campaign_members__validate
on public.career_campaign_members;

create trigger trg_career_campaign_members__validate
before insert or update
on public.career_campaign_members
for each row
execute function private.validate_career_campaign_member();

create index if not exists ix_career_campaigns__status_dates
    on public.career_campaigns(status, start_date, end_date);

create index if not exists ix_career_campaigns__active
    on public.career_campaigns(start_date, end_date)
    where status = 'active';

create index if not exists ix_career_campaigns__preference
    on public.career_campaigns(preference_profile_id)
    where preference_profile_id is not null;

create index if not exists ix_career_campaign_members__object
    on public.career_campaign_members(object_id, status);

create index if not exists ix_career_campaign_members__campaign_role
    on public.career_campaign_members(campaign_id, member_role, priority);

create index if not exists ix_career_campaign_members__active
    on public.career_campaign_members(campaign_id, priority, added_at)
    where status = 'active';

alter table public.career_campaigns enable row level security;
alter table public.career_campaign_members enable row level security;

create policy career_campaigns_owner_all
on public.career_campaigns
for all to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and (
        preference_profile_id is null
        or private.is_object_owner(preference_profile_id)
    )
);

create policy career_campaign_members_owner_all
on public.career_campaign_members
for all to authenticated
using (
    private.is_object_owner(campaign_id)
    and private.is_object_owner(object_id)
)
with check (
    private.is_object_owner(campaign_id)
    and private.is_object_owner(object_id)
);

revoke all on public.career_campaigns from anon;
revoke all on public.career_campaign_members from anon;

grant select, insert, update, delete
on public.career_campaigns
to authenticated;

grant select, insert, update, delete
on public.career_campaign_members
to authenticated;

commit;
