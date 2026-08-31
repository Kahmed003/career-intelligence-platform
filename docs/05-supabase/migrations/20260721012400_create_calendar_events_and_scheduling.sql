
/*
Migration: 20260721012400_create_calendar_events_and_scheduling.sql
Purpose: Create normalized calendar events, participants, and external sync state.
*/
begin;

create table if not exists public.calendar_events (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    event_type text not null
        check (
            event_type in (
                'interview',
                'assessment',
                'networking',
                'application_deadline',
                'offer_deadline',
                'task',
                'project',
                'preparation',
                'study',
                'career_planning',
                'conference',
                'other'
            )
        ),

    status text not null default 'tentative'
        check (
            status in (
                'tentative',
                'confirmed',
                'completed',
                'cancelled',
                'rescheduled'
            )
        ),

    source_object_id uuid
        references public.objects(id)
        on update restrict
        on delete set null,

    parent_object_id uuid
        references public.objects(id)
        on update restrict
        on delete set null,

    title text not null
        check (length(btrim(title)) > 0),

    description text,

    starts_at timestamptz not null,
    ends_at timestamptz,

    all_day boolean not null default false,

    timezone text,

    location_text text,

    meeting_url text
        check (
            meeting_url is null
            or meeting_url ~* '^https?://'
        ),

    preparation_minutes integer not null default 0
        check (preparation_minutes >= 0),

    follow_up_minutes integer not null default 0
        check (follow_up_minutes >= 0),

    is_recurring boolean not null default false,
    recurrence_rule text,

    metadata jsonb not null default '{}'::jsonb
        check (jsonb_typeof(metadata) = 'object'),

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_calendar_events__time_order
        check (
            ends_at is null
            or ends_at >= starts_at
        ),

    constraint ck_calendar_events__timezone
        check (
            all_day = true
            or timezone is not null
        ),

    constraint ck_calendar_events__recurrence
        check (
            (is_recurring = true and recurrence_rule is not null)
            or
            (is_recurring = false and recurrence_rule is null)
        )
);

comment on table public.calendar_events is
'User-owned normalized calendar events linked to Career OS source objects.';

create table if not exists public.calendar_event_participants (
    calendar_event_id uuid not null
        references public.calendar_events(id)
        on update restrict
        on delete cascade,

    person_id uuid not null
        references public.people(id)
        on update restrict
        on delete cascade,

    participant_role text not null default 'attendee'
        check (
            participant_role in (
                'interviewer',
                'recruiter',
                'mentor',
                'contact',
                'attendee',
                'organizer',
                'other'
            )
        ),

    response_status text not null default 'unknown'
        check (
            response_status in (
                'needs_action',
                'accepted',
                'declined',
                'tentative',
                'unknown'
            )
        ),

    is_required boolean not null default true,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    primary key (
        calendar_event_id,
        person_id,
        participant_role
    )
);

comment on table public.calendar_event_participants is
'People participating in Career OS calendar events.';

create table if not exists public.external_calendar_links (
    id uuid primary key default gen_random_uuid(),

    calendar_event_id uuid not null
        references public.calendar_events(id)
        on update restrict
        on delete cascade,

    provider text not null
        check (
            provider in (
                'google',
                'outlook',
                'apple',
                'other'
            )
        ),

    external_calendar_id text not null
        check (length(btrim(external_calendar_id)) > 0),

    external_event_id text not null
        check (length(btrim(external_event_id)) > 0),

    sync_direction text not null default 'bidirectional'
        check (
            sync_direction in (
                'push',
                'pull',
                'bidirectional'
            )
        ),

    sync_status text not null default 'pending'
        check (
            sync_status in (
                'pending',
                'synced',
                'conflict',
                'failed',
                'detached'
            )
        ),

    external_updated_at timestamptz,
    last_synced_at timestamptz,
    etag text,
    sync_error text,

    metadata jsonb not null default '{}'::jsonb
        check (jsonb_typeof(metadata) = 'object'),

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp()
);

comment on table public.external_calendar_links is
'External provider identifiers and synchronization state for Career OS calendar events.';

drop trigger if exists trg_calendar_events__set_updated_at
on public.calendar_events;

create trigger trg_calendar_events__set_updated_at
before update on public.calendar_events
for each row execute function private.set_updated_at();

drop trigger if exists trg_calendar_event_participants__set_updated_at
on public.calendar_event_participants;

create trigger trg_calendar_event_participants__set_updated_at
before update on public.calendar_event_participants
for each row execute function private.set_updated_at();

drop trigger if exists trg_external_calendar_links__set_updated_at
on public.external_calendar_links;

create trigger trg_external_calendar_links__set_updated_at
before update on public.external_calendar_links
for each row execute function private.set_updated_at();

create or replace function private.validate_calendar_event()
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

    if v_type <> 'calendar_event' then
        raise exception 'Object % must have object_type calendar_event.', new.id
            using errcode = '23514';
    end if;

    if new.source_object_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.source_object_id
           and deleted_at is null;

        if not found then
            raise exception 'Source object % does not exist or is deleted.',
                new.source_object_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Calendar event and source object must share owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.parent_object_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.parent_object_id
           and deleted_at is null;

        if not found then
            raise exception 'Parent object % does not exist or is deleted.',
                new.parent_object_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Calendar event and parent object must share owner.'
                using errcode = '42501';
        end if;
    end if;

    new.title := btrim(new.title);

    if new.timezone is not null then
        new.timezone := btrim(new.timezone);
        if new.timezone = '' then new.timezone := null; end if;
    end if;

    if new.location_text is not null then
        new.location_text := btrim(new.location_text);
        if new.location_text = '' then new.location_text := null; end if;
    end if;

    if new.recurrence_rule is not null then
        new.recurrence_rule := btrim(new.recurrence_rule);
        if new.recurrence_rule = '' then new.recurrence_rule := null; end if;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_calendar_events__validate
on public.calendar_events;

create trigger trg_calendar_events__validate
before insert or update on public.calendar_events
for each row execute function private.validate_calendar_event();

create or replace function private.validate_calendar_event_participant()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_event_owner uuid;
    v_person_owner uuid;
begin
    select o.owner_user_id
      into v_event_owner
      from public.objects o
      join public.calendar_events ce on ce.id = o.id
     where ce.id = new.calendar_event_id
       and o.deleted_at is null;

    if not found then
        raise exception 'Calendar event % does not exist or is deleted.',
            new.calendar_event_id
            using errcode = '23503';
    end if;

    select owner_user_id
      into v_person_owner
      from public.objects
     where id = new.person_id
       and object_type = 'person'
       and deleted_at is null;

    if not found then
        raise exception 'Person % does not exist or is deleted.',
            new.person_id
            using errcode = '23503';
    end if;

    if v_event_owner <> v_person_owner then
        raise exception 'Calendar event and participant must share owner.'
            using errcode = '42501';
    end if;

    return new;
end;
$$;

drop trigger if exists trg_calendar_event_participants__validate
on public.calendar_event_participants;

create trigger trg_calendar_event_participants__validate
before insert or update on public.calendar_event_participants
for each row execute function private.validate_calendar_event_participant();

create or replace function private.validate_external_calendar_link()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_event_owner uuid;
begin
    select o.owner_user_id
      into v_event_owner
      from public.objects o
      join public.calendar_events ce on ce.id = o.id
     where ce.id = new.calendar_event_id
       and o.deleted_at is null;

    if not found then
        raise exception 'Calendar event % does not exist or is deleted.',
            new.calendar_event_id
            using errcode = '23503';
    end if;

    new.external_calendar_id := btrim(new.external_calendar_id);
    new.external_event_id := btrim(new.external_event_id);

    if new.etag is not null then
        new.etag := btrim(new.etag);
        if new.etag = '' then new.etag := null; end if;
    end if;

    if new.sync_error is not null then
        new.sync_error := btrim(new.sync_error);
        if new.sync_error = '' then new.sync_error := null; end if;
    end if;

    if new.sync_status = 'failed'
       and new.sync_error is null then
        raise exception 'Failed calendar sync requires sync_error.'
            using errcode = '23514';
    end if;

    if new.sync_status <> 'failed'
       and new.sync_error is not null then
        raise exception 'sync_error is only valid for failed sync state.'
            using errcode = '23514';
    end if;

    return new;
end;
$$;

drop trigger if exists trg_external_calendar_links__validate
on public.external_calendar_links;

create trigger trg_external_calendar_links__validate
before insert or update on public.external_calendar_links
for each row execute function private.validate_external_calendar_link();

create unique index if not exists ux_external_calendar_links__provider_event
    on public.external_calendar_links(
        provider,
        external_calendar_id,
        external_event_id
    );

create index if not exists ix_calendar_events__upcoming
    on public.calendar_events(starts_at)
    where status in ('tentative', 'confirmed');

create index if not exists ix_calendar_events__source
    on public.calendar_events(source_object_id, starts_at desc)
    where source_object_id is not null;

create index if not exists ix_calendar_events__parent
    on public.calendar_events(parent_object_id, starts_at desc)
    where parent_object_id is not null;

create index if not exists ix_calendar_events__type_status
    on public.calendar_events(event_type, status, starts_at);

create index if not exists ix_calendar_event_participants__person
    on public.calendar_event_participants(person_id, calendar_event_id);

create index if not exists ix_external_calendar_links__event
    on public.external_calendar_links(calendar_event_id);

create index if not exists ix_external_calendar_links__sync_queue
    on public.external_calendar_links(provider, sync_status, last_synced_at)
    where sync_status in ('pending', 'conflict', 'failed');

alter table public.calendar_events enable row level security;
alter table public.calendar_event_participants enable row level security;
alter table public.external_calendar_links enable row level security;

create policy calendar_events_owner_all
on public.calendar_events
for all to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and (
        source_object_id is null
        or private.is_object_owner(source_object_id)
    )
    and (
        parent_object_id is null
        or private.is_object_owner(parent_object_id)
    )
);

create policy calendar_event_participants_owner_all
on public.calendar_event_participants
for all to authenticated
using (
    private.is_object_owner(calendar_event_id)
    and private.is_object_owner(person_id)
)
with check (
    private.is_object_owner(calendar_event_id)
    and private.is_object_owner(person_id)
);

create policy external_calendar_links_owner_all
on public.external_calendar_links
for all to authenticated
using (private.is_object_owner(calendar_event_id))
with check (private.is_object_owner(calendar_event_id));

revoke all on public.calendar_events from anon;
revoke all on public.calendar_event_participants from anon;
revoke all on public.external_calendar_links from anon;

grant select, insert, update, delete
on public.calendar_events
to authenticated;

grant select, insert, update, delete
on public.calendar_event_participants
to authenticated;

grant select, insert, update, delete
on public.external_calendar_links
to authenticated;

commit;
