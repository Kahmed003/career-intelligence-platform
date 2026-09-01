## 1. Purpose

Defines the supported Supabase development, staging, and production setup for Career OS.

PostgreSQL remains the authoritative system of record. Supabase provides managed PostgreSQL, Auth, Storage, Edge Functions, migration tooling, generated types, and operational tooling.

## 2. Environments

Career OS should maintain isolated environments:

- local development;
- staging / preview;
- production.

Production data must never be copied into local development unless explicitly sanitized.

## 3. Required Tooling

- Supabase CLI
- PostgreSQL client tooling
- Node.js / package manager used by the application
- Docker-compatible local runtime when using `supabase start`
- Git

## 4. Initial Setup

Typical repository bootstrap:

```text
supabase init
supabase start
supabase db reset
```

`supabase db reset` must recreate the database entirely from committed migrations and seed data.

## 5. Environment Configuration

Application configuration should use environment variables for:

- Supabase project URL;
- public/anon client key;
- server-side service credentials where strictly required;
- external integration identifiers.

Secrets must never be committed to Git.

Service-role credentials must never be exposed to browser clients.

## 6. Migration Discipline

All database changes are forward migrations under:

```text
supabase/migrations/
```

Rules:

1. migrations are append-only after application;
2. timestamps are unique and ordered;
3. one logical responsibility per migration;
4. production corrections use new forward migrations;
5. destructive changes require rollout and recovery planning;
6. local reset must succeed from an empty database.

## 7. Local Validation

Before merging a database change:

- reset the local database;
- run database tests;
- verify RLS with authenticated user contexts;
- regenerate database types;
- run application integration tests;
- inspect migration diff for unintended changes.

## 8. Seed Data

`supabase/seed.sql` contains development/test fixtures only.

It must not contain:

- production personal data;
- OAuth tokens;
- API secrets;
- real private communications;
- confidential application materials.

## 9. Production Deployment

Production migration execution should be automated through the deployment pipeline.

Required controls:

- migration ordering;
- failure visibility;
- environment isolation;
- pre-deployment backup/recovery posture;
- post-deployment smoke tests;
- RLS verification for security-sensitive changes.

## 10. Definition of Ready

A Supabase environment is ready when:

- migrations recreate the schema successfully;
- Auth works;
- RLS tests pass;
- Storage policies pass;
- generated types are current;
- Edge Functions can access only intended resources;
- no secrets exist in tracked source files.
