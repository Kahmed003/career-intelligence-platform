/*
===============================================================================
Career OS Database Migration

Migration ID:    20260721000400
Filename:        20260721000400_create_object_registry.sql
Version:         1.0.0
Purpose:         Create the canonical Object Registry used by every first-class
                 Career OS domain entity.

Dependencies:
  - 20260721000100_enable_postgres_extensions.sql
  - 20260721000200_create_shared_enums.sql
  - 20260721000300_create_users_and_profiles.sql

Affected Schemas:
  - public
  - private

Security Considerations:
  - Row-Level Security is enabled immediately.
  - Initial policies restrict access to the canonical owner.
  - No anonymous access is granted.
  - Shared and workspace authorization will be introduced later.

Rollback Strategy:
  Dropping the registry is destructive and will eventually cascade into every
  specialized domain table. Rollback requires a dedicated forward migration
  after dependency and data-retention analysis.

Related Documentation:
  - docs/05-supabase/06_OBJECT_REGISTRY.md
  - docs/02-domain/OBJECTS.md
  - docs/04-database/03_DATABASE_SCHEMA.md
  - docs/04-database/05_RLS_POLICIES.md
===============================================================================
*/

begin;

create schema if not exists private;

/*
Maintains updated_at consistently for mutable application tables.
*/
create or replace function private.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog
as $function$
begin
    new.updated_at = statement_timestamp();
    return new;
end;
$function$;

comment on function private.set_updated_at() is
'Sets a row updated_at column to the current statement timestamp before update.';

create table if not exists public.objects (
    id uuid
        constraint pk_objects
        primary key
        default extensions.gen_random_uuid(),

    owner_user_id uuid
        constraint fk_objects__owner_user_id__profiles
        not null
        references public.profiles(id)
        on update restrict
        on delete restrict,

    object_type text
        constraint ck_objects__object_type__format
        check (object_type ~ '^[a-z][a-z0-9_]*$')
        constraint ck_objects__object_type__supported
        check (
            object_type in (
                'project',
                'task',
                'person',
                'organization',
                'opportunity',
                'application',
                'knowledge',
                'evidence',
                'recommendation'
            )
        )
        not null,

    title text
        constraint ck_objects__title__not_blank
        check (length(btrim(title)) > 0)
        not null,

    lifecycle_status public.lifecycle_status
        not null
        default 'draft',

    visibility public.visibility_scope
        not null
        default 'private',

    metadata jsonb
        constraint ck_objects__metadata__object
        check (jsonb_typeof(metadata) = 'object')
        not null
        default '{}'::jsonb,

    created_at timestamptz
        not null
        default statement_timestamp(),

    updated_at timestamptz
        not null
        default statement_timestamp(),

    archived_at timestamptz,

    deleted_at timestamptz,

    constraint ck_objects__archived_state_consistency
        check (
            (lifecycle_status = 'archived' and archived_at is not null)
            or
            (lifecycle_status <> 'archived' and archived_at is null)
        ),

    constraint ck_objects__deleted_after_created
        check (deleted_at is null or deleted_at >= created_at),

    constraint ck_objects__archived_after_created
        check (archived_at is null or archived_at >= created_at)
);

comment on table public.objects is
'Canonical identity, ownership, lifecycle, visibility, and metadata registry for every first-class Career OS object.';

comment on column public.objects.id is
'Canonical UUID shared with the corresponding specialized domain table.';

comment on column public.objects.owner_user_id is
'Canonical owner used as the primary input to Row-Level Security.';

comment on column public.objects.object_type is
'Stable lowercase machine-readable code identifying the specialized domain type.';

comment on column public.objects.title is
'Human-readable primary label used across search, navigation, and activity views.';

comment on column public.objects.lifecycle_status is
'Canonical high-level lifecycle state shared across domain types.';

comment on column public.objects.visibility is
'Default visibility boundary; authorization remains enforced by RLS.';

comment on column public.objects.metadata is
'Non-authoritative extensible JSON metadata. Core relational facts must use typed columns or tables.';

comment on column public.objects.archived_at is
'Timestamp at which the object entered the archived lifecycle state.';

comment on column public.objects.deleted_at is
'Soft-deletion timestamp. Non-null values exclude the object from normal active use.';

drop trigger if exists trg_objects__set_updated_at on public.objects;

create trigger trg_objects__set_updated_at
before update on public.objects
for each row
execute function private.set_updated_at();

create index if not exists ix_objects__owner_user_id__active
    on public.objects(owner_user_id, created_at desc)
    where deleted_at is null;

create index if not exists ix_objects__owner_user_id__lifecycle_status
    on public.objects(owner_user_id, lifecycle_status)
    where deleted_at is null;

create index if not exists ix_objects__object_type__lifecycle_status
    on public.objects(object_type, lifecycle_status)
    where deleted_at is null;

create index if not exists ix_objects__created_at__active
    on public.objects(created_at desc)
    where deleted_at is null;

create index if not exists ix_objects__metadata__gin
    on public.objects
    using gin(metadata);

create index if not exists ix_objects__title__trgm
    on public.objects
    using gin(title extensions.gin_trgm_ops);

alter table public.objects enable row level security;

drop policy if exists objects_select_own on public.objects;
create policy objects_select_own
on public.objects
for select
to authenticated
using (owner_user_id = auth.uid());

drop policy if exists objects_insert_own on public.objects;
create policy objects_insert_own
on public.objects
for insert
to authenticated
with check (owner_user_id = auth.uid());

drop policy if exists objects_update_own on public.objects;
create policy objects_update_own
on public.objects
for update
to authenticated
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

drop policy if exists objects_delete_own on public.objects;
create policy objects_delete_own
on public.objects
for delete
to authenticated
using (owner_user_id = auth.uid());

revoke all on table public.objects from anon;
grant select, insert, update, delete on table public.objects to authenticated;

commit;
