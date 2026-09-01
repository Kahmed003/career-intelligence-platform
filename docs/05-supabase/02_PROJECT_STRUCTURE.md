## 1. Purpose

Defines the repository structure and ownership boundaries for the Career OS Supabase backend.

## 2. Canonical Structure

```text
supabase/
├── config.toml
├── seed.sql
├── migrations/
├── functions/
│   ├── _shared/
│   └── <function-name>/
└── tests/
    ├── database/
    ├── rls/
    ├── storage/
    └── functions/

docs/05-supabase/
├── README.md
├── 01_SETUP.md
├── 02_PROJECT_STRUCTURE.md
├── 03_POSTGRES_EXTENSIONS.md
├── 04_SHARED_ENUMS.md
├── 05_AUTHENTICATION.md
├── 06_STORAGE.md
├── 07_EDGE_FUNCTIONS.md
├── 08_TESTING.md
└── <domain and intelligence specifications>
```

## 3. Migrations

`supabase/migrations/` is the only authoritative schema history.

Do not use dashboard-only schema changes as the permanent source of truth.

Each migration should document:

- migration ID;
- purpose;
- dependencies;
- affected schemas;
- security implications;
- rollback/recovery strategy;
- related documentation.

## 4. Edge Functions

Each Edge Function owns one externally invokable capability.

Shared code belongs under `functions/_shared/`.

Functions must not become an alternative domain model. Business invariants remain in PostgreSQL where practical.

## 5. Tests

Database tests are organized by concern:

- schema and constraints;
- RLS;
- storage;
- functions;
- integration behavior.

Every user-accessible table requires an intentional access-control test.

## 6. Generated Types

Generated database types should be committed in the application type layer when the repository workflow requires reproducible builds.

Types must be regenerated after schema changes.

## 7. Naming

Use:

- snake_case for SQL objects;
- lowercase migration filenames;
- stable machine-readable codes;
- explicit constraint and index names where practical.

## 8. Ownership Boundary

The Supabase directory owns backend platform configuration and database infrastructure.

Application repositories/services own workflow orchestration.

UI code must not contain authoritative business invariants that belong in the database.
