
Career OS — Supabase Backend

Document ID: COS-SUP-README-001Version: 1.0.0Status: Approved for implementationCanonical path: docs/05-supabase/README.mdLast updated: 2026-07-21

1. Purpose

This document defines how Supabase is used as the backend platform for Career OS.

Career OS uses Supabase as a managed application platform around PostgreSQL. PostgreSQL remains the authoritative system of record and enforces the core domain model, business invariants, ownership rules, lifecycle rules, relationship integrity, and auditability.

Supabase provides:

managed PostgreSQL;

authentication;

Row-Level Security integration;

object storage;

Edge Functions;

local development tooling;

migration execution;

generated client types;

operational dashboards.

The application layer is responsible for user experience, workflow orchestration, AI coordination, and external integrations. The database is responsible for preserving domain correctness.

2. Architectural Position

Career OS follows a Foundation-Then-Vertical-Slices implementation strategy.

The shared backend foundation is built first:

PostgreSQL extensions;

shared enums and domains;

authentication integration;

users and profiles;

Object Registry;

Relationship Graph;

Activity Ledger;

shared SQL functions;

Row-Level Security;

storage policies;

test infrastructure.

After the foundation is stable, each product capability is implemented end-to-end as a vertical slice:

Domain specification
        ↓
Database migration
        ↓
Constraints and triggers
        ↓
RLS policies
        ↓
Database tests
        ↓
TypeScript repository
        ↓
Application service
        ↓
API boundary
        ↓
User interface
        ↓
AI integration
        ↓
End-to-end tests

3. Core Engineering Principles

3.1 PostgreSQL is the source of truth

The database must not rely on the frontend to preserve integrity. Invalid state must be rejected at the database boundary whenever practical.

3.2 Rich domain database

Career OS uses:

explicit foreign keys;

named constraints;

check constraints;

immutable identifiers;

lifecycle validation;

relationship validation;

ownership validation;

transaction-safe trigger functions;

audit records;

Row-Level Security;

PostgreSQL comments;

controlled database functions.

3.3 Migrations are append-only

Applied migrations must not be edited in place. Corrections are introduced through new forward migrations.

3.4 One migration per logical unit

Each migration must have one primary responsibility. A migration may include supporting objects required to make that responsibility complete and internally consistent.

3.5 Explicit security

All user-accessible tables must have an intentional RLS posture. No table is considered production-ready until its access model is documented and tested.

3.6 Least privilege

Functions, roles, storage buckets, service integrations, and API surfaces must receive only the permissions they require.

3.7 Observability and auditability

Important state changes must be reconstructable through timestamps, activity records, and audit metadata.

4. Repository Structure

career-os/
├── docs/
│   ├── 02-domain/
│   ├── 03-architecture/
│   ├── 04-database/
│   ├── 05-supabase/
│   │   ├── README.md
│   │   ├── 01_SETUP.md
│   │   ├── 02_PROJECT_STRUCTURE.md
│   │   ├── 03_POSTGRES_EXTENSIONS.md
│   │   ├── 04_SHARED_ENUMS.md
│   │   ├── 05_AUTHENTICATION.md
│   │   ├── 06_STORAGE.md
│   │   ├── 07_EDGE_FUNCTIONS.md
│   │   └── 08_TESTING.md
│   └── 09-decisions/
│
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   ├── seed.sql
│   ├── functions/
│   └── tests/
│
├── src/
│   ├── repositories/
│   ├── services/
│   ├── types/
│   └── integrations/
│
└── tests/
    ├── integration/
    └── end-to-end/

5. Migration Naming Convention

Migration filenames use a UTC timestamp prefix followed by a concise snake_case description.

YYYYMMDDHHMMSS_description.sql

Example:

20260721000100_enable_postgres_extensions.sql

Rules:

timestamps must be unique;

names must describe the database change;

filenames must use lowercase snake_case;

migrations must be ordered by dependency;

each migration must be safe to run exactly once through the migration system;

destructive changes require an explicit rollout and recovery plan.

6. Required Migration Header

Every migration must begin with a structured header containing:

migration identifier;

purpose;

dependencies;

affected schemas;

security considerations;

rollback strategy;

related documentation.

Every migration must use explicit transaction boundaries unless PostgreSQL prohibits the relevant operation inside a transaction.

7. Schema Strategy

The initial implementation uses Supabase's standard PostgreSQL schemas together with controlled Career OS schemas.

Expected schemas include:

Schema

Responsibility

auth

Supabase-managed authentication data

public

application-facing relational model

storage

Supabase-managed object storage metadata

extensions

optional installation target for supported extensions

private

internal functions and implementation details not directly exposed through the API

audit

security and audit records, when introduced

Schema introduction must occur through migrations.

8. Authentication Model

Supabase Auth owns authentication identities in auth.users.

Career OS application identity is represented separately through application tables such as:

public.profiles;

user preferences;

workspace membership records;

ownership and authorization records.

The application must not place domain-specific data directly in auth.users.

A profile record must be created transactionally or through a controlled database trigger when a new authentication identity is created.

9. Authorization and Row-Level Security

Authorization is enforced through PostgreSQL Row-Level Security.

Policies will be built from:

authenticated user identity;

canonical object ownership;

workspace or organization membership;

delegated permissions;

object visibility;

system-service privileges.

Security rules must not depend solely on client-supplied identifiers.

Every RLS-enabled table requires tests for:

owner access;

non-owner denial;

anonymous denial where applicable;

service-role behavior;

membership-based access;

mutation restrictions;

privilege escalation attempts.

10. Object Registry Foundation

Career OS uses a Hybrid Object Registry.

Every first-class domain object receives a canonical registry record containing shared identity and ownership metadata. Specialized tables hold domain-specific attributes.

The Object Registry provides:

stable identifiers;

canonical ownership;

object type;

lifecycle state;

visibility;

timestamps;

archive or deletion metadata;

cross-domain references.

Specialized tables must preserve one-to-one consistency with their registry records.

11. Relationship Graph Foundation

Career OS uses a Hybrid Relationship Graph.

Relationships are represented through a shared relationship structure for cross-domain graph traversal while domain-specific constraints remain enforceable.

The graph must support:

typed relationships;

directionality;

provenance;

temporal validity;

relationship lifecycle;

ownership;

metadata;

duplicate prevention where required.

12. Activity Ledger Foundation

Career OS uses a Hybrid Activity Ledger.

The ledger records meaningful domain events and supports:

auditability;

user timelines;

AI context assembly;

analytics;

notification generation;

historical reconstruction.

Activity records should be append-oriented. Corrections should normally be represented through compensating events rather than silent mutation.

13. PostgreSQL Extensions

Extensions are enabled only when a documented use case exists.

The initial foundation enables:

pgcrypto for UUID and cryptographic utilities;

citext for case-insensitive identity and lookup fields;

pg_trgm for indexed fuzzy search and similarity matching;

btree_gin for composite GIN indexing support where appropriate.

Extensions must be installed idempotently and documented in 03_POSTGRES_EXTENSIONS.md.

14. Local Development Workflow

The expected local workflow is:

supabase start
supabase db reset
supabase migration new <description>
supabase db lint
supabase test db
supabase gen types typescript --local

A clean database reset must reproduce the complete schema from migrations and seed data.

Generated TypeScript types must be treated as build artifacts derived from the database schema.

15. Testing Strategy

Database testing occurs at several layers.

Migration validation

migrations apply from an empty database;

migrations apply in dependency order;

schema objects exist after execution;

constraints reject invalid state.

Security testing

RLS policies enforce ownership and membership;

anonymous access is denied by default;

privileged functions cannot be abused;

service-role access is intentional.

Domain testing

invalid lifecycle transitions fail;

invalid object specialization fails;

invalid relationships fail;

duplicate relationships fail when prohibited;

immutable records cannot be silently rewritten.

Integration testing

generated types match the schema;

repositories use supported database contracts;

API workflows complete transactionally.

16. Deployment Workflow

Database changes are promoted through controlled environments:

Local
  ↓
Preview or Development
  ↓
Staging
  ↓
Production

Production deployment rules:

migrations must be reviewed;

migrations must be tested from a clean database;

destructive operations require a staged rollout;

long-running index creation must be planned;

production data backfills must be separated from schema changes when risk warrants;

rollback or forward-recovery steps must be documented.

17. SQL Engineering Standard

All production SQL must follow these rules:

lowercase unquoted identifiers;

explicit schema qualification;

explicit constraint names;

explicit foreign-key behavior;

descriptive comments;

deterministic functions where applicable;

controlled use of security definer;

fixed search_path for privileged functions;

no hidden reliance on client validation;

no destructive cascade without documented intent;

no unrestricted public execution grants;

no table without an ownership and RLS decision.

18. Definition of Done

A Supabase foundation milestone is complete only when:

the migration exists;

the migration applies cleanly;

relevant comments are present;

constraints are explicitly named;

security posture is documented;

database tests exist;

architecture documentation is updated;

generated types can be refreshed;

the repository can be rebuilt from an empty local database.

19. Initial Implementation Sequence

The first migrations are:

20260721000100_enable_postgres_extensions.sql
20260721000200_create_shared_enums.sql
20260721000300_create_users_and_profiles.sql
20260721000400_create_object_registry.sql

This order establishes capabilities before dependent tables are introduced.

20. Related Documents

docs/02-domain/DOMAIN_MODEL.md

docs/02-domain/OBJECTS.md

docs/02-domain/RELATIONSHIPS.md

docs/02-domain/LIFECYCLES.md

docs/03-architecture/ARCHITECTURE.md

docs/04-database/03_DATABASE_SCHEMA.md

docs/04-database/05_RLS_POLICIES.md

docs/04-database/06_MIGRATION_STRATEGY.md

docs/04-database/07_NAMING_CONVENTIONS.md

docs/09-decisions/ADR-0008-rich-domain-database.md

docs/09-decisions/ADR-0009-engineering-grade-sql.md

21. Change Metadata

Recommended commit message

docs(supabase): add backend architecture overview

README addition

Add the following entry to the repository root README:

- [Supabase Backend](docs/05-supabase/README.md) — backend architecture, migrations, security, testing, and deployment conventions.
