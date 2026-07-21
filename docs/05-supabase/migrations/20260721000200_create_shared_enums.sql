/*
===============================================================================
Career OS Database Migration

Migration ID:    20260721000200
Filename:        20260721000200_create_shared_enums.sql
Version:         1.0.0
Purpose:         Create stable PostgreSQL enum types shared across the
                 Career OS domain model.

Description:
  Introduces a minimal set of closed, cross-domain value types for canonical
  lifecycle state, visibility, relationship directionality, and activity actor
  classification.

Dependencies:
  - 20260721000100_enable_postgres_extensions.sql

Affected Schemas:
  - public

Security Considerations:
  - This migration creates data types only.
  - It grants no privileges and creates no executable functions.
  - Row-Level Security remains the responsibility of table migrations.

Rollback Strategy:
  Enum removal is not automated because dependent columns, functions, views,
  policies, or generated types may exist. Removal requires dependency analysis
  and a dedicated forward migration.

Related Documentation:
  - docs/05-supabase/04_SHARED_ENUMS.md
  - docs/04-database/03_DATABASE_SCHEMA.md
  - docs/04-database/06_MIGRATION_STRATEGY.md
  - docs/04-database/07_NAMING_CONVENTIONS.md
===============================================================================
*/

begin;

/*
Canonical lifecycle state shared by first-class Career OS objects.

Domain-specific tables may define additional workflow states, but those states
must remain compatible with this high-level lifecycle classification.
*/
do $migration$
begin
    if not exists (
        select 1
        from pg_catalog.pg_type as t
        join pg_catalog.pg_namespace as n
          on n.oid = t.typnamespace
        where n.nspname = 'public'
          and t.typname = 'lifecycle_status'
    ) then
        create type public.lifecycle_status as enum (
            'draft',
            'active',
            'paused',
            'completed',
            'cancelled',
            'archived'
        );
    end if;
end;
$migration$;

comment on type public.lifecycle_status is
'Canonical high-level lifecycle state shared by first-class Career OS objects.';

/*
Default visibility boundary for a Career OS object.

Visibility is authorization metadata. It does not replace ownership checks,
membership checks, or Row-Level Security policies.
*/
do $migration$
begin
    if not exists (
        select 1
        from pg_catalog.pg_type as t
        join pg_catalog.pg_namespace as n
          on n.oid = t.typnamespace
        where n.nspname = 'public'
          and t.typname = 'visibility_scope'
    ) then
        create type public.visibility_scope as enum (
            'private',
            'shared',
            'public'
        );
    end if;
end;
$migration$;

comment on type public.visibility_scope is
'Default visibility boundary used as one input into Career OS authorization decisions.';

/*
Relationship graph directionality.

Directed relationships distinguish source and target semantics. Undirected
relationships are symmetric and require canonical endpoint ordering when
duplicate prevention is implemented.
*/
do $migration$
begin
    if not exists (
        select 1
        from pg_catalog.pg_type as t
        join pg_catalog.pg_namespace as n
          on n.oid = t.typnamespace
        where n.nspname = 'public'
          and t.typname = 'relationship_directionality'
    ) then
        create type public.relationship_directionality as enum (
            'directed',
            'undirected'
        );
    end if;
end;
$migration$;

comment on type public.relationship_directionality is
'Indicates whether graph relationship endpoint order has semantic meaning.';

/*
Activity actor category.

This classification supports audit interpretation, activity timelines,
authorization review, and AI provenance without coupling the ledger to a
single actor table.
*/
do $migration$
begin
    if not exists (
        select 1
        from pg_catalog.pg_type as t
        join pg_catalog.pg_namespace as n
          on n.oid = t.typnamespace
        where n.nspname = 'public'
          and t.typname = 'activity_actor_type'
    ) then
        create type public.activity_actor_type as enum (
            'user',
            'system',
            'agent',
            'integration'
        );
    end if;
end;
$migration$;

comment on type public.activity_actor_type is
'Category of actor responsible for a Career OS activity-ledger event.';

commit;
