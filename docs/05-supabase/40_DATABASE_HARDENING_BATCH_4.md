
# Career OS — Database Hardening Batch 4

**Document ID:** COS-SUP-HARD-004  
**Version:** 1.0.0  
**Status:** Approved for implementation  
**Canonical path:** `docs/05-supabase/40_DATABASE_HARDENING_BATCH_4.md`

## Purpose

This batch hardens operational intelligence and ingestion infrastructure across:

- Opportunity Discovery;
- Notifications;
- Notes and Knowledge search;
- Recruiting Pipeline;
- Campaign deadline analytics.

All corrections are forward migrations.

## Migration Order

1. `20260721013800_harden_discovery_provenance.sql`
2. `20260721013900_harden_notification_lifecycle.sql`
3. `20260721014000_create_notes_search_interface.sql`
4. `20260721014100_harden_pipeline_application_summary.sql`
5. `20260721014200_create_campaign_deadline_pressure.sql`
6. `supabase/tests/database/004_hardening_batch_4.sql`

## Discovery Provenance

Discovery already enforces structured deduplication by `(source, external_id)` and
`(source, dedupe_key)`.

This migration adds explicit duplicate provenance:

- `duplicate_of_record_id`;
- duplicate records must identify the canonical staging record;
- duplicate links cannot self-reference;
- duplicate records must remain inside the same discovery source;
- when both a discovery run and saved search are supplied, they must agree.

This makes deduplication auditable rather than encoding only the terminal
`ingestion_status = 'duplicate'`.

## Notification Lifecycle

The original notification trigger required `failure_reason` to be cleared immediately
after leaving `failed`. That destroys useful retry history.

The hardened trigger:

- still requires `failed_at` and `failure_reason` for current failures;
- permits retained historical failure details after recovery;
- validates lifecycle transitions;
- prevents reopening terminal user states such as acknowledged/dismissed/cancelled;
- preserves timestamp ordering.

Provider delivery remains outside PostgreSQL.

## Notes Search

The existing GIN FTS index correctly indexes:

- summary;
- source name;
- content.

The canonical object title lives in `public.objects`, so it cannot be included in a
single-table expression index without denormalizing ownership/title data.

This batch creates `public.notes_knowledge_search`, a `security_invoker` view that
combines:

- canonical object title;
- note content;
- note summary;
- source name;
- a generated search vector.

It also creates `public.search_notes_knowledge(text, integer)` as the stable search API.

## Pipeline Application Summary

The original application summary filtered deleted Applications, Opportunities,
Interviews, and Offers, but a deleted Organization could still appear through a plain
left join.

The replacement view preserves the existing API while requiring any displayed
Organization to have an active canonical Object row owned by the same user.

## Campaign Deadline Pressure

The original Campaign Performance summary counts distinct deadline source objects.
That can collapse multiple actionable deadlines from one source object.

This batch introduces `public.campaign_deadline_pressure`, which counts normalized
deadline rows rather than distinct source objects and exposes:

- total deadline items;
- overdue items;
- due today;
- next 3 days;
- next 7 days;
- later;
- next due timestamp.

Future historical analytics should consume this corrected deadline-pressure view.

## Security

New views use `security_invoker = true`. Anonymous access is revoked and authenticated
read access is explicit.

## Commit

```text
fix(database): harden discovery notifications search and pipeline intelligence
```
