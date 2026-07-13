# Career OS PostgreSQL Database Schema

**Document ID:** DB-003
**Version:** 1.0
**Status:** Draft
**Owner:** Ahmed Kazadi Kabuya
**Last Updated:** 2026-07-12

**Related Documents:**

* `docs/01-product/PRD.md`
* `docs/02-domain/DOMAIN_MODEL.md`
* `docs/02-domain/OBJECTS.md`
* `docs/02-domain/RELATIONSHIPS.md`
* `docs/02-domain/LIFECYCLES.md`
* `docs/03-architecture/ARCHITECTURE.md`
* `docs/04-database/01_DATA_DICTIONARY.md`
* `docs/04-database/02_ERD.md`
* `docs/09-decisions/ADR-0001-postgresql-graph-compatible-model.md`
* `docs/09-decisions/ADR-0005-hybrid-object-registry.md`
* `docs/09-decisions/ADR-0006-hybrid-relationship-architecture.md`
* `docs/09-decisions/ADR-0007-hybrid-activity-ledger.md`
* `docs/09-decisions/ADR-0008-intelligent-ai-persistence.md`

---

# 1. Purpose

This document specifies the logical PostgreSQL schema for Career OS.

It defines:

* PostgreSQL table names.
* Column names.
* Suggested data types.
* Primary keys.
* Foreign keys.
* Unique constraints.
* Check constraints.
* Deletion behavior.
* Archive behavior.
* Object Registry participation.
* Canonical ownership.
* Enum strategy.
* Timestamp standards.
* JSON usage boundaries.
* Sensitive-data handling requirements.

This specification is intended to guide:

* Supabase migrations.
* Generated TypeScript types.
* Row-Level Security policies.
* Repository implementations.
* API contracts.
* Test fixtures.
* Seed data.

This document does not yet define every index or every RLS policy. Those are covered in separate specifications.

---

# 2. PostgreSQL Conventions

## 2.1 Identifier format

Use:

* `snake_case` for tables, columns, constraints, indexes, and database functions.
* Plural nouns for table names.
* Singular conceptual names for enum types.

Examples:

```sql
application_stage
integration_provider
relationship_origin
```

## 2.2 Primary keys

Use UUID primary keys.

Preferred implementation:

```sql
id uuid primary key default gen_random_uuid()
```

Object-specialization tables use:

```sql
object_id uuid primary key references objects(id)
```

## 2.3 User references

Supabase authentication users are referenced through:

```sql
auth.users(id)
```

Application-facing user records are stored in:

```sql
public.users
```

`public.users.id` should match `auth.users.id`.

## 2.4 Timestamps

Use:

```sql
timestamptz
```

for event, activity, synchronization, and audit timestamps.

Use:

```sql
date
```

for date-only concepts such as target graduation date or application cycle date.

Standard timestamp columns:

```sql
created_at timestamptz not null default now()
updated_at timestamptz not null default now()
archived_at timestamptz null
```

## 2.5 Time zones

Store timestamps in `timestamptz`.

Store the original IANA timezone separately when it materially affects interpretation.

Example:

```sql
deadline_at timestamptz
deadline_timezone text
```

## 2.6 Soft deletion

First-class domain records should normally use:

```sql
archived_at timestamptz
```

Hard deletion should be reserved for:

* Explicit user deletion.
* Privacy requests.
* Temporary ingestion records.
* Revoked credentials.
* Failed transient processing records, where retention is unnecessary.

## 2.7 Metadata

Use `jsonb` only for:

* Provider-specific payloads.
* Optional extensible metadata.
* AI factor details.
* Background-job payloads.
* Non-canonical integration fields.

Do not store core searchable or relational domain facts only in JSON.

## 2.8 Text search

Fields likely to participate in search should remain typed text columns.

Examples:

* Object title.
* Person name.
* Organization name.
* Opportunity title.
* Knowledge title.
* Document title.

## 2.9 Monetary values

Where structured compensation becomes necessary, use:

```sql
numeric
```

plus currency and interval columns.

For MVP flexibility, human-readable summaries may also be retained.

---

# 3. PostgreSQL Extensions

Recommended extensions:

```sql
create extension if not exists pgcrypto;
create extension if not exists citext;
create extension if not exists pg_trgm;
```

Potential later extension:

```sql
create extension if not exists vector;
```

The vector extension should be introduced only when semantic search is implemented.

---

# 4. Enum Strategy

## 4.1 Recommended approach

Use PostgreSQL enums only for highly stable, small-value sets.

Use lookup tables or constrained text columns for values expected to evolve frequently.

## 4.2 PostgreSQL enum candidates

Suggested stable enum types:

```sql
object_layer
object_visibility
record_origin
verification_status
integration_provider
integration_status
approval_status
notification_priority
job_status
actor_type
```

## 4.3 Controlled text values

Use text columns with check constraints or application validation for frequently evolving domain states such as:

* Opportunity type.
* Project type.
* Goal type.
* Knowledge type.
* Recommendation type.
* Relationship type.
* Activity type.

This avoids repeated enum migrations as the ontology evolves.

---

# 5. Shared Enum Definitions

## 5.1 Object layer

```sql
create type object_layer as enum (
  'personal',
  'world',
  'intelligence'
);
```

## 5.2 Object visibility

```sql
create type object_visibility as enum (
  'private',
  'system',
  'future_shared'
);
```

## 5.3 Record origin

```sql
create type record_origin as enum (
  'user_created',
  'imported',
  'system_generated',
  'ai_inferred',
  'integration_detected',
  'migration'
);
```

## 5.4 Verification status

```sql
create type verification_status as enum (
  'unverified',
  'user_confirmed',
  'source_verified',
  'disputed',
  'stale',
  'rejected'
);
```

## 5.5 Actor type

```sql
create type actor_type as enum (
  'user',
  'system',
  'integration',
  'ai',
  'migration'
);
```

## 5.6 Integration provider

```sql
create type integration_provider as enum (
  'google',
  'github'
);
```

This enum may be converted to a lookup table if provider growth becomes frequent.

## 5.7 Integration status

```sql
create type integration_status as enum (
  'pending',
  'active',
  'disabled',
  'revoked',
  'error'
);
```

## 5.8 Approval status

```sql
create type approval_status as enum (
  'pending',
  'approved',
  'rejected',
  'expired',
  'cancelled'
);
```

## 5.9 Job status

```sql
create type job_status as enum (
  'queued',
  'running',
  'succeeded',
  'failed',
  'cancelled',
  'retrying'
);
```

## 5.10 Notification priority

```sql
create type notification_priority as enum (
  'low',
  'normal',
  'high',
  'critical'
);
```

---

# 6. Identity and User Tables

## 6.1 `users`

### Purpose

Application-facing identity and tenancy record.

```sql
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email citext not null unique,
  display_name text,
  avatar_url text,
  timezone text not null default 'America/Los_Angeles',
  locale text not null default 'en-US',
  onboarding_status text not null default 'not_started',
  account_status text not null default 'active',
  last_active_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint users_timezone_not_blank
    check (length(trim(timezone)) > 0),

  constraint users_locale_not_blank
    check (length(trim(locale)) > 0)
);
```

### Deletion behavior

Deleting the authenticated account cascades to the application user record.

A dedicated account-deletion workflow must handle dependent records before or alongside this cascade.

---

## 6.2 `user_profiles`

```sql
create table public.user_profiles (
  user_id uuid primary key references public.users(id) on delete cascade,
  professional_summary text,
  education_summary text,
  career_interests text[] not null default '{}',
  research_interests text[] not null default '{}',
  preferred_locations text[] not null default '{}',
  work_authorization_summary text,
  short_term_objectives text,
  long_term_objectives text,
  profile_completeness numeric(5,2) not null default 0,
  inferred_fields jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),

  constraint user_profiles_completeness_range
    check (profile_completeness between 0 and 100)
);
```

---

## 6.3 `user_preferences`

```sql
create table public.user_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  preference_key text not null,
  preference_value jsonb not null,
  source record_origin not null default 'user_created',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint user_preferences_key_not_blank
    check (length(trim(preference_key)) > 0),

  constraint user_preferences_unique_key
    unique (user_id, preference_key)
);
```

---

# 7. Universal Object Platform

## 7.1 `objects`

### Purpose

Universal identity registry for all first-class objects.

```sql
create table public.objects (
  id uuid primary key default gen_random_uuid(),
  object_type text not null,
  owner_user_id uuid not null references public.users(id) on delete cascade,
  display_title text not null,
  slug text,
  layer object_layer not null,
  visibility object_visibility not null default 'private',
  status text not null,
  source_type record_origin not null default 'user_created',
  source_reference text,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,

  constraint objects_type_not_blank
    check (length(trim(object_type)) > 0),

  constraint objects_title_not_blank
    check (length(trim(display_title)) > 0),

  constraint objects_slug_format
    check (
      slug is null
      or slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
    ),

  constraint objects_owner_type_slug_unique
    unique nulls not distinct (owner_user_id, object_type, slug)
);
```

### Notes

* Version 1 uses user-scoped World objects.
* `status` is duplicated here for fast universal queries.
* Domain-table status remains canonical unless a later ADR changes this.
* Database triggers or application services must keep registry and domain status synchronized.

---

## 7.2 `relationships`

```sql
create table public.relationships (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  relationship_type text not null,
  source_object_id uuid not null references public.objects(id) on delete cascade,
  target_object_id uuid not null references public.objects(id) on delete cascade,
  origin_type record_origin not null default 'user_created',
  verification_status verification_status not null default 'unverified',
  confidence numeric(5,4),
  valid_from timestamptz,
  valid_until timestamptz,
  ended_at timestamptz,
  is_current boolean not null default true,
  evidence_summary text,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint relationships_type_not_blank
    check (length(trim(relationship_type)) > 0),

  constraint relationships_no_self_link
    check (source_object_id <> target_object_id),

  constraint relationships_confidence_range
    check (confidence is null or confidence between 0 and 1),

  constraint relationships_valid_dates
    check (
      valid_until is null
      or valid_from is null
      or valid_until >= valid_from
    )
);
```

### Duplicate control

Use partial unique indexes for relationship types requiring one active edge.

Generic uniqueness should not be imposed globally because some relationship types may legitimately repeat over time.

---

## 7.3 `activities`

```sql
create table public.activities (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  activity_type text not null,
  actor_type actor_type not null,
  actor_id text,
  primary_object_id uuid references public.objects(id) on delete set null,
  occurred_at timestamptz not null default now(),
  origin_type record_origin not null,
  correlation_id uuid,
  summary text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),

  constraint activities_type_not_blank
    check (length(trim(activity_type)) > 0),

  constraint activities_summary_not_blank
    check (length(trim(summary)) > 0)
);
```

### Mutability

Activities are append-oriented.

Corrections should normally create compensating activities.

---

## 7.4 `activity_objects`

```sql
create table public.activity_objects (
  activity_id uuid not null references public.activities(id) on delete cascade,
  object_id uuid not null references public.objects(id) on delete cascade,
  role text not null default 'related',

  primary key (activity_id, object_id, role)
);
```

---

## 7.5 `lifecycle_transitions`

```sql
create table public.lifecycle_transitions (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  object_id uuid not null references public.objects(id) on delete cascade,
  previous_status text,
  new_status text not null,
  transition_origin record_origin not null,
  transition_reason text,
  override_used boolean not null default false,
  override_reason text,
  initiated_by uuid references public.users(id) on delete set null,
  transitioned_at timestamptz not null default now(),
  evidence_object_id uuid references public.objects(id) on delete set null,
  activity_id uuid references public.activities(id) on delete set null,

  constraint lifecycle_new_status_not_blank
    check (length(trim(new_status)) > 0),

  constraint lifecycle_override_reason_required
    check (
      override_used = false
      or length(trim(coalesce(override_reason, ''))) > 0
    )
);
```

---

## 7.6 `tags`

```sql
create table public.tags (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  normalized_name text not null,
  description text,
  color_reference text,
  created_at timestamptz not null default now(),

  constraint tags_name_not_blank
    check (length(trim(name)) > 0),

  constraint tags_normalized_not_blank
    check (length(trim(normalized_name)) > 0),

  constraint tags_unique_normalized_name
    unique (owner_user_id, normalized_name)
);
```

---

## 7.7 `object_tags`

```sql
create table public.object_tags (
  object_id uuid not null references public.objects(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  assigned_by uuid references public.users(id) on delete set null,
  assigned_at timestamptz not null default now(),

  primary key (object_id, tag_id)
);
```

---

# 8. Goals, Decisions, and Assets

## 8.1 `goals`

```sql
create table public.goals (
  object_id uuid primary key references public.objects(id) on delete cascade,
  goal_type text not null,
  description text,
  priority smallint not null default 3,
  status text not null,
  start_date date,
  target_date date,
  success_criteria text,
  motivation text,
  progress_method text not null default 'manual',
  progress_value numeric(7,2) not null default 0,
  confidence_level numeric(5,4),

  constraint goals_priority_range
    check (priority between 1 and 5),

  constraint goals_progress_range
    check (progress_value between 0 and 100),

  constraint goals_confidence_range
    check (confidence_level is null or confidence_level between 0 and 1),

  constraint goals_dates_valid
    check (
      target_date is null
      or start_date is null
      or target_date >= start_date
    )
);
```

---

## 8.2 `goal_milestones`

```sql
create table public.goal_milestones (
  id uuid primary key default gen_random_uuid(),
  goal_object_id uuid not null references public.goals(object_id) on delete cascade,
  title text not null,
  description text,
  status text not null,
  target_date date,
  completed_at timestamptz,
  weight numeric(7,4) not null default 1,
  sequence_order integer,

  constraint goal_milestones_title_not_blank
    check (length(trim(title)) > 0),

  constraint goal_milestones_weight_positive
    check (weight > 0)
);
```

---

## 8.3 `decisions`

```sql
create table public.decisions (
  object_id uuid primary key references public.objects(id) on delete cascade,
  decision_question text not null,
  description text,
  decision_type text,
  status text not null,
  importance smallint not null default 3,
  reversibility text not null default 'partially_reversible',
  decision_deadline timestamptz,
  final_choice_summary text,
  decision_date timestamptz,
  outcome_summary text,
  reflection text,

  constraint decisions_question_not_blank
    check (length(trim(decision_question)) > 0),

  constraint decisions_importance_range
    check (importance between 1 and 5)
);
```

---

## 8.4 `decision_options`

```sql
create table public.decision_options (
  id uuid primary key default gen_random_uuid(),
  decision_object_id uuid not null references public.decisions(object_id) on delete cascade,
  title text not null,
  description text,
  status text not null default 'active',
  estimated_value numeric,
  confidence numeric(5,4),
  selected boolean not null default false,
  sequence_order integer,

  constraint decision_options_title_not_blank
    check (length(trim(title)) > 0),

  constraint decision_options_confidence_range
    check (confidence is null or confidence between 0 and 1)
);
```

---

## 8.5 `decision_criteria`

```sql
create table public.decision_criteria (
  id uuid primary key default gen_random_uuid(),
  decision_object_id uuid not null references public.decisions(object_id) on delete cascade,
  name text not null,
  description text,
  weight numeric(7,4) not null default 1,
  measurement_method text,

  constraint decision_criteria_name_not_blank
    check (length(trim(name)) > 0),

  constraint decision_criteria_weight_positive
    check (weight > 0),

  constraint decision_criteria_unique_name
    unique (decision_object_id, name)
);
```

---

## 8.6 `decision_evaluations`

```sql
create table public.decision_evaluations (
  id uuid primary key default gen_random_uuid(),
  decision_option_id uuid not null references public.decision_options(id) on delete cascade,
  decision_criterion_id uuid not null references public.decision_criteria(id) on delete cascade,
  score numeric,
  rationale text,
  confidence numeric(5,4),
  source_type record_origin not null default 'user_created',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint decision_evaluations_confidence_range
    check (confidence is null or confidence between 0 and 1),

  constraint decision_evaluations_unique_pair
    unique (decision_option_id, decision_criterion_id)
);
```

---

## 8.7 `assets`

```sql
create table public.assets (
  object_id uuid primary key references public.objects(id) on delete cascade,
  asset_type text not null,
  description text,
  status text not null,
  current_level numeric,
  measurement_method text,
  last_evaluated_at timestamptz
);
```

---

## 8.8 `asset_measurements`

```sql
create table public.asset_measurements (
  id uuid primary key default gen_random_uuid(),
  asset_object_id uuid not null references public.assets(object_id) on delete cascade,
  measured_at timestamptz not null default now(),
  value numeric not null,
  measurement_type text not null,
  confidence numeric(5,4),
  evidence_summary text,
  source_type record_origin not null,

  constraint asset_measurements_confidence_range
    check (confidence is null or confidence between 0 and 1)
);
```

---

# 9. Projects and Execution

## 9.1 `projects`

```sql
create table public.projects (
  object_id uuid primary key references public.objects(id) on delete cascade,
  project_type text not null,
  description text,
  mission text not null,
  status text not null,
  priority smallint not null default 3,
  start_date date,
  target_end_date date,
  actual_end_date date,
  expected_outcomes text,
  success_criteria text,
  health_status text,

  constraint projects_priority_range
    check (priority between 1 and 5),

  constraint projects_mission_not_blank
    check (length(trim(mission)) > 0),

  constraint projects_dates_valid
    check (
      target_end_date is null
      or start_date is null
      or target_end_date >= start_date
    )
);
```

---

## 9.2 `project_milestones`

```sql
create table public.project_milestones (
  id uuid primary key default gen_random_uuid(),
  project_object_id uuid not null references public.projects(object_id) on delete cascade,
  title text not null,
  description text,
  status text not null,
  target_date date,
  completed_at timestamptz,
  sequence_order integer,
  weight numeric(7,4) not null default 1,

  constraint project_milestones_title_not_blank
    check (length(trim(title)) > 0),

  constraint project_milestones_weight_positive
    check (weight > 0)
);
```

---

## 9.3 `deliverables`

```sql
create table public.deliverables (
  object_id uuid primary key references public.objects(id) on delete cascade,
  project_object_id uuid not null references public.projects(object_id) on delete cascade,
  deliverable_type text not null,
  description text,
  status text not null,
  target_date date,
  completed_at timestamptz,
  external_url text
);
```

---

## 9.4 `tasks`

```sql
create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  description text,
  status text not null,
  priority smallint not null default 3,
  due_at timestamptz,
  estimated_duration_minutes integer,
  actual_duration_minutes integer,
  completed_at timestamptz,
  source_type record_origin not null default 'user_created',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,

  constraint tasks_title_not_blank
    check (length(trim(title)) > 0),

  constraint tasks_priority_range
    check (priority between 1 and 5),

  constraint tasks_estimated_duration_nonnegative
    check (
      estimated_duration_minutes is null
      or estimated_duration_minutes >= 0
    ),

  constraint tasks_actual_duration_nonnegative
    check (
      actual_duration_minutes is null
      or actual_duration_minutes >= 0
    ),

  constraint tasks_completed_timestamp
    check (
      status <> 'completed'
      or completed_at is not null
    )
);
```

---

## 9.5 `task_objects`

```sql
create table public.task_objects (
  task_id uuid not null references public.tasks(id) on delete cascade,
  object_id uuid not null references public.objects(id) on delete cascade,
  relationship_role text not null,

  primary key (task_id, object_id, relationship_role)
);
```

---

## 9.6 `task_dependencies`

```sql
create table public.task_dependencies (
  task_id uuid not null references public.tasks(id) on delete cascade,
  depends_on_task_id uuid not null references public.tasks(id) on delete cascade,
  dependency_type text not null default 'blocks',
  created_at timestamptz not null default now(),

  primary key (task_id, depends_on_task_id, dependency_type),

  constraint task_dependencies_no_self_dependency
    check (task_id <> depends_on_task_id)
);
```

Cycle prevention should be handled through an application service or database function.

---

## 9.7 `time_blocks`

```sql
create table public.time_blocks (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  start_at timestamptz not null,
  end_at timestamptz not null,
  timezone text not null,
  status text not null,
  task_id uuid references public.tasks(id) on delete set null,
  external_calendar_event_id uuid,
  source_type record_origin not null default 'user_created',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint time_blocks_title_not_blank
    check (length(trim(title)) > 0),

  constraint time_blocks_time_order
    check (end_at > start_at)
);
```

---

## 9.8 `reminders`

```sql
create table public.reminders (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  remind_at timestamptz not null,
  status text not null default 'scheduled',
  channel text not null default 'in_app',
  related_object_id uuid references public.objects(id) on delete cascade,
  related_task_id uuid references public.tasks(id) on delete cascade,
  created_at timestamptz not null default now(),

  constraint reminders_target_required
    check (
      related_object_id is not null
      or related_task_id is not null
    )
);
```

---

# 10. Organizations, People, and Relationships

## 10.1 `organizations`

```sql
create table public.organizations (
  object_id uuid primary key references public.objects(id) on delete cascade,
  name text not null,
  normalized_name text not null,
  organization_type text not null,
  description text,
  website text,
  primary_domain citext,
  headquarters_text text,
  size_category text,
  parent_organization_object_id uuid references public.organizations(object_id) on delete set null,
  source_type record_origin not null default 'user_created',
  last_verified_at timestamptz,

  constraint organizations_name_not_blank
    check (length(trim(name)) > 0),

  constraint organizations_normalized_not_blank
    check (length(trim(normalized_name)) > 0)
);
```

---

## 10.2 `people`

```sql
create table public.people (
  object_id uuid primary key references public.objects(id) on delete cascade,
  full_name text not null,
  preferred_name text,
  headline text,
  biography text,
  location_text text,
  primary_email citext,
  phone_number text,
  linkedin_url text,
  personal_website text,
  source_type record_origin not null default 'user_created',
  last_verified_at timestamptz,

  constraint people_full_name_not_blank
    check (length(trim(full_name)) > 0)
);
```

Contact information should receive Restricted privacy treatment where appropriate.

---

## 10.3 `person_organization_affiliations`

```sql
create table public.person_organization_affiliations (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  person_object_id uuid not null references public.people(object_id) on delete cascade,
  organization_object_id uuid not null references public.organizations(object_id) on delete cascade,
  affiliation_type text not null,
  title text,
  department text,
  start_date date,
  end_date date,
  is_current boolean not null default true,
  source_type record_origin not null default 'user_created',
  verification_status verification_status not null default 'unverified',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint affiliations_date_order
    check (
      end_date is null
      or start_date is null
      or end_date >= start_date
    )
);
```

---

## 10.4 `professional_relationships`

```sql
create table public.professional_relationships (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  person_object_id uuid not null references public.people(object_id) on delete cascade,
  relationship_type text,
  status text not null,
  started_at timestamptz,
  last_interaction_at timestamptz,
  next_follow_up_at timestamptz,
  shared_interests text[] not null default '{}',
  user_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint professional_relationships_unique_person
    unique (owner_user_id, person_object_id)
);
```

Relationship Health is not stored here as a user-entered fact. It is represented through Scores or Intelligence outputs.

---

## 10.5 `interactions`

```sql
create table public.interactions (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  interaction_type text not null,
  occurred_at timestamptz not null,
  channel text,
  summary text not null,
  follow_up_required boolean not null default false,
  follow_up_due_at timestamptz,
  source_type record_origin not null default 'user_created',
  created_at timestamptz not null default now(),

  constraint interactions_summary_not_blank
    check (length(trim(summary)) > 0)
);
```

---

## 10.6 `interaction_participants`

```sql
create table public.interaction_participants (
  interaction_id uuid not null references public.interactions(id) on delete cascade,
  object_id uuid not null references public.objects(id) on delete cascade,
  participant_role text not null,

  primary key (interaction_id, object_id, participant_role)
);
```

---

# 11. Opportunities and Applications

## 11.1 `opportunities`

```sql
create table public.opportunities (
  object_id uuid primary key references public.objects(id) on delete cascade,
  opportunity_type text not null,
  organization_object_id uuid references public.organizations(object_id) on delete set null,
  description text,
  status text not null,
  location_text text,
  work_arrangement text,
  eligibility_summary text,
  application_deadline timestamptz,
  deadline_timezone text,
  start_date date,
  end_date date,
  compensation_summary text,
  funding_summary text,
  visa_summary text,
  source_url text,
  external_identifier text,
  published_at timestamptz,
  last_verified_at timestamptz,

  constraint opportunities_date_order
    check (
      end_date is null
      or start_date is null
      or end_date >= start_date
    )
);
```

---

## 11.2 `opportunity_requirements`

```sql
create table public.opportunity_requirements (
  id uuid primary key default gen_random_uuid(),
  opportunity_object_id uuid not null references public.opportunities(object_id) on delete cascade,
  requirement_type text not null,
  description text not null,
  importance smallint not null default 3,
  required boolean not null default true,
  source_excerpt text,

  constraint opportunity_requirements_description_not_blank
    check (length(trim(description)) > 0),

  constraint opportunity_requirements_importance_range
    check (importance between 1 and 5)
);
```

---

## 11.3 `applications`

```sql
create table public.applications (
  object_id uuid primary key references public.objects(id) on delete cascade,
  opportunity_object_id uuid not null references public.opportunities(object_id) on delete restrict,
  stage text not null,
  status text not null,
  priority smallint not null default 3,
  application_cycle text,
  application_deadline timestamptz,
  submitted_at timestamptz,
  decision_date timestamptz,
  outcome text,
  source text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint applications_priority_range
    check (priority between 1 and 5),

  constraint applications_submitted_timestamp
    check (
      stage <> 'submitted'
      or submitted_at is not null
    )
);
```

A partial unique index should enforce one active Application per owner, Opportunity, and application cycle.

---

## 11.4 `application_stage_history`

```sql
create table public.application_stage_history (
  id uuid primary key default gen_random_uuid(),
  application_object_id uuid not null references public.applications(object_id) on delete cascade,
  previous_stage text,
  new_stage text not null,
  changed_at timestamptz not null default now(),
  changed_by uuid references public.users(id) on delete set null,
  origin_type record_origin not null,
  reason text,
  evidence_object_id uuid references public.objects(id) on delete set null,
  override_used boolean not null default false,

  constraint application_stage_new_not_blank
    check (length(trim(new_stage)) > 0)
);
```

---

## 11.5 `assessments`

```sql
create table public.assessments (
  object_id uuid primary key references public.objects(id) on delete cascade,
  application_object_id uuid not null references public.applications(object_id) on delete cascade,
  assessment_type text not null,
  status text not null,
  invited_at timestamptz,
  due_at timestamptz,
  completed_at timestamptz,
  result_summary text,
  provider text,
  external_url text
);
```

---

## 11.6 `interviews`

```sql
create table public.interviews (
  object_id uuid primary key references public.objects(id) on delete cascade,
  application_object_id uuid not null references public.applications(object_id) on delete cascade,
  interview_type text,
  round_name text,
  status text not null,
  scheduled_start timestamptz,
  scheduled_end timestamptz,
  timezone text,
  location_or_link text,
  outcome_summary text,

  constraint interviews_schedule_order
    check (
      scheduled_end is null
      or scheduled_start is null
      or scheduled_end > scheduled_start
    )
);
```

---

# 12. Skills and Development

## 12.1 `skills`

```sql
create table public.skills (
  object_id uuid primary key references public.objects(id) on delete cascade,
  name text not null,
  normalized_name text not null,
  skill_category text,
  description text,
  parent_skill_object_id uuid references public.skills(object_id) on delete set null,
  source_type record_origin not null default 'user_created',

  constraint skills_name_not_blank
    check (length(trim(name)) > 0),

  constraint skills_normalized_not_blank
    check (length(trim(normalized_name)) > 0)
);
```

---

## 12.2 `user_skills`

```sql
create table public.user_skills (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  skill_object_id uuid not null references public.skills(object_id) on delete cascade,
  claimed_level numeric,
  inferred_level numeric,
  target_level numeric,
  confidence numeric(5,4),
  last_practiced_at timestamptz,
  last_evaluated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint user_skills_confidence_range
    check (confidence is null or confidence between 0 and 1),

  constraint user_skills_unique_skill
    unique (owner_user_id, skill_object_id)
);
```

---

## 12.3 `skill_evidence`

```sql
create table public.skill_evidence (
  user_skill_id uuid not null references public.user_skills(id) on delete cascade,
  evidence_object_id uuid not null references public.objects(id) on delete cascade,
  evidence_role text not null,
  confidence numeric(5,4),

  primary key (user_skill_id, evidence_object_id, evidence_role),

  constraint skill_evidence_confidence_range
    check (confidence is null or confidence between 0 and 1)
);
```

The referenced Object should be an Evidence object. Enforcement may occur in application validation or a database trigger.

---

# 13. Knowledge and Evidence

## 13.1 `knowledge_items`

```sql
create table public.knowledge_items (
  object_id uuid primary key references public.objects(id) on delete cascade,
  knowledge_type text not null,
  content text not null,
  status text not null,
  confidence numeric(5,4),
  source_summary text,
  current_version_number integer not null default 1,

  constraint knowledge_items_content_not_blank
    check (length(trim(content)) > 0),

  constraint knowledge_items_confidence_range
    check (confidence is null or confidence between 0 and 1),

  constraint knowledge_items_version_positive
    check (current_version_number > 0)
);
```

---

## 13.2 `knowledge_versions`

```sql
create table public.knowledge_versions (
  id uuid primary key default gen_random_uuid(),
  knowledge_object_id uuid not null references public.knowledge_items(object_id) on delete cascade,
  version_number integer not null,
  content text not null,
  change_summary text,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),

  constraint knowledge_versions_number_positive
    check (version_number > 0),

  constraint knowledge_versions_content_not_blank
    check (length(trim(content)) > 0),

  constraint knowledge_versions_unique_number
    unique (knowledge_object_id, version_number)
);
```

---

## 13.3 `evidence`

```sql
create table public.evidence (
  object_id uuid primary key references public.objects(id) on delete cascade,
  evidence_type text not null,
  title text not null,
  source_uri text,
  source_name text,
  captured_at timestamptz not null default now(),
  published_at timestamptz,
  content_excerpt text,
  authority_level smallint,
  verification_status verification_status not null default 'unverified',
  last_verified_at timestamptz,

  constraint evidence_title_not_blank
    check (length(trim(title)) > 0),

  constraint evidence_authority_range
    check (
      authority_level is null
      or authority_level between 1 and 5
    )
);
```

---

## 13.4 `evidence_claims`

```sql
create table public.evidence_claims (
  id uuid primary key default gen_random_uuid(),
  evidence_object_id uuid not null references public.evidence(object_id) on delete cascade,
  claim_text text not null,
  claim_type text,
  confidence numeric(5,4),
  valid_from timestamptz,
  valid_until timestamptz,
  extracted_by record_origin not null,
  created_at timestamptz not null default now(),

  constraint evidence_claims_text_not_blank
    check (length(trim(claim_text)) > 0),

  constraint evidence_claims_confidence_range
    check (confidence is null or confidence between 0 and 1),

  constraint evidence_claims_valid_dates
    check (
      valid_until is null
      or valid_from is null
      or valid_until >= valid_from
    )
);
```

---

## 13.5 `citations`

```sql
create table public.citations (
  id uuid primary key default gen_random_uuid(),
  source_object_id uuid not null references public.objects(id) on delete cascade,
  evidence_object_id uuid not null references public.evidence(object_id) on delete cascade,
  citation_role text not null,
  excerpt text,
  created_at timestamptz not null default now(),

  constraint citations_unique_role
    unique (source_object_id, evidence_object_id, citation_role)
);
```

---

# 14. Documents and Files

## 14.1 `documents`

```sql
create table public.documents (
  object_id uuid primary key references public.objects(id) on delete cascade,
  document_type text not null,
  status text not null,
  current_version_id uuid,
  description text,
  sensitivity text not null default 'confidential'
);
```

The `current_version_id` foreign key should be added after `document_versions` is created.

---

## 14.2 `file_objects`

```sql
create table public.file_objects (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  file_name text not null,
  mime_type text not null,
  size_bytes bigint not null,
  storage_provider text not null default 'supabase',
  storage_path text not null,
  checksum text,
  sensitivity text not null default 'confidential',
  uploaded_at timestamptz not null default now(),

  constraint file_objects_name_not_blank
    check (length(trim(file_name)) > 0),

  constraint file_objects_size_nonnegative
    check (size_bytes >= 0),

  constraint file_objects_storage_path_not_blank
    check (length(trim(storage_path)) > 0)
);
```

---

## 14.3 `document_versions`

```sql
create table public.document_versions (
  id uuid primary key default gen_random_uuid(),
  document_object_id uuid not null references public.documents(object_id) on delete cascade,
  version_number integer not null,
  file_object_id uuid not null references public.file_objects(id) on delete restrict,
  status text not null,
  change_summary text,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),

  constraint document_versions_number_positive
    check (version_number > 0),

  constraint document_versions_unique_number
    unique (document_object_id, version_number)
);
```

Add the circular reference after both tables exist:

```sql
alter table public.documents
  add constraint documents_current_version_fk
  foreign key (current_version_id)
  references public.document_versions(id)
  on delete set null;
```

---

## 14.4 `application_documents`

```sql
create table public.application_documents (
  application_object_id uuid not null references public.applications(object_id) on delete cascade,
  document_version_id uuid not null references public.document_versions(id) on delete restrict,
  usage_type text not null,
  submitted_at timestamptz,

  primary key (
    application_object_id,
    document_version_id,
    usage_type
  )
);
```

---

## 14.5 `attachments`

```sql
create table public.attachments (
  id uuid primary key default gen_random_uuid(),
  file_id uuid not null references public.file_objects(id) on delete cascade,
  parent_object_id uuid references public.objects(id) on delete cascade,
  parent_record_type text,
  parent_record_id uuid,
  attachment_role text not null default 'attachment',
  created_at timestamptz not null default now(),

  constraint attachments_parent_required
    check (
      parent_object_id is not null
      or (
        parent_record_type is not null
        and parent_record_id is not null
      )
    )
);
```

Polymorphic supporting-record integrity must be enforced in application logic or replaced later with dedicated link tables.

---

# 15. Communication and Calendar

## 15.1 `integration_accounts`

Defined before communication records because those records depend on it.

```sql
create table public.integration_accounts (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  provider integration_provider not null,
  external_account_id text not null,
  display_name text,
  status integration_status not null default 'pending',
  granted_scopes text[] not null default '{}',
  connected_at timestamptz,
  last_successful_sync_at timestamptz,
  last_error_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint integration_accounts_external_id_not_blank
    check (length(trim(external_account_id)) > 0),

  constraint integration_accounts_unique_provider_account
    unique (owner_user_id, provider, external_account_id)
);
```

---

## 15.2 `integration_credentials`

```sql
create table public.integration_credentials (
  integration_account_id uuid primary key
    references public.integration_accounts(id) on delete cascade,
  encrypted_access_token text,
  encrypted_refresh_token text,
  token_expires_at timestamptz,
  encryption_version integer not null,
  updated_at timestamptz not null default now(),

  constraint integration_credentials_version_positive
    check (encryption_version > 0)
);
```

Direct client access must be prohibited.

---

## 15.3 `email_records`

```sql
create table public.email_records (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  integration_account_id uuid not null
    references public.integration_accounts(id) on delete cascade,
  external_message_id text not null,
  external_thread_id text,
  subject text,
  sender_summary text,
  recipient_summary text,
  sent_at timestamptz,
  snippet text,
  encrypted_body text,
  classification text,
  requires_action boolean not null default false,
  sensitivity text not null default 'restricted',
  import_status text not null default 'metadata_only',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint email_records_external_id_not_blank
    check (length(trim(external_message_id)) > 0),

  constraint email_records_unique_message
    unique (integration_account_id, external_message_id)
);
```

The encryption design for `encrypted_body` must be defined in the Security specification.

---

## 15.4 `email_object_links`

```sql
create table public.email_object_links (
  email_record_id uuid not null references public.email_records(id) on delete cascade,
  object_id uuid not null references public.objects(id) on delete cascade,
  link_type text not null,
  confidence numeric(5,4),
  confirmed_by_user boolean not null default false,

  primary key (email_record_id, object_id, link_type),

  constraint email_object_links_confidence_range
    check (confidence is null or confidence between 0 and 1)
);
```

---

## 15.5 `calendar_events`

```sql
create table public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  integration_account_id uuid
    references public.integration_accounts(id) on delete cascade,
  external_event_id text,
  title text not null,
  description text,
  start_at timestamptz not null,
  end_at timestamptz not null,
  timezone text not null,
  location text,
  event_type text,
  status text not null,
  import_status text not null default 'metadata_only',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint calendar_events_title_not_blank
    check (length(trim(title)) > 0),

  constraint calendar_events_time_order
    check (end_at > start_at),

  constraint calendar_events_external_unique
    unique nulls not distinct (
      integration_account_id,
      external_event_id
    )
);
```

---

## 15.6 `calendar_event_object_links`

```sql
create table public.calendar_event_object_links (
  calendar_event_id uuid not null references public.calendar_events(id) on delete cascade,
  object_id uuid not null references public.objects(id) on delete cascade,
  link_type text not null,
  confidence numeric(5,4),
  confirmed_by_user boolean not null default false,

  primary key (calendar_event_id, object_id, link_type),

  constraint calendar_event_links_confidence_range
    check (confidence is null or confidence between 0 and 1)
);
```

---

## 15.7 `time_blocks` external-calendar relationship

After `calendar_events` exists:

```sql
alter table public.time_blocks
  add constraint time_blocks_external_calendar_event_fk
  foreign key (external_calendar_event_id)
  references public.calendar_events(id)
  on delete set null;
```

---

# 16. Intelligence Tables

## 16.1 `insights`

```sql
create table public.insights (
  object_id uuid primary key references public.objects(id) on delete cascade,
  insight_type text not null,
  summary text not null,
  status text not null,
  confidence numeric(5,4),
  generated_at timestamptz not null default now(),
  expires_at timestamptz,
  model_identifier text not null,
  instruction_version text,

  constraint insights_summary_not_blank
    check (length(trim(summary)) > 0),

  constraint insights_confidence_range
    check (confidence is null or confidence between 0 and 1)
);
```

---

## 16.2 `recommendations`

```sql
create table public.recommendations (
  object_id uuid primary key references public.objects(id) on delete cascade,
  recommendation_type text not null,
  recommended_action text not null,
  reasoning_summary text not null,
  priority smallint not null default 3,
  confidence numeric(5,4),
  expected_impact jsonb not null default '{}'::jsonb,
  status text not null,
  valid_until timestamptz,
  generated_at timestamptz not null default now(),
  model_identifier text not null,
  instruction_version text,

  constraint recommendations_priority_range
    check (priority between 1 and 5),

  constraint recommendations_confidence_range
    check (confidence is null or confidence between 0 and 1),

  constraint recommendations_action_not_blank
    check (length(trim(recommended_action)) > 0),

  constraint recommendations_reasoning_not_blank
    check (length(trim(reasoning_summary)) > 0)
);
```

---

## 16.3 `scores`

```sql
create table public.scores (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  score_type text not null,
  subject_object_id uuid not null references public.objects(id) on delete cascade,
  value numeric not null,
  scale_min numeric not null,
  scale_max numeric not null,
  confidence numeric(5,4),
  factor_summary text,
  calculated_at timestamptz not null default now(),
  expires_at timestamptz,
  model_version text,

  constraint scores_scale_order
    check (scale_max > scale_min),

  constraint scores_value_in_range
    check (value between scale_min and scale_max),

  constraint scores_confidence_range
    check (confidence is null or confidence between 0 and 1)
);
```

---

## 16.4 `score_factors`

```sql
create table public.score_factors (
  id uuid primary key default gen_random_uuid(),
  score_id uuid not null references public.scores(id) on delete cascade,
  factor_name text not null,
  factor_value numeric,
  weight numeric,
  rationale text,
  source_object_id uuid references public.objects(id) on delete set null,

  constraint score_factors_name_not_blank
    check (length(trim(factor_name)) > 0)
);
```

---

## 16.5 `career_risks`

```sql
create table public.career_risks (
  object_id uuid primary key references public.objects(id) on delete cascade,
  risk_type text not null,
  description text not null,
  severity smallint not null,
  likelihood numeric(5,4),
  time_horizon text,
  mitigation_summary text,
  status text not null,
  detected_at timestamptz not null default now(),
  expires_at timestamptz,

  constraint career_risks_description_not_blank
    check (length(trim(description)) > 0),

  constraint career_risks_severity_range
    check (severity between 1 and 5),

  constraint career_risks_likelihood_range
    check (likelihood is null or likelihood between 0 and 1)
);
```

---

## 16.6 `daily_missions`

```sql
create table public.daily_missions (
  object_id uuid primary key references public.objects(id) on delete cascade,
  mission_date date not null,
  summary text,
  status text not null,
  estimated_workload_minutes integer,
  deadline_risk smallint,
  generated_at timestamptz not null default now(),
  confirmed_at timestamptz,

  constraint daily_missions_workload_nonnegative
    check (
      estimated_workload_minutes is null
      or estimated_workload_minutes >= 0
    ),

  constraint daily_missions_deadline_risk_range
    check (
      deadline_risk is null
      or deadline_risk between 1 and 5
    )
);
```

A unique partial index should allow one active Daily Mission per user and date.

---

## 16.7 `daily_mission_items`

```sql
create table public.daily_mission_items (
  id uuid primary key default gen_random_uuid(),
  daily_mission_object_id uuid not null
    references public.daily_missions(object_id) on delete cascade,
  related_object_id uuid references public.objects(id) on delete cascade,
  related_task_id uuid references public.tasks(id) on delete cascade,
  sequence_order integer not null,
  priority smallint not null default 3,
  reasoning_summary text,
  estimated_duration_minutes integer,

  constraint daily_mission_items_target_required
    check (
      related_object_id is not null
      or related_task_id is not null
    ),

  constraint daily_mission_items_priority_range
    check (priority between 1 and 5),

  constraint daily_mission_items_duration_nonnegative
    check (
      estimated_duration_minutes is null
      or estimated_duration_minutes >= 0
    ),

  constraint daily_mission_items_unique_sequence
    unique (daily_mission_object_id, sequence_order)
);
```

---

## 16.8 `weekly_strategies`

```sql
create table public.weekly_strategies (
  object_id uuid primary key references public.objects(id) on delete cascade,
  week_start date not null,
  week_end date not null,
  summary text,
  status text not null,
  generated_at timestamptz not null default now(),
  confirmed_at timestamptz,

  constraint weekly_strategies_date_order
    check (week_end >= week_start)
);
```

---

## 16.9 `intelligence_inputs`

```sql
create table public.intelligence_inputs (
  intelligence_object_id uuid not null references public.objects(id) on delete cascade,
  input_object_id uuid not null references public.objects(id) on delete cascade,
  input_role text not null,
  weight_or_relevance numeric,

  primary key (
    intelligence_object_id,
    input_object_id,
    input_role
  ),

  constraint intelligence_inputs_no_self_reference
    check (intelligence_object_id <> input_object_id)
);
```

---

## 16.10 `ai_feedback`

```sql
create table public.ai_feedback (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  intelligence_object_id uuid not null references public.objects(id) on delete cascade,
  feedback_type text not null,
  rating smallint,
  correction text,
  explanation text,
  created_at timestamptz not null default now(),

  constraint ai_feedback_rating_range
    check (rating is null or rating between 1 and 5)
);
```

---

# 17. Integration and Ingestion Tables

## 17.1 `sync_cursors`

```sql
create table public.sync_cursors (
  id uuid primary key default gen_random_uuid(),
  integration_account_id uuid not null
    references public.integration_accounts(id) on delete cascade,
  resource_type text not null,
  cursor_value text,
  last_synced_at timestamptz,
  sync_status text not null default 'idle',
  updated_at timestamptz not null default now(),

  constraint sync_cursors_unique_resource
    unique (integration_account_id, resource_type)
);
```

---

## 17.2 `sync_jobs`

```sql
create table public.sync_jobs (
  id uuid primary key default gen_random_uuid(),
  integration_account_id uuid not null
    references public.integration_accounts(id) on delete cascade,
  resource_type text not null,
  status job_status not null default 'queued',
  started_at timestamptz,
  completed_at timestamptz,
  records_detected integer not null default 0,
  records_processed integer not null default 0,
  records_failed integer not null default 0,
  error_summary text,
  correlation_id uuid,
  created_at timestamptz not null default now(),

  constraint sync_jobs_counts_nonnegative
    check (
      records_detected >= 0
      and records_processed >= 0
      and records_failed >= 0
    )
);
```

---

## 17.3 `ingestion_candidates`

```sql
create table public.ingestion_candidates (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  integration_account_id uuid
    references public.integration_accounts(id) on delete cascade,
  source_record_type text not null,
  source_record_id text not null,
  candidate_type text not null,
  classification text,
  extracted_payload jsonb not null,
  confidence numeric(5,4),
  status text not null default 'pending_review',
  created_at timestamptz not null default now(),
  expires_at timestamptz,

  constraint ingestion_candidates_confidence_range
    check (confidence is null or confidence between 0 and 1)
);
```

---

## 17.4 `approval_requests`

```sql
create table public.approval_requests (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  ingestion_candidate_id uuid
    references public.ingestion_candidates(id) on delete cascade,
  approval_type text not null,
  status approval_status not null default 'pending',
  summary text not null,
  proposed_action text not null,
  payload_reference jsonb,
  requested_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by uuid references public.users(id) on delete set null,
  decision_reason text,
  expires_at timestamptz,

  constraint approval_requests_summary_not_blank
    check (length(trim(summary)) > 0),

  constraint approval_requests_action_not_blank
    check (length(trim(proposed_action)) > 0)
);
```

---

## 17.5 `external_references`

```sql
create table public.external_references (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  integration_account_id uuid
    references public.integration_accounts(id) on delete cascade,
  provider text not null,
  external_type text not null,
  external_id text not null,
  internal_object_id uuid references public.objects(id) on delete cascade,
  internal_record_type text,
  internal_record_id uuid,
  created_at timestamptz not null default now(),

  constraint external_references_internal_target
    check (
      internal_object_id is not null
      or (
        internal_record_type is not null
        and internal_record_id is not null
      )
    ),

  constraint external_references_unique_external
    unique (
      integration_account_id,
      provider,
      external_type,
      external_id
    )
);
```

---

# 18. Notification, Audit, and Background Processing

## 18.1 `notifications`

```sql
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  notification_type text not null,
  title text not null,
  message text not null,
  priority notification_priority not null default 'normal',
  related_object_id uuid references public.objects(id) on delete cascade,
  read_at timestamptz,
  dismissed_at timestamptz,
  snoozed_until timestamptz,
  created_at timestamptz not null default now(),

  constraint notifications_title_not_blank
    check (length(trim(title)) > 0),

  constraint notifications_message_not_blank
    check (length(trim(message)) > 0)
);
```

---

## 18.2 `audit_logs`

```sql
create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references public.users(id) on delete set null,
  actor_type actor_type not null,
  actor_id text,
  action_type text not null,
  target_type text,
  target_id text,
  result text not null,
  ip_summary inet,
  correlation_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),

  constraint audit_logs_action_not_blank
    check (length(trim(action_type)) > 0)
);
```

Audit logs should not cascade-delete with ordinary domain records unless required by a data-deletion policy.

---

## 18.3 `background_jobs`

```sql
create table public.background_jobs (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references public.users(id) on delete cascade,
  job_type text not null,
  status job_status not null default 'queued',
  input_reference jsonb,
  attempt_count integer not null default 0,
  scheduled_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  error_summary text,
  correlation_id uuid,
  created_at timestamptz not null default now(),

  constraint background_jobs_attempts_nonnegative
    check (attempt_count >= 0)
);
```

---

# 19. Object Type Integrity

PostgreSQL foreign keys do not ensure that:

```text
projects.object_id
```

references an Object whose `object_type = 'project'`.

Career OS should enforce type integrity through one of the following:

## Recommended MVP approach

Use transactional application services plus database triggers.

Example conceptual trigger:

```sql
assert_object_type(object_id, 'project')
```

Triggers should be added for:

* Goals.
* Decisions.
* Assets.
* Projects.
* Deliverables.
* Organizations.
* People.
* Opportunities.
* Applications.
* Assessments.
* Interviews.
* Skills.
* Knowledge Items.
* Evidence.
* Documents.
* Insights.
* Recommendations.
* Career Risks.
* Daily Missions.
* Weekly Strategies.

## Alternative future approach

Use partitioned or inherited registry structures if the object system becomes significantly more complex.

---

# 20. Status Synchronization

For registered domain objects, status exists in:

* `objects.status`
* The domain-specific table.

The domain table is the canonical status owner.

The registry status is a synchronized projection for:

* Universal search.
* Filtering.
* Context panels.
* Mission Control.

Updates must occur in one transaction.

A database trigger or repository service should ensure consistency.

---

# 21. Canonical Relationship Ownership

When a dedicated foreign key or join table exists, it is canonical.

Examples:

| Meaning                             | Canonical storage                    |
| ----------------------------------- | ------------------------------------ |
| Application targets Opportunity     | `applications.opportunity_object_id` |
| Project produces Deliverable        | `deliverables.project_object_id`     |
| Person affiliated with Organization | `person_organization_affiliations`   |
| Application uses Document Version   | `application_documents`              |
| Task relates to Object              | `task_objects`                       |
| User has Skill                      | `user_skills`                        |
| Email relates to Object             | `email_object_links`                 |
| Calendar Event relates to Object    | `calendar_event_object_links`        |
| Intelligence uses input Object      | `intelligence_inputs`                |

Generic graph edges may be created as projections where useful.

The system must not allow graph and canonical relational storage to drift.

---

# 22. Deletion Rules

## 22.1 `on delete cascade`

Use when the child has no independent value without the parent.

Examples:

* Goal Milestones.
* Project Milestones.
* Decision Options.
* Decision Criteria.
* Knowledge Versions.
* Score Factors.
* Daily Mission Items.
* Email Object Links.
* Calendar Event Object Links.
* Integration Credentials.
* Sync Cursors.

## 22.2 `on delete restrict`

Use when deletion could destroy important historical evidence.

Examples:

* Opportunity referenced by an Application.
* File Object referenced by a Document Version.
* Document Version used in an Application.

## 22.3 `on delete set null`

Use when history should remain but the referenced object may be removed.

Examples:

* Activity primary object.
* Evidence reference on a lifecycle transition.
* Organization parent.
* Score factor source.
* Notification related object.
* Created-by user after account transition.

## 22.4 Hard deletion review

Hard deletion of a first-class object should check:

* Relationships.
* Activities.
* Citations.
* Tasks.
* Attachments.
* Intelligence Inputs.
* Notifications.
* External References.
* Dependent Documents.
* Application history.

---

# 23. Archive Rules

Archived records:

* Remain queryable.
* Do not appear in active default views.
* Preserve relationships and history.
* May continue to support AI explanation of historical decisions.
* Should not generate ordinary reminders or active recommendations.

Archiving a parent does not automatically archive all children unless specified by the domain workflow.

Example:

Archiving an Application should not archive the Organization, Opportunity, Documents, or People connected to it.

---

# 24. Updated-At Automation

Tables with mutable records should use an `updated_at` trigger.

Suggested function:

```sql
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
```

Apply to mutable tables such as:

* Users.
* User Preferences.
* Objects.
* Relationships.
* Goals.
* Decisions.
* Projects.
* Tasks.
* People.
* Organizations.
* Opportunities.
* Applications.
* User Skills.
* Integration Accounts.
* Email Records.
* Calendar Events.

---

# 25. Object Creation Transactions

Creating a registered object must be atomic.

Example Project creation:

```text
1. Insert Object Registry row.
2. Insert Project row using the same UUID.
3. Insert initial Lifecycle Transition.
4. Insert Activity.
5. Insert initial Relationships if supplied.
6. Commit.
```

If any step fails, the transaction rolls back.

This pattern applies to all registered objects.

---

# 26. Intelligence Persistence Rules

Persist only durable Intelligence outputs.

Persist:

* Insight.
* Recommendation.
* Career Risk.
* Score used in workflows.
* Daily Mission.
* Weekly Strategy.
* Approved AI-extracted Knowledge.

Do not persist by default:

* Temporary brainstorming.
* Intermediate model reasoning.
* Disposable drafting suggestions.
* Unapproved extracted entities.
* One-off casual chat responses.

Persisted Intelligence must include:

* Input references.
* Model identifier.
* Confidence.
* Generation time.
* Expiration or recalculation rules.
* User feedback where available.

---

# 27. Restricted Tables

The following require especially strict RLS and server-only access:

* `integration_credentials`
* `email_records.encrypted_body`
* `audit_logs`
* Restricted `file_objects`
* Immigration Evidence
* Future trading records
* Sensitive Approval payloads

Client applications must never directly query decrypted credentials.

---

# 28. Initial Migration Grouping

Recommended migration sequence:

## Migration 001 — Extensions and enums

* Extensions.
* Shared enums.
* Timestamp trigger function.

## Migration 002 — Users and profiles

* Users.
* User Profiles.
* User Preferences.

## Migration 003 — Object platform

* Objects.
* Relationships.
* Activities.
* Activity Objects.
* Lifecycle Transitions.
* Tags.
* Object Tags.

## Migration 004 — Goals and decisions

* Goals.
* Goal Milestones.
* Decisions.
* Decision Options.
* Decision Criteria.
* Decision Evaluations.
* Assets.
* Asset Measurements.

## Migration 005 — Projects and execution

* Projects.
* Project Milestones.
* Deliverables.
* Tasks.
* Task Objects.
* Task Dependencies.
* Time Blocks.
* Reminders.

## Migration 006 — People and organizations

* People.
* Organizations.
* Affiliations.
* Professional Relationships.
* Interactions.
* Interaction Participants.

## Migration 007 — Opportunities and applications

* Opportunities.
* Opportunity Requirements.
* Applications.
* Application Stage History.
* Assessments.
* Interviews.

## Migration 008 — Skills and knowledge

* Skills.
* User Skills.
* Knowledge Items.
* Knowledge Versions.
* Evidence.
* Evidence Claims.
* Citations.
* Skill Evidence.

## Migration 009 — Documents

* File Objects.
* Documents.
* Document Versions.
* Application Documents.
* Attachments.

## Migration 010 — Integrations

* Integration Accounts.
* Integration Credentials.
* Sync Cursors.
* Sync Jobs.
* Ingestion Candidates.
* Approval Requests.
* External References.
* Email Records.
* Email Object Links.
* Calendar Events.
* Calendar Event Object Links.

## Migration 011 — Intelligence

* Insights.
* Recommendations.
* Scores.
* Score Factors.
* Career Risks.
* Daily Missions.
* Daily Mission Items.
* Weekly Strategies.
* Intelligence Inputs.
* AI Feedback.

## Migration 012 — Operations

* Notifications.
* Audit Logs.
* Background Jobs.

## Migration 013 — Integrity triggers

* Object-type triggers.
* Status synchronization.
* Updated-at triggers.
* Projection synchronization.

## Migration 014 — RLS

* Enable RLS.
* Add ownership policies.
* Add server-only policies.

## Migration 015 — Indexes

* Search indexes.
* Foreign-key indexes.
* Partial active-record indexes.
* Mission Control query indexes.

---

# 29. Deferred Schema Decisions

The following remain intentionally unresolved:

1. Whether Tasks become registered Objects.
2. Whether Time Blocks become registered Objects.
3. Whether Scores become registered Objects.
4. Whether World entities become globally shared.
5. Whether relationship projections are stored or generated dynamically.
6. Whether polymorphic Attachments remain acceptable.
7. Whether email bodies use field-level encryption or an encrypted storage object.
8. Whether AI context snapshots require a dedicated table.
9. Whether custom user fields use JSON or dedicated definitions.
10. Whether application cycles become a separate table.
11. Whether Organizations require structured locations.
12. Whether compensation should be normalized in Version 1.
13. Whether Visa Pathways enter the MVP schema.
14. Whether market and trading entities enter the MVP schema.
15. Whether GraphQL or REST shape affects schema projection design.

---

# 30. Schema Acceptance Criteria

The schema is ready for migration implementation when:

* Every MVP entity maps to a concrete table.
* Every first-class object maps through `objects`.
* Ownership is unambiguous.
* Foreign keys are defined.
* Canonical facts have one authoritative table.
* Sensitive records are identifiable.
* Lifecycle history is append-oriented.
* AI outputs can be traced to inputs.
* Integration records preserve external identifiers.
* Approval-gated workflows are representable.
* Application history is reconstructable.
* Object timelines are reconstructable.
* Document versions are immutable.
* Deletion behavior is explicit.
* The schema can operate entirely on PostgreSQL and Supabase.
* No dedicated graph database is required for the MVP.

---

# 31. Next Documents

* `docs/04-database/04_INDEXING_STRATEGY.md`
* `docs/04-database/05_RLS_POLICIES.md`
* `docs/04-database/06_MIGRATION_STRATEGY.md`
* `docs/04-database/07_NAMING_CONVENTIONS.md`
* `supabase/migrations/`

