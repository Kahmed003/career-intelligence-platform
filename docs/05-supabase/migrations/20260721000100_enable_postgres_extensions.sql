/*
===============================================================================
Career OS Database Migration

Migration ID:    20260721000100
Filename:        20260721000100_enable_postgres_extensions.sql
Version:         1.0.0
Purpose:         Enable the PostgreSQL extensions required by the Career OS
                 backend foundation.

Description:
  Installs a minimal, approved set of PostgreSQL extensions used by Career OS
  for cryptographic utilities, case-insensitive text handling, fuzzy search,
  and advanced indexing support.

Dependencies:
  - PostgreSQL
  - Supabase migration runner
  - Sufficient database privileges to create extensions

Affected Schemas:
  - extensions

Security Considerations:
  - Extensions are installed into the dedicated "extensions" schema.
  - No application role grants are introduced by this migration.
  - Extension functions remain governed by PostgreSQL and Supabase privileges.

Rollback Strategy:
  Extension removal is intentionally not automated because later migrations
  may depend on extension-owned types, operators, functions, or indexes.
  A rollback requires dependency analysis followed by explicit DROP EXTENSION
  statements in a dedicated forward migration.

Related Documentation:
  - docs/05-supabase/README.md
  - docs/05-supabase/03_POSTGRES_EXTENSIONS.md
  - docs/04-database/06_MIGRATION_STRATEGY.md
  - docs/04-database/07_NAMING_CONVENTIONS.md
===============================================================================
*/

begin;

/*
Create a dedicated schema for PostgreSQL extensions.

Using a dedicated schema keeps extension-owned objects separate from the
application's public API surface and reduces namespace pollution.
*/
create schema if not exists extensions;

comment on schema extensions is
'Contains PostgreSQL extension-owned objects used by the Career OS platform.';

/*
pgcrypto

Provides cryptographic functions and UUID generation utilities. Although
modern PostgreSQL versions include native UUID support, pgcrypto remains useful
for cryptographic hashing and secure random data generation.
*/
create extension if not exists pgcrypto
    with schema extensions;

/*
citext

Provides a case-insensitive text type for identity-like values where casing
must not create logically distinct records, such as normalized email aliases,
usernames, slugs, or external identifiers.
*/
create extension if not exists citext
    with schema extensions;

/*
pg_trgm

Provides trigram similarity operators and indexes used for fuzzy search,
partial matching, typo tolerance, and ranked lookup across people,
organizations, opportunities, knowledge records, and other searchable objects.
*/
create extension if not exists pg_trgm
    with schema extensions;

/*
btree_gin

Provides B-tree-equivalent operator classes for GIN indexes. This supports
future composite search indexes that combine scalar values with arrays,
documents, or full-text search expressions.
*/
create extension if not exists btree_gin
    with schema extensions;

commit;
