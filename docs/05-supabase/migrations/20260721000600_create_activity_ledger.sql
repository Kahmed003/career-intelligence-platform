/*
===============================================================================
Career OS Database Migration

Migration ID:    20260721000600
Filename:        20260721000600_create_activity_ledger.sql
Version:         1.0.0
Purpose:         Create the governed append-oriented Activity Ledger.

Dependencies:
  - 20260721000500_create_relationship_graph.sql

Affected Schemas:
  - public
  - private

Security Considerations:
  - RLS is enabled immediately.
  - Authenticated users may read and insert owned events.
  - Authenticated users may not update or delete ledger rows.
  - Linked-object ownership is validated in a trigger.

Rollback Strategy:
  Ledger removal destroys audit history and requires a dedicated forward
  migration following retention and dependency analysis.
===============================================================================
*/

begin;

create table if not exists public.activity_event_types (
    code text
        constraint pk_activity_event_types
        primary key,

    display_name text
        constraint ck_activity_event_types__display_name__not_blank
        check (length(btrim(display_name)) > 0)
        not null,

    description text
        constraint ck_activity_event_types__description__not_blank
        check (length(btrim(description)) > 0)
        not null,

    is_active boolean
        not null
        default true,

    created_at timestamptz
        not null
        default statement_timestamp(),

    updated_at timestamptz
        not null
        default statement_timestamp(),

    constraint ck_activity_event_types__code__format
        check (code ~ '^[a-z][a-z0-9_]*$')
);

comment on table public.activity_event_types is
'Governed catalog of event codes accepted by the Career OS Activity Ledger.';

drop trigger if exists trg_activity_event_types__set_updated_at
on public.activity_event_types;

create trigger trg_activity_event_types__set_updated_at
before update on public.activity_event_types
for each row
execute function private.set_updated_at();

insert into public.activity_event_types (
    code,
    display_name,
    description
)
values
    ('object_created', 'Object Created', 'A first-class Career OS object was created.'),
    ('object_updated', 'Object Updated', 'A first-class Career OS object was materially updated.'),
    ('object_archived', 'Object Archived', 'An object entered the archived lifecycle state.'),
    ('object_deleted', 'Object Deleted', 'An object was soft-deleted.'),
    ('relationship_created', 'Relationship Created', 'A graph relationship was created.'),
    ('relationship_deleted', 'Relationship Deleted', 'A graph relationship was soft-deleted or removed.'),
    ('status_changed', 'Status Changed', 'A canonical or domain-specific status changed.'),
    ('note_added', 'Note Added', 'A note or narrative update was added.'),
    ('recommendation_generated', 'Recommendation Generated', 'An AI or rules-based recommendation was generated.'),
    ('integration_synced', 'Integration Synced', 'An external integration completed a synchronization event.')
on conflict (code) do nothing;

create table if not exists public.activity_events (
    id uuid
        constraint pk_activity_events
        primary key
        default extensions.gen_random_uuid(),

    owner_user_id uuid
        constraint fk_activity_events__owner_user_id__profiles
        not null
        references public.profiles(id)
        on update restrict
        on delete restrict,

    event_type_code text
        constraint fk_activity_events__event_type_code__activity_event_types
        not null
        references public.activity_event_types(code)
        on update cascade
        on delete restrict,

    actor_type public.activity_actor_type
        not null,

    actor_user_id uuid
        constraint fk_activity_events__actor_user_id__profiles
        references public.profiles(id)
        on update restrict
        on delete restrict,

    primary_object_id uuid
        constraint fk_activity_events__primary_object_id__objects
        references public.objects(id)
        on update restrict
        on delete restrict,

    secondary_object_id uuid
        constraint fk_activity_events__secondary_object_id__objects
        references public.objects(id)
        on update restrict
        on delete restrict,

    occurred_at timestamptz
        not null
        default statement_timestamp(),

    recorded_at timestamptz
        not null
        default statement_timestamp(),

    source_system text
        constraint ck_activity_events__source_system__format
        check (
            source_system is null
            or source_system ~ '^[a-z][a-z0-9_]*$'
        ),

    correlation_id uuid,

    causation_id uuid
        constraint fk_activity_events__causation_id__activity_events
        references public.activity_events(id)
        on update restrict
        on delete restrict,

    payload jsonb
        constraint ck_activity_events__payload__object
        check (jsonb_typeof(payload) = 'object')
        not null
        default '{}'::jsonb,

    metadata jsonb
        constraint ck_activity_events__metadata__object
        check (jsonb_typeof(metadata) = 'object')
        not null
        default '{}'::jsonb,

    constraint ck_activity_events__user_actor_consistency
        check (
            (actor_type = 'user' and actor_user_id is not null)
            or
            (actor_type <> 'user')
        ),

    constraint ck_activity_events__occurred_at_reasonable
        check (occurred_at <= recorded_at + interval '5 minutes')
);

comment on table public.activity_events is
'Append-oriented event history supporting auditability, timelines, analytics, notifications, and AI context.';

comment on column public.activity_events.actor_type is
'Category of actor responsible for the event: user, system, agent, or integration.';

comment on column public.activity_events.correlation_id is
'Groups multiple events produced by the same workflow, request, or synchronization run.';

comment on column public.activity_events.causation_id is
'Optional prior event that directly caused this event.';

comment on column public.activity_events.payload is
'Event-specific immutable facts required to interpret the activity.';

comment on column public.activity_events.metadata is
'Non-authoritative operational and provenance metadata.';

create or replace function private.validate_activity_event()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_owner uuid;
begin
    if not exists (
        select 1
        from public.activity_event_types
        where code = new.event_type_code
          and is_active = true
    ) then
        raise exception 'Activity event type % is missing or inactive.',
            new.event_type_code
            using errcode = '23514';
    end if;

    if new.actor_type = 'user'
       and new.actor_user_id <> new.owner_user_id then
        raise exception 'User actor must match the event owner.'
            using errcode = '42501';
    end if;

    if new.primary_object_id is not null then
        select owner_user_id
        into v_owner
        from public.objects
        where id = new.primary_object_id
          and deleted_at is null;

        if not found then
            raise exception 'Primary object does not exist or is deleted.'
                using errcode = '23503';
        end if;

        if v_owner <> new.owner_user_id then
            raise exception 'Event owner must own the primary object.'
                using errcode = '42501';
        end if;
    end if;

    if new.secondary_object_id is not null then
        select owner_user_id
        into v_owner
        from public.objects
        where id = new.secondary_object_id
          and deleted_at is null;

        if not found then
            raise exception 'Secondary object does not exist or is deleted.'
                using errcode = '23503';
        end if;

        if v_owner <> new.owner_user_id then
            raise exception 'Event owner must own the secondary object.'
                using errcode = '42501';
        end if;
    end if;

    return new;
end;
$$;

comment on function private.validate_activity_event() is
'Validates event type, actor consistency, and ownership of linked objects before insertion.';

drop trigger if exists trg_activity_events__validate
on public.activity_events;

create trigger trg_activity_events__validate
before insert on public.activity_events
for each row
execute function private.validate_activity_event();

create or replace function private.prevent_activity_event_mutation()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog
as $$
begin
    raise exception 'Activity Ledger rows are immutable.'
        using errcode = '55000';
end;
$$;

comment on function private.prevent_activity_event_mutation() is
'Prevents updates and deletes to append-oriented Activity Ledger rows.';

drop trigger if exists trg_activity_events__prevent_mutation
on public.activity_events;

create trigger trg_activity_events__prevent_mutation
before update or delete on public.activity_events
for each row
execute function private.prevent_activity_event_mutation();

create index if not exists ix_activity_events__owner__occurred_at
    on public.activity_events(owner_user_id, occurred_at desc);

create index if not exists ix_activity_events__primary_object__occurred_at
    on public.activity_events(primary_object_id, occurred_at desc)
    where primary_object_id is not null;

create index if not exists ix_activity_events__secondary_object__occurred_at
    on public.activity_events(secondary_object_id, occurred_at desc)
    where secondary_object_id is not null;

create index if not exists ix_activity_events__event_type__occurred_at
    on public.activity_events(event_type_code, occurred_at desc);

create index if not exists ix_activity_events__correlation_id
    on public.activity_events(correlation_id)
    where correlation_id is not null;

create index if not exists ix_activity_events__payload__gin
    on public.activity_events
    using gin(payload);

alter table public.activity_event_types enable row level security;
alter table public.activity_events enable row level security;

drop policy if exists activity_event_types_select_authenticated
on public.activity_event_types;

create policy activity_event_types_select_authenticated
on public.activity_event_types
for select
to authenticated
using (is_active = true);

drop policy if exists activity_events_select_own
on public.activity_events;

create policy activity_events_select_own
on public.activity_events
for select
to authenticated
using (owner_user_id = auth.uid());

drop policy if exists activity_events_insert_own
on public.activity_events;

create policy activity_events_insert_own
on public.activity_events
for insert
to authenticated
with check (
    owner_user_id = auth.uid()
    and (
        actor_type <> 'user'
        or actor_user_id = auth.uid()
    )
);

revoke all on table public.activity_event_types from anon;
revoke all on table public.activity_events from anon;

grant select on table public.activity_event_types to authenticated;
grant select, insert on table public.activity_events to authenticated;

commit;
