# Career OS Database Migration Strategy

**Document ID:** DB-006
**Version:** 1.0
**Status:** Draft
**Owner:** Ahmed Kazadi Kabuya
**Last Updated:** 2026-07-12

**Related Documents:**

* `docs/03-architecture/ARCHITECTURE.md`
* `docs/04-database/01_DATA_DICTIONARY.md`
* `docs/04-database/02_ERD.md`
* `docs/04-database/03_DATABASE_SCHEMA.md`
* `docs/04-database/04_INDEXING_STRATEGY.md`
* `docs/04-database/05_RLS_POLICIES.md`
* `docs/04-database/07_NAMING_CONVENTIONS.md`
* `docs/09-decisions/ADR-0001-postgresql-graph-compatible-model.md`
* `docs/09-decisions/ADR-0005-hybrid-object-registry.md`
* `docs/09-decisions/ADR-0006-hybrid-relationship-architecture.md`
* `docs/09-decisions/ADR-0007-hybrid-activity-ledger.md`

---

# 1. Purpose

This document defines how Career OS changes its PostgreSQL and Supabase database safely over time.

It governs:

* Schema migrations.
* Data migrations.
* Row-Level Security changes.
* Database functions and triggers.
* Index creation.
* Rollbacks.
* Backfills.
* Deployment sequencing.
* Compatibility between application and database versions.
* Migration testing.
* Production recovery.
* Migration documentation.

The objective is to keep database evolution:

* Reproducible.
* Reviewable.
* Version controlled.
* Backward compatible where practical.
* Safe for production data.
* Auditable.
* Consistent across environments.

---

# 2. Migration Principles

## 2.1 The database is changed only through migrations

Production schema changes must never be performed manually through the Supabase dashboard or ad hoc SQL console.

Every persistent change must exist in:

```text
supabase/migrations/
```

This includes:

* Tables.
* Columns.
* Constraints.
* Indexes.
* Enums.
* Functions.
* Triggers.
* Views.
* RLS policies.
* Storage policies.
* Backfills.
* Data corrections.

Emergency manual changes must be followed immediately by a migration that records the resulting state.

---

## 2.2 Migrations are immutable after application

Once a migration has been applied to a shared or production environment, it must not be edited.

Corrections require a new migration.

Bad:

```text
Edit migration 202607120001_create_objects.sql
```

Correct:

```text
Create migration 202607130001_fix_objects_constraint.sql
```

This preserves reliable migration history.

---

## 2.3 Prefer forward fixes over rollback dependence

Career OS should generally recover from migration problems by applying a corrective forward migration.

Rollback scripts may be documented, but production safety must not depend on every change being automatically reversible.

Some changes are inherently difficult to reverse:

* Data deletion.
* Data transformation.
* Enum value changes.
* Column type conversions.
* Encryption changes.
* Table consolidation.

---

## 2.4 Separate schema change from destructive cleanup

Large or breaking changes should use multiple migrations.

Example:

```text
1. Add replacement column.
2. Begin writing to old and new columns.
3. Backfill existing records.
4. Switch reads to new column.
5. Stop writing to old column.
6. Verify.
7. Remove old column later.
```

Do not combine all steps into one production migration unless the table is small and the risk is demonstrably low.

---

## 2.5 Preserve compatibility during deployment

Application and database deployments may not become active at precisely the same time.

Migrations should therefore support a short compatibility window in which:

* The old application can work with the new schema.
* The new application can work before destructive cleanup occurs.

This is the expand-and-contract migration pattern.

---

## 2.6 Production data must be treated as irreplaceable

Before performing a high-risk migration:

* Verify backups.
* Estimate affected rows.
* Test on production-like data.
* Confirm rollback or recovery steps.
* Monitor execution.
* Record the migration owner.

---

# 3. Migration Tooling

Career OS uses Supabase CLI migrations.

Primary commands include:

```bash
supabase migration new <migration_name>
```

```bash
supabase db reset
```

```bash
supabase db diff
```

```bash
supabase db push
```

```bash
supabase migration list
```

Exact commands may evolve with Supabase tooling, but the repository remains the authoritative migration source.

---

# 4. Migration File Location

All database migrations are stored in:

```text
supabase/migrations/
```

Example:

```text
supabase/
└── migrations/
    ├── 202607120001_enable_extensions.sql
    ├── 202607120002_create_shared_enums.sql
    ├── 202607120003_create_users.sql
    ├── 202607120004_create_object_registry.sql
    └── 202607120005_create_relationships.sql
```

Supabase-generated timestamp prefixes establish execution order.

---

# 5. Migration Naming Convention

Use:

```text
<timestamp>_<verb>_<subject>.sql
```

Preferred verbs:

* `enable`
* `create`
* `add`
* `alter`
* `rename`
* `backfill`
* `migrate`
* `drop`
* `fix`
* `replace`
* `rebuild`

Examples:

```text
202607120001_enable_postgres_extensions.sql
202607120002_create_shared_enums.sql
202607120003_create_users_and_profiles.sql
202607120004_create_object_registry.sql
202607120005_add_object_search_indexes.sql
202607120006_backfill_object_status.sql
202607120007_replace_relationship_constraint.sql
```

Avoid vague names:

```text
update_database.sql
schema_changes.sql
fix_stuff.sql
migration_final.sql
```

---

# 6. Migration Categories

## 6.1 Foundation migrations

Create:

* Extensions.
* Shared schemas.
* Shared enums.
* Common functions.
* Updated-at triggers.

## 6.2 Structural migrations

Create or alter:

* Tables.
* Columns.
* Foreign keys.
* Constraints.
* Views.
* Functions.

## 6.3 Security migrations

Create or alter:

* RLS enablement.
* RLS policies.
* Security-definer functions.
* Storage policies.
* Grants.
* Revocations.

## 6.4 Index migrations

Create or remove:

* B-tree indexes.
* Partial indexes.
* GIN indexes.
* Trigram indexes.
* Future vector indexes.

## 6.5 Data migrations

Transform or backfill existing records.

Examples:

* Populate `objects.status`.
* Create Object Registry records for existing Projects.
* Normalize Organization names.
* Migrate free-text Skills into Skill objects.

## 6.6 Cleanup migrations

Remove:

* Deprecated columns.
* Old triggers.
* Temporary compatibility views.
* Obsolete tables.
* Superseded constraints.

Cleanup should occur only after successful verification.

---

# 7. Initial Migration Plan

The first schema implementation should be divided into the following groups.

## Migration group 001 — Extensions and shared infrastructure

Create:

* `pgcrypto`
* `citext`
* `pg_trgm`
* Shared enum types.
* `set_updated_at()` function.
* Common helper schemas if needed.

## Migration group 002 — Identity

Create:

* `users`
* `user_profiles`
* `user_preferences`
* Auth-user provisioning trigger.

## Migration group 003 — Universal object platform

Create:

* `objects`
* `relationships`
* `activities`
* `activity_objects`
* `lifecycle_transitions`
* `tags`
* `object_tags`

## Migration group 004 — Strategy

Create:

* `goals`
* `goal_milestones`
* `decisions`
* `decision_options`
* `decision_criteria`
* `decision_evaluations`
* `assets`
* `asset_measurements`

## Migration group 005 — Projects and execution

Create:

* `projects`
* `project_milestones`
* `deliverables`
* `tasks`
* `task_objects`
* `task_dependencies`
* `time_blocks`
* `reminders`

## Migration group 006 — People and organizations

Create:

* `people`
* `organizations`
* `person_organization_affiliations`
* `professional_relationships`
* `interactions`
* `interaction_participants`

## Migration group 007 — Opportunities and applications

Create:

* `opportunities`
* `opportunity_requirements`
* `applications`
* `application_stage_history`
* `assessments`
* `interviews`

## Migration group 008 — Skills, knowledge, and evidence

Create:

* `skills`
* `user_skills`
* `knowledge_items`
* `knowledge_versions`
* `evidence`
* `evidence_claims`
* `citations`
* `skill_evidence`

## Migration group 009 — Documents and files

Create:

* `file_objects`
* `documents`
* `document_versions`
* `application_documents`
* `attachments`

## Migration group 010 — Integrations and ingestion

Create:

* `integration_accounts`
* `integration_credentials`
* `sync_cursors`
* `sync_jobs`
* `ingestion_candidates`
* `approval_requests`
* `external_references`
* `email_records`
* `email_object_links`
* `calendar_events`
* `calendar_event_object_links`

## Migration group 011 — Intelligence

Create:

* `insights`
* `recommendations`
* `scores`
* `score_factors`
* `career_risks`
* `daily_missions`
* `daily_mission_items`
* `weekly_strategies`
* `intelligence_inputs`
* `ai_feedback`

## Migration group 012 — Operations

Create:

* `notifications`
* `audit_logs`
* `background_jobs`

## Migration group 013 — Integrity automation

Create:

* Object-type validation functions.
* Status-synchronization triggers.
* Updated-at triggers.
* Lifecycle recording helpers.
* Projection synchronization where approved.

## Migration group 014 — Row-Level Security

* Enable RLS.
* Create ownership helper functions.
* Add user policies.
* Add server-only restrictions.
* Revoke unsafe default privileges.

## Migration group 015 — Indexes

Implement the initial index set defined in:

```text
docs/04-database/04_INDEXING_STRATEGY.md
```

## Migration group 016 — Seed reference data

Seed stable controlled data such as:

* Initial relationship ontology values, if represented in tables.
* Supported object types.
* Initial system preferences.
* Default lifecycle definitions, if database-driven.

User-specific demo data must remain separate from production migrations.

---

# 8. Expand-and-Contract Pattern

Breaking changes must normally follow three stages.

## Stage 1 — Expand

Add the new structure without removing the old structure.

Example:

```sql
alter table public.opportunities
  add column deadline_at timestamptz;
```

The existing `application_deadline` remains temporarily.

## Stage 2 — Migrate

Backfill the new column and update the application to support both fields.

Example:

```sql
update public.opportunities
set deadline_at = application_deadline
where deadline_at is null;
```

## Stage 3 — Contract

After verification and application rollout:

* Stop reading the old field.
* Stop writing the old field.
* Remove the old field in a later migration.

```sql
alter table public.opportunities
  drop column application_deadline;
```

Destructive contraction should not occur in the same deployment as expansion unless the system is offline and data volume is trivial.

---

# 9. Adding a Column

## Safe addition

Adding a nullable column is generally safe:

```sql
alter table public.projects
  add column portfolio_summary text;
```

## Adding a required column

Do not immediately add a non-null column without a default to a populated table.

Preferred sequence:

```sql
alter table public.projects
  add column strategic_value text;
```

Backfill:

```sql
update public.projects
set strategic_value = 'unclassified'
where strategic_value is null;
```

Then enforce:

```sql
alter table public.projects
  alter column strategic_value set not null;
```

For large tables, perform the backfill in batches.

---

# 10. Renaming a Column

Direct renaming may break older application versions.

Preferred compatibility strategy:

1. Add new column.
2. Backfill.
3. Dual-write temporarily.
4. Switch reads.
5. Remove old column later.

Direct renaming is acceptable during pre-production development when no shared environment depends on the old name.

---

# 11. Changing a Column Type

Type changes must be evaluated for:

* Lock duration.
* Rewrite cost.
* Invalid existing values.
* Application compatibility.
* Data precision loss.

For risky changes, add a replacement column and migrate gradually.

Example:

```sql
alter table public.assets
  add column current_level_v2 numeric(10,4);
```

Then backfill, verify, switch usage, and remove the original field later.

---

# 12. Adding Constraints

Constraints on populated tables may fail or lock the table.

Preferred PostgreSQL pattern:

```sql
alter table public.tasks
  add constraint tasks_priority_range
  check (priority between 1 and 5)
  not valid;
```

Validate separately:

```sql
alter table public.tasks
  validate constraint tasks_priority_range;
```

This separates creation from validation and can reduce disruption.

Before adding a unique constraint:

* Identify duplicates.
* Resolve duplicates.
* Create a unique index concurrently where appropriate.
* Attach the constraint if required.

---

# 13. Adding Foreign Keys

Before adding a foreign key:

1. Confirm every referenced value exists.
2. Decide the correct deletion behavior.
3. Index the referencing column where needed.
4. Evaluate table-lock impact.
5. Test orphan cleanup.

For populated high-volume tables, consider:

```sql
alter table ...
  add constraint ...
  foreign key (...)
  references ...
  not valid;
```

Then validate separately.

---

# 14. Creating Indexes

For production tables with meaningful data volume, prefer:

```sql
create index concurrently
```

when supported by the migration execution environment.

Important:

* `CREATE INDEX CONCURRENTLY` cannot run inside a standard transaction block.
* The migration must be structured accordingly.
* Failure can leave an invalid index requiring cleanup.

Small early-stage tables may use ordinary `CREATE INDEX`.

Index migrations should reference the query path they support in SQL comments.

Example:

```sql
-- Supports Mission Control retrieval of open tasks by due date.
create index idx_tasks__owner_status_due__active
  on public.tasks (owner_user_id, status, due_at)
  where archived_at is null
    and status not in ('completed', 'cancelled');
```

---

# 15. Enum Migrations

PostgreSQL enums require careful handling.

Adding an enum value is generally forward-only:

```sql
alter type integration_provider
  add value if not exists 'microsoft';
```

Renaming or removing enum values is more complex.

For frequently changing concepts, use:

* Lookup tables.
* Constrained text.
* Domain validation.

Do not use PostgreSQL enums for fast-changing relationship, activity, or object ontologies.

---

# 16. Data Backfills

Backfills must be:

* Idempotent where practical.
* Measurable.
* Restartable.
* Observable.
* Safe under partial completion.

## Small backfills

May run directly inside a migration.

## Large backfills

Should use:

* A background job.
* A dedicated script.
* Batches.
* Progress tracking.
* Retry behavior.

Example batch key:

```text
last_processed_id
```

Backfills must record:

* Expected row count.
* Processed row count.
* Failed row count.
* Verification query.
* Completion criteria.

---

# 17. Object Registry Backfills

Introducing a new first-class object type requires:

1. Add the object type to application validation.
2. Create Object Registry rows.
3. Populate the domain table using matching UUIDs.
4. Create initial lifecycle transitions.
5. Create creation Activities.
6. Verify one-to-one object specialization.
7. Enable application reads.
8. Add required indexes and RLS policies.

A domain record must never exist without its required Object Registry row.

---

# 18. Relationship Ontology Migrations

Relationship types are controlled domain vocabulary.

When introducing a new relationship type:

1. Update `RELATIONSHIPS.md`.
2. Update validation schemas.
3. Add database lookup or validation data if used.
4. Add any required uniqueness indexes.
5. Add inverse projection logic where appropriate.
6. Add graph query tests.

Renaming a relationship type requires a data migration.

Example:

```sql
update public.relationships
set relationship_type = 'SUPPORTS_GOAL'
where relationship_type = 'SUPPORTS';
```

The old and new application versions must remain compatible during deployment, or a mapping layer must be introduced.

---

# 19. Lifecycle Migrations

Changing lifecycle states can affect:

* Domain records.
* Partial indexes.
* RLS policies.
* Mission Control.
* Analytics.
* Notifications.
* AI prompts.
* Application validation.

Before changing a lifecycle:

1. Update `LIFECYCLES.md`.
2. Identify all existing records using affected states.
3. Define state mapping.
4. Update partial indexes.
5. Update checks and validation.
6. Backfill records.
7. Verify current-state consistency.
8. Preserve historical transition values.

Historical lifecycle transitions should normally retain the terminology that existed at the time unless there is a compelling reason to rewrite history.

---

# 20. RLS Migration Rules

RLS changes require security review.

Every RLS migration must test:

* Owner access.
* Non-owner denial.
* Anonymous denial.
* Service-role behavior.
* Insert ownership validation.
* Update ownership validation.
* Delete behavior.
* Ownership inheritance.

Safe sequence for a new table:

1. Create table.
2. Revoke broad privileges.
3. Enable RLS.
4. Add policies.
5. Add tests.
6. Expose through application code.

A user-facing table must not be released while RLS is incomplete.

---

# 21. Security-Definer Function Migrations

Security-definer functions require explicit review.

Each function must:

* Use a fixed `search_path`.
* Validate the authenticated user.
* Limit accessible data.
* Avoid dynamic SQL where possible.
* Return the minimum required fields.
* Be inaccessible to unauthorized roles.
* Be covered by tests.
* Be documented in security specifications.

Example pattern:

```sql
create or replace function public.is_object_owner(object_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.objects
    where id = object_uuid
      and owner_user_id = auth.uid()
  );
$$;
```

Function grants must be explicit.

---

# 22. Trigger Migrations

Triggers should be used only when database-level enforcement provides clear value.

Approved trigger categories include:

* `updated_at`
* Object-type integrity.
* Object status synchronization.
* User-profile creation.
* Append-only protection.
* Projection consistency.

Avoid triggers that hide complex business workflows from the application layer.

Every trigger must document:

* Event.
* Timing.
* Target table.
* Function.
* Failure behavior.
* Testing approach.

---

# 23. Migration Transactions

Use transactions for migrations that can safely run atomically.

Example:

```sql
begin;

create table ...;
alter table ...;
create policy ...;

commit;
```

Do not wrap operations that PostgreSQL forbids inside transactions, such as certain concurrent index operations.

Large data backfills should not hold one long transaction when batching is safer.

---

# 24. Rollback Strategy

Each migration should be classified as:

## Reversible

Can be safely undone without data loss.

Example:

* Add unused nullable column.
* Create index.
* Create view.

## Conditionally reversible

Can be undone only before new data depends on it.

Example:

* Add table used by a new application version.
* Add relationship type.
* Add lifecycle state.

## Irreversible

Undoing would destroy or corrupt data.

Example:

* Drop populated column.
* Merge records.
* Encrypt using a new irreversible format without retaining the old key.
* Delete records.

For irreversible changes, the pull request must describe recovery from backup or corrective forward migration.

---

# 25. Backup and Recovery Requirements

Before high-risk production migrations:

* Confirm automated database backups are healthy.
* Confirm point-in-time recovery availability where supported.
* Record the latest recoverable timestamp.
* Verify storage and external file implications.
* Confirm OAuth credentials are separately recoverable or reconnectable.

Database backups do not automatically guarantee restoration of:

* External Gmail content.
* Google Calendar content.
* Supabase Storage objects.
* Third-party API state.

Recovery procedures must consider all persistent systems.

---

# 26. Migration Environments

## Local

Used for development and complete schema rebuilds.

Developers should regularly run:

```bash
supabase db reset
```

to confirm that all migrations execute successfully from an empty database.

## Preview

Used for pull-request validation where available.

## Staging

Used for:

* Production-like migration testing.
* Integration testing.
* Backfill validation.
* RLS testing.
* Performance evaluation.

## Production

Receives only reviewed migrations that passed automated and staging checks.

Each environment must have its own database and secrets.

---

# 27. Migration Development Workflow

## Step 1 — Update specifications

Update relevant documentation:

* Data Dictionary.
* ERD.
* Database Schema.
* RLS Policies.
* Indexing Strategy.
* ADR, when architectural.

## Step 2 — Create migration

```bash
supabase migration new <descriptive_name>
```

## Step 3 — Implement SQL

Include comments explaining:

* Purpose.
* Canonical owner.
* Risk.
* Compatibility assumptions.

## Step 4 — Reset locally

```bash
supabase db reset
```

Confirm the entire migration chain works from zero.

## Step 5 — Test upgrade path

Test migration against a database containing representative prior-version data.

## Step 6 — Run automated tests

Include:

* Schema tests.
* Constraint tests.
* RLS tests.
* Backfill tests.
* Application integration tests.

## Step 7 — Review generated diff

Confirm no unintended schema changes are included.

## Step 8 — Review pull request

At least one reviewer should examine high-risk migrations before production.

## Step 9 — Deploy to staging

Validate:

* Migration execution.
* Application compatibility.
* Data integrity.
* Query performance.
* RLS.
* Integration behavior.

## Step 10 — Deploy to production

Monitor migration and application health.

## Step 11 — Verify

Run documented post-migration checks.

---

# 28. Migration Pull Request Requirements

Every migration pull request should include:

## Summary

What changes?

## Motivation

Why is it needed?

## Affected tables

List all affected database objects.

## Data impact

How many records may be affected?

## Compatibility

Can old and new application versions coexist?

## Security impact

Does it change RLS, credentials, sensitive fields, or privileges?

## Performance impact

Does it lock or rewrite a table?

## Backfill

Is one required?

## Verification

Which SQL queries prove success?

## Recovery

What happens if the migration fails?

## Documentation

Which documents were updated?

---

# 29. Migration Risk Levels

## Low risk

Examples:

* Add nullable column.
* Add non-blocking index to small table.
* Add view.
* Add optional metadata.

Requirements:

* Normal review.
* Automated tests.

## Medium risk

Examples:

* Add foreign key.
* Add RLS policy.
* Add non-null constraint after backfill.
* Change application workflow state.
* Add trigger.

Requirements:

* Staging validation.
* Explicit verification queries.
* Recovery plan.

## High risk

Examples:

* Drop column or table.
* Rewrite a large table.
* Change encryption.
* Change ownership model.
* Migrate Object Registry identity.
* Alter critical RLS helper functions.
* Merge or deduplicate records.

Requirements:

* Architecture review.
* Backup verification.
* Staging rehearsal.
* Deployment plan.
* Monitoring.
* Explicit approval.

---

# 30. Migration Testing

## 30.1 Clean-database test

All migrations must apply successfully from an empty database.

## 30.2 Upgrade test

Migrations must apply to the prior released schema containing representative data.

## 30.3 Idempotency test

Backfill scripts and helper functions should behave safely when rerun where practical.

## 30.4 Constraint test

Verify invalid records are rejected.

Examples:

* Cross-user relationship.
* Task depending on itself.
* End time before start time.
* Invalid confidence score.
* Domain record with incorrect object type.

## 30.5 RLS test

Verify access boundaries across at least two test users.

## 30.6 Application compatibility test

Verify the application can start and complete critical workflows after migration.

## 30.7 Performance test

Use representative row counts and `EXPLAIN ANALYZE` for important altered queries.

---

# 31. Post-Migration Verification

Each production migration should define verification queries.

Examples:

## Confirm migration applied

```sql
select *
from supabase_migrations.schema_migrations
order by version desc;
```

## Confirm no orphan Project records

```sql
select p.object_id
from public.projects p
left join public.objects o on o.id = p.object_id
where o.id is null;
```

## Confirm Object type integrity

```sql
select p.object_id, o.object_type
from public.projects p
join public.objects o on o.id = p.object_id
where o.object_type <> 'project';
```

## Confirm current status synchronization

```sql
select o.id, o.status, p.status
from public.objects o
join public.projects p on p.object_id = o.id
where o.status <> p.status;
```

## Confirm no cross-owner relationship

```sql
select r.id
from public.relationships r
join public.objects source on source.id = r.source_object_id
join public.objects target on target.id = r.target_object_id
where r.owner_user_id <> source.owner_user_id
   or r.owner_user_id <> target.owner_user_id;
```

Verification queries should return zero unexpected rows.

---

# 32. Migration Failure Handling

If a migration fails before completion:

1. Stop application deployment.
2. Determine whether the transaction rolled back.
3. Check for partially created indexes or objects.
4. Review database logs.
5. Do not rerun blindly.
6. Repair with a reviewed corrective migration.
7. Re-test in staging.
8. Record the incident.

If the migration succeeded but the application fails:

* Roll back the application deployment where schema compatibility permits.
* Keep the expanded schema in place.
* Apply a corrective application or forward database migration.

---

# 33. Data Correction Migrations

Data corrections should be explicit and auditable.

Avoid untracked manual updates.

A correction migration should document:

* How incorrect data was identified.
* Which records are affected.
* The intended corrected state.
* Verification queries.
* Whether Activities or Audit Logs must record the correction.

For user-visible historical corrections, create an Activity explaining the correction where appropriate.

---

# 34. Migration and Activity History

Database migrations and user-domain Activities are different.

A schema migration should not automatically create user-facing Activities unless it changes the user’s meaningful domain state.

Example:

* Adding an index: no user Activity.
* Correcting an Application stage: create a user-visible Activity.
* Migrating a relationship type name without changing meaning: usually no Activity.
* Merging duplicate People: likely create an Activity.

---

# 35. Seed Data Strategy

## System seed data

Version-controlled system seed data may include:

* Object-type definitions.
* Stable controlled vocabulary.
* Default notification preferences.
* Lifecycle definitions if stored as data.

## Development seed data

Development fixtures should include:

* Demo User.
* Opportunities.
* Applications.
* People.
* Projects.
* Tasks.
* Relationships.
* Activities.

Development seed data must not run automatically in production.

## User data

Real user data must never be committed to the repository.

---

# 36. Migration Documentation Register

Maintain migration summaries in either:

```text
docs/04-database/MIGRATION_LOG.md
```

or release notes.

Each production release should record:

* Migration versions.
* Schema changes.
* Backfills.
* Breaking changes.
* Required operational steps.

The migration files remain the technical source of truth.

---

# 37. Migration Ownership

Every migration should have a responsible author or reviewer.

For high-risk migrations, identify:

* Migration owner.
* Deployment operator.
* Reviewer.
* Recovery decision-maker.

For the current project stage, these roles may all be Ahmed and the AI development workflow, but the responsibilities should remain conceptually distinct.

---

# 38. Destructive Change Checklist

Before dropping or irreversibly changing data, confirm:

* Is the field truly unused?
* Is the application no longer reading it?
* Is the application no longer writing it?
* Has data been copied to the replacement?
* Has the replacement been verified?
* Do backups exist?
* Are dependent views, triggers, functions, and policies updated?
* Are search projections updated?
* Are AI prompts and pipelines updated?
* Are integrations affected?
* Is the deletion legally and operationally acceptable?
* Is an ADR required?

---

# 39. Migration Acceptance Criteria

The migration strategy is complete when:

* All schema changes are version controlled.
* Applied migrations are immutable.
* Naming rules are defined.
* Initial migration sequencing is documented.
* Expand-and-contract is the default breaking-change pattern.
* RLS changes require security testing.
* Object Registry changes preserve type integrity.
* Data backfills are restartable and verifiable.
* High-risk changes require backups and staging rehearsals.
* Clean database and upgrade paths are both tested.
* Production verification queries are required.
* Recovery responsibilities are clear.
* Manual production changes are prohibited except for documented emergencies.

---

# 40. Next Documents

* `docs/04-database/07_NAMING_CONVENTIONS.md`
* `docs/03-architecture/SECURITY.md`
* `supabase/migrations/`
* `supabase/seed/`

