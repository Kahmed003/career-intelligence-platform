
# Career OS — Database Hardening Batch 3

**Document ID:** COS-SUP-HARD-003  
**Version:** 1.0.0  
**Status:** Approved for implementation  
**Canonical path:** `docs/05-supabase/39_DATABASE_HARDENING_BATCH_3.md`

## Purpose

Hardening Batch 3 corrects integrity and derived-intelligence issues across:

- Documents and Attachments;
- Interactions and Communications;
- Calendar Scheduling;
- Relationship Intelligence.

All changes are forward migrations. Previously applied migrations remain immutable.

## Migration Order

1. `20260721013400_harden_documents_and_attachments.sql`
2. `20260721013500_harden_interaction_consistency.sql`
3. `20260721013600_harden_calendar_synchronization.sql`
4. `20260721013700_fix_relationship_intelligence.sql`
5. `supabase/tests/database/003_hardening_batch_3.sql`

## Documents and Attachments

The attachment model supports `is_primary`, but the original schema permits multiple
primary documents for the same object and attachment role.

This migration adds a partial unique index:

```text
(object_id, attachment_role) WHERE is_primary = true
```

It also strengthens document supersession:

- same owner;
- same document type;
- new version number must exceed the superseded version.

A preflight check fails clearly if existing duplicate primary links must be resolved
before migration.

## Interaction Consistency

Application-linked interactions already enforce application/opportunity and
application/organization consistency.

This batch additionally enforces Opportunity ↔ Organization consistency when an
interaction references those objects directly without an Application.

When an Opportunity has a canonical Organization and the interaction leaves
`organization_id` empty, the trigger fills it automatically.

## Calendar Hardening

Timed calendar events now validate timezone names against PostgreSQL
`pg_timezone_names`.

External calendar synchronization is hardened by:

- replacing globally scoped external-event uniqueness with owner-scoped validation;
- preventing duplicate links from one Career OS event to the same provider/calendar;
- allowing historical `sync_error` text to remain after retry/success;
- still requiring an error message whenever current `sync_status = 'failed'`.

No OAuth credentials are stored.

## Relationship Intelligence

The original relationship-health view left-joined active interaction Objects but did
not require the active Object join to succeed, allowing soft-deleted interactions to
remain in aggregates.

The warm-introduction view also referenced `relationship_type`, while the actual
Relationship Graph column is `relationship_type_code`.

The replacement views:

- exclude soft-deleted interactions;
- use the actual relationship graph schema;
- treat `do_not_contact` as a non-actionable health state;
- preserve explainable scoring;
- retain `security_invoker = true`.

## Security

All derived views remain `security_invoker = true`.

Validation functions use:

```text
security definer
set search_path = pg_catalog, public
```

Underlying RLS remains authoritative.

## Commit

```text
fix(database): harden documents interactions calendar and relationship intelligence
```
