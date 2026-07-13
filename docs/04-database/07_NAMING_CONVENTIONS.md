# Career OS Database Naming Conventions

**Document ID:** DB-007
**Version:** 1.0
**Status:** Draft
**Owner:** Ahmed Kazadi Kabuya
**Last Updated:** 2026-07-12

**Related Documents:**

* `docs/02-domain/GLOSSARY.md`
* `docs/02-domain/OBJECTS.md`
* `docs/02-domain/RELATIONSHIPS.md`
* `docs/02-domain/LIFECYCLES.md`
* `docs/03-architecture/ARCHITECTURE.md`
* `docs/04-database/01_DATA_DICTIONARY.md`
* `docs/04-database/02_ERD.md`
* `docs/04-database/03_DATABASE_SCHEMA.md`
* `docs/04-database/04_INDEXING_STRATEGY.md`
* `docs/04-database/05_RLS_POLICIES.md`
* `docs/04-database/06_MIGRATION_STRATEGY.md`

---

# 1. Purpose

This document defines the canonical naming standards for the Career OS PostgreSQL and Supabase database.

It governs:

* Schemas.
* Tables.
* Columns.
* Primary keys.
* Foreign keys.
* Constraints.
* Indexes.
* PostgreSQL enums.
* Functions.
* Triggers.
* Views.
* Materialized views.
* Row-Level Security policies.
* Storage buckets and paths.
* Migration files.
* Seed files.
* Generated TypeScript names.
* Domain-to-database mappings.

The objective is to keep the database:

* Predictable.
* Searchable.
* Consistent.
* Easy to review.
* Easy to query.
* Compatible with generated TypeScript types.
* Maintainable as the platform grows.

---

# 2. General Naming Principles

## 2.1 Use one canonical term

Database names should use the canonical vocabulary defined in:

```text
docs/02-domain/GLOSSARY.md
```

Do not use multiple database terms for the same concept.

Preferred:

```text
opportunity
application
knowledge_item
relationship
```

Avoid inconsistent synonyms:

```text
job
opening
posting
lead
```

when the canonical domain concept is `Opportunity`.

## 2.2 Prefer clarity over brevity

Names should be understandable without relying on tribal knowledge.

Preferred:

```text
application_deadline
relationship_type
owner_user_id
last_interaction_at
```

Avoid:

```text
app_dl
rel_t
uid
last_int
```

## 2.3 Avoid implementation-specific names in domain tables

Preferred:

```text
people
organizations
opportunities
```

Avoid:

```text
person_records
organization_rows
opportunity_documents
```

unless the table genuinely represents those narrower concepts.

## 2.4 Names should communicate cardinality and role

Preferred:

```text
person_object_id
organization_object_id
decision_option_id
depends_on_task_id
```

Avoid ambiguous names:

```text
person
organization
option
dependency
```

## 2.5 Avoid reserved words

Do not use PostgreSQL or SQL reserved words as unquoted identifiers.

Avoid:

```text
user
order
group
role
constraint
references
current
```

Use:

```text
users
sequence_order
user_role
is_current
```

## 2.6 Never rely on quoted mixed-case identifiers

All database identifiers must be lowercase and unquoted.

Preferred:

```sql
professional_relationships
```

Avoid:

```sql
"ProfessionalRelationships"
"professionalRelationships"
```

---

# 3. Case and Separator Standard

Use lowercase `snake_case` for all PostgreSQL identifiers.

Examples:

```text
application_stage_history
owner_user_id
created_at
relationship_type
```

Do not use:

```text
camelCase
PascalCase
kebab-case
spaces
```

Technical constants represented as database values may use lowercase snake case unless the domain ontology explicitly requires uppercase technical codes.

Example application-stage value:

```text
ready_to_submit
```

Canonical relationship ontology names may appear as uppercase snake case in documentation:

```text
MENTORED_BY
SUPPORTS_GOAL
```

The database should normally store their normalized lowercase forms:

```text
mentored_by
supports_goal
```

This reduces case-sensitive comparison problems.

---

# 4. PostgreSQL Schema Names

## 4.1 Application schema

Use:

```text
public
```

for primary Career OS application tables during the MVP.

Examples:

```sql
public.objects
public.projects
public.applications
```

## 4.2 Authentication schema

Supabase authentication remains under:

```text
auth
```

Example:

```sql
auth.users
```

## 4.3 Storage schema

Supabase Storage-managed tables remain under:

```text
storage
```

Do not modify storage internals directly unless officially supported.

## 4.4 Future internal schema

A future schema may be introduced for internal-only functions:

```text
internal
```

Potential uses:

* Security-definer functions.
* Operational procedures.
* Internal projections.
* Maintenance functions.

This requires a dedicated architecture and security review before adoption.

## 4.5 Future analytics schema

A later analytics layer may use:

```text
analytics
```

for:

* Materialized views.
* Aggregations.
* Reporting projections.
* Historical metrics.

Transactional tables should remain in `public`.

---

# 5. Table Naming

## 5.1 Use plural nouns

Tables represent collections and should use plural names.

Preferred:

```text
users
objects
projects
goals
applications
people
organizations
```

Avoid:

```text
user
object
project
goal
application
person
organization
```

## 5.2 Use canonical domain nouns

Preferred:

```text
knowledge_items
professional_relationships
integration_accounts
approval_requests
```

Avoid unnecessarily generic names:

```text
items
records
data
entries
things
```

## 5.3 Link tables combine both entity names

Use plural names reflecting both sides.

Examples:

```text
object_tags
task_objects
application_documents
interaction_participants
email_object_links
calendar_event_object_links
```

When direction or role matters, use a meaningful domain name instead of a mechanical concatenation.

Example:

```text
person_organization_affiliations
```

is preferable to:

```text
people_organizations
```

because the table contains affiliation-specific attributes.

## 5.4 History tables use a descriptive suffix

Preferred:

```text
application_stage_history
lifecycle_transitions
asset_measurements
knowledge_versions
document_versions
```

Avoid:

```text
application_logs
history
changes
versions_table
```

## 5.5 Infrastructure tables use explicit nouns

Preferred:

```text
sync_jobs
sync_cursors
background_jobs
audit_logs
external_references
integration_credentials
```

## 5.6 Do not add redundant prefixes

Inside the Career OS database, avoid prefixes such as:

```text
career_os_projects
cos_projects
app_projects
```

Use:

```text
projects
```

The database context already identifies the application.

---

# 6. Column Naming

## 6.1 Primary keys

Standard table primary key:

```text
id
```

Registered-object specialization table primary key:

```text
object_id
```

Examples:

```text
tasks.id
projects.object_id
people.object_id
```

## 6.2 Foreign keys

Use:

```text
<referenced_entity_singular>_id
```

Examples:

```text
user_id
task_id
tag_id
score_id
```

For Object Registry references, preserve the semantic role:

```text
project_object_id
person_object_id
opportunity_object_id
source_object_id
target_object_id
```

Do not use generic:

```text
object_id
```

when multiple Object references exist in the same table.

## 6.3 Ownership foreign keys

Use:

```text
owner_user_id
```

for canonical record ownership.

Use:

```text
created_by
updated_by
decided_by
initiated_by
```

for action attribution.

Do not use:

```text
user_id
```

when the field specifically means ownership and the distinction matters.

## 6.4 Boolean columns

Boolean columns should read naturally as true-or-false questions.

Use prefixes:

* `is_`
* `has_`
* `can_`
* `should_`
* `requires_`

Examples:

```text
is_current
has_attachment
requires_action
follow_up_required
override_used
confirmed_by_user
```

Existing domain phrases without a prefix are acceptable when clear:

```text
selected
required
```

Avoid inverted or confusing names:

```text
not_active
disable_flag
no_follow_up
```

Prefer positive semantics:

```text
is_active
is_disabled
follow_up_required
```

## 6.5 Timestamp columns

Use `_at` for date and time.

Examples:

```text
created_at
updated_at
archived_at
submitted_at
completed_at
last_verified_at
scheduled_start
scheduled_end
```

Use `_on` only if an existing external convention requires it. Career OS should prefer `_at`.

## 6.6 Date-only columns

Use names describing the domain date without `_at`.

Examples:

```text
start_date
end_date
target_date
mission_date
week_start
week_end
```

## 6.7 Duration columns

Include the unit in the column name.

Preferred:

```text
estimated_duration_minutes
actual_duration_minutes
size_bytes
```

Avoid:

```text
duration
size
time_needed
```

## 6.8 Count columns

Use plural concept plus `_count` where the value is derived or stored.

Examples:

```text
attempt_count
records_detected
records_processed
records_failed
```

## 6.9 Score and confidence fields

Use:

```text
confidence
value
weight
priority
severity
likelihood
```

When the scale is not intrinsically defined, include:

```text
scale_min
scale_max
```

Avoid embedding a scale in the name unless it is truly fixed:

```text
confidence_percentage
score_out_of_100
```

## 6.10 Status and type columns

Use:

```text
status
<object>_type
```

Examples:

```text
project_type
opportunity_type
knowledge_type
recommendation_type
```

Avoid:

```text
kind
category_type
type_name
state_value
```

Use `stage` only when it is conceptually distinct from overall status.

Example:

```text
applications.stage
applications.status
```

## 6.11 Human-readable summaries

Use explicit names:

```text
description
summary
reasoning_summary
outcome_summary
source_summary
mitigation_summary
```

Avoid generic:

```text
text
details
info
data
```

## 6.12 External provider identifiers

Use:

```text
external_id
external_message_id
external_event_id
external_account_id
external_thread_id
```

Use provider-specific names only where the table is dedicated to that provider and the distinction improves clarity.

## 6.13 URLs and URIs

Use:

```text
website
source_url
linkedin_url
external_url
source_uri
avatar_url
```

Use `uri` when the field may contain a non-HTTP resource identifier.

Use `url` when the value is specifically web-addressable.

## 6.14 Encrypted fields

Prefix encrypted values clearly:

```text
encrypted_access_token
encrypted_refresh_token
encrypted_body
```

Do not store an encrypted value under a misleading plain-text name.

---

# 7. Primary Key Naming

Primary-key constraints should use:

```text
pk_<table>
```

Examples:

```text
pk_users
pk_objects
pk_projects
pk_task_objects
```

PostgreSQL may generate default names automatically, but explicit names are preferred in carefully managed migrations.

Example:

```sql
constraint pk_tasks primary key (id)
```

For composite keys:

```sql
constraint pk_task_objects
  primary key (task_id, object_id, relationship_role)
```

---

# 8. Foreign Key Constraint Naming

Use:

```text
fk_<child_table>__<child_column>__<parent_table>
```

Examples:

```text
fk_projects__object_id__objects
fk_tasks__owner_user_id__users
fk_applications__opportunity_object_id__opportunities
fk_document_versions__file_object_id__file_objects
```

For composite foreign keys:

```text
fk_<child_table>__<role>__<parent_table>
```

If the full name exceeds PostgreSQL’s identifier limit, shorten carefully while preserving clarity.

Avoid:

```text
projects_object_id_fkey
```

for manually named constraints, although PostgreSQL-generated names may follow that pattern.

---

# 9. Unique Constraint Naming

Use:

```text
uq_<table>__<columns_or_business_rule>
```

Examples:

```text
uq_users__email
uq_user_preferences__user_key
uq_professional_relationships__owner_person
uq_document_versions__document_version
uq_integration_accounts__owner_provider_account
```

For partial uniqueness enforced by an index, use the unique-index naming convention instead.

---

# 10. Check Constraint Naming

Use:

```text
ck_<table>__<business_rule>
```

Examples:

```text
ck_tasks__priority_range
ck_time_blocks__end_after_start
ck_relationships__no_self_link
ck_scores__value_in_scale
ck_lifecycle_transitions__override_reason_required
```

Names should describe the rule, not merely the column.

Preferred:

```text
ck_calendar_events__end_after_start
```

Avoid:

```text
ck_calendar_events__end_at
```

---

# 11. Index Naming

Use the standards defined in the Indexing Strategy.

## 11.1 Standard index

```text
idx_<table>__<columns_or_query_role>
```

Examples:

```text
idx_tasks__owner_status_due__active
idx_activities__owner_occurred
idx_relationships__owner_source_type__current
```

## 11.2 Unique index

```text
uidx_<table>__<columns_or_rule>
```

Examples:

```text
uidx_file_objects__storage_provider_path
uidx_approval_requests__candidate_type__pending
```

## 11.3 GIN index

```text
gin_<table>__<column_or_role>
```

Examples:

```text
gin_knowledge_items__search_vector
gin_user_profiles__career_interests
```

## 11.4 Trigram index

```text
trgm_<table>__<column>
```

Examples:

```text
trgm_people__full_name
trgm_organizations__name
trgm_objects__display_title
```

## 11.5 Vector index

Future vector indexes should use:

```text
vec_<table>__<column>__<method>
```

Example:

```text
vec_object_embeddings__embedding__hnsw
```

---

# 12. PostgreSQL Enum Naming

Enum type names use singular lowercase snake case.

Examples:

```text
object_layer
object_visibility
record_origin
verification_status
integration_provider
job_status
```

Enum values use lowercase snake case.

Examples:

```text
user_created
ai_inferred
future_shared
source_verified
```

Do not use uppercase enum values.

Avoid prefixing every value with the enum type.

Preferred:

```text
active
disabled
revoked
```

Avoid:

```text
integration_status_active
integration_status_disabled
```

---

# 13. Lookup Table Naming

Use lookup tables instead of enums for fast-evolving vocabularies.

Table names should be plural nouns.

Examples:

```text
relationship_types
object_types
lifecycle_definitions
notification_types
```

Suggested columns:

```text
code
display_name
description
is_active
created_at
updated_at
```

Use stable machine-readable codes in lowercase snake case.

Example:

```text
mentored_by
supports_goal
requires_skill
```

---

# 14. Function Naming

Database functions use lowercase snake case and an action-oriented verb.

Preferred prefixes:

* `get_`
* `is_`
* `has_`
* `assert_`
* `validate_`
* `create_`
* `update_`
* `record_`
* `sync_`
* `set_`
* `recalculate_`

Examples:

```text
set_updated_at
is_object_owner
assert_object_type
record_lifecycle_transition
sync_object_status
recalculate_relationship_health
```

Avoid:

```text
object_owner_check_function
do_sync
helper
process_data
```

## 14.1 Predicate functions

Boolean functions should read as questions:

```text
is_object_owner
has_object_access
can_manage_integration
```

## 14.2 Security-definer functions

Security-definer functions should have particularly explicit names.

Examples:

```text
secure_get_email_metadata
secure_approve_ingestion_candidate
```

Do not imply unrestricted capability through vague names.

---

# 15. Trigger Function Naming

Use:

```text
trgfn_<purpose>
```

Examples:

```text
trgfn_set_updated_at
trgfn_validate_object_type
trgfn_sync_object_status
trgfn_create_user_profile
```

This distinguishes trigger functions from ordinary callable functions.

---

# 16. Trigger Naming

Use:

```text
trg_<table>__<timing>_<event>__<purpose>
```

Examples:

```text
trg_projects__before_insert__validate_object_type
trg_projects__after_update__sync_object_status
trg_users__before_update__set_updated_at
trg_auth_users__after_insert__create_profile
```

Accepted timing values:

```text
before
after
instead_of
```

Accepted event values:

```text
insert
update
delete
truncate
```

For multiple events:

```text
insert_or_update
```

---

# 17. View Naming

## 17.1 Ordinary views

Use:

```text
v_<descriptive_name>
```

Examples:

```text
v_active_applications
v_object_timelines
v_mission_control_tasks
v_relationship_neighborhoods
```

Views are projections and must not be treated as canonical storage.

## 17.2 Materialized views

Use:

```text
mv_<descriptive_name>
```

Examples:

```text
mv_weekly_application_metrics
mv_goal_progress_summary
mv_relationship_activity_summary
```

## 17.3 Security views

Views used specifically to limit sensitive fields should use:

```text
v_safe_<subject>
```

Examples:

```text
v_safe_email_metadata
v_safe_integration_accounts
```

Their security model must be documented.

---

# 18. Row-Level Security Policy Naming

Use:

```text
rls_<table>__<operation>__<rule>
```

Examples:

```text
rls_tasks__select__owner
rls_tasks__insert__owner
rls_tasks__update__owner
rls_tasks__delete__owner
rls_projects__select__object_owner
rls_approval_requests__update__owner_pending
```

Operations:

* `select`
* `insert`
* `update`
* `delete`
* `all`

Avoid generic names:

```text
user_policy
allow_access
policy_1
```

---

# 19. Grant and Role Naming

Application-specific PostgreSQL roles, if introduced later, should use:

```text
career_os_<role>
```

Examples:

```text
career_os_worker
career_os_readonly
career_os_migration
```

Supabase-provided roles retain their official names:

```text
anon
authenticated
service_role
```

Do not rename or shadow built-in Supabase roles.

---

# 20. Migration File Naming

Use the standard:

```text
<timestamp>_<verb>_<subject>.sql
```

Examples:

```text
202607120001_enable_postgres_extensions.sql
202607120002_create_shared_enums.sql
202607120003_create_users_and_profiles.sql
202607120004_create_object_registry.sql
202607120005_create_relationship_graph.sql
202607120006_add_object_rls_policies.sql
```

Use one coherent subject per migration where practical.

Avoid:

```text
final.sql
database_update.sql
schema_fix_2.sql
new_changes.sql
```

---

# 21. Seed File Naming

Store seed scripts under:

```text
supabase/seed/
```

Use ordered descriptive names:

```text
001_system_reference_data.sql
002_development_demo_user.sql
003_development_demo_objects.sql
004_development_demo_relationships.sql
```

Production-safe system seeds and development demo seeds must remain separate.

Alternative environment folders may be used:

```text
supabase/seed/system/
supabase/seed/development/
```

---

# 22. Storage Bucket Naming

Use lowercase kebab case for Supabase Storage bucket names because bucket names are external resource identifiers rather than SQL identifiers.

Recommended buckets:

```text
private-documents
private-attachments
document-previews
temporary-imports
```

Avoid:

```text
CareerOSFiles
documents_bucket
all-files
uploads
```

Buckets should communicate both purpose and sensitivity.

---

# 23. Storage Path Naming

Use deterministic user-scoped paths.

Recommended format:

```text
<owner_user_id>/<object_type>/<object_id>/<file_name>
```

Example:

```text
9f.../document/2a.../resume-v3.pdf
```

For Document Versions:

```text
<owner_user_id>/documents/<document_object_id>/<version_number>/<file_name>
```

Example:

```text
9f.../documents/2a.../3/consulting-resume.pdf
```

Temporary imports:

```text
<owner_user_id>/temporary-imports/<ingestion_candidate_id>/<file_name>
```

Do not place raw email addresses or names in storage paths.

---

# 24. Object Type Codes

Object-type codes use singular lowercase snake case.

Examples:

```text
goal
decision
asset
project
deliverable
person
organization
opportunity
application
assessment
interview
skill
knowledge_item
evidence
document
insight
recommendation
career_risk
daily_mission
weekly_strategy
```

Object-type codes should match:

* Domain terminology.
* Application validation schemas.
* Database trigger validation.
* Search documents.
* TypeScript discriminated unions.

Changing a code requires a migration and compatibility review.

---

# 25. Relationship Type Codes

Database relationship-type codes use lowercase snake case.

Examples:

```text
works_for
mentored_by
supports_goal
builds
requires_skill
derived_from
about
targets
```

The documentation ontology may display:

```text
WORKS_FOR
MENTORED_BY
SUPPORTS_GOAL
```

The mapping must be one-to-one.

Do not abbreviate relationship codes.

Preferred:

```text
person_works_for_organization
```

is generally too verbose when source and target types already establish context.

Use:

```text
works_for
```

Avoid:

```text
wf
employed
job_at
```

---

# 26. Lifecycle State Codes

Lifecycle states use lowercase snake case.

Examples:

```text
ready_to_submit
final_round
in_review
partially_achieved
needs_attention
outcome_pending
```

Do not use spaces or title case in stored values.

User-facing labels are generated separately:

```text
ready_to_submit → Ready to Submit
```

Historical values should not be renamed casually because they may appear in lifecycle history and analytics.

---

# 27. Activity Type Codes

Use:

```text
<object_or_domain>.<past_tense_event>
```

Examples:

```text
application.created
application.submitted
application.stage_changed
project.completed
task.completed
interaction.recorded
recommendation.generated
recommendation.accepted
integration.connected
email.classified
```

This dot-delimited event convention is intentionally different from SQL identifier naming because values are event codes.

Event codes should describe something that happened, not a command.

Preferred:

```text
application.submitted
```

Avoid:

```text
submit_application
application.submit
```

---

# 28. Notification Type Codes

Use lowercase dot-delimited names grouped by domain.

Examples:

```text
application.deadline_approaching
interview.scheduled
relationship.follow_up_due
career_risk.detected
integration.sync_failed
approval.requested
```

Notification types should not encode presentation channel.

Avoid:

```text
email_application_deadline
push_interview_alert
```

Channel is separate from semantic type.

---

# 29. Job Type Codes

Background and synchronization job types use lowercase dot-delimited names.

Examples:

```text
gmail.sync_messages
calendar.sync_events
search.reindex_object
intelligence.refresh_recommendations
evidence.check_freshness
document.extract_text
```

Job type describes the operation, not the implementation class.

---

# 30. Approval Type Codes

Use lowercase dot-delimited codes.

Examples:

```text
email.import_body
email.send
calendar.create_event
calendar.update_event
application.change_stage
knowledge.persist_extraction
document.export
```

Approval codes should clearly identify the consequential action requiring authorization.

---

# 31. Metadata Key Naming

JSONB keys use lowercase snake case.

Example:

```json
{
  "previous_stage": "assessment",
  "new_stage": "interview",
  "source_message_id": "abc123"
}
```

Do not use a mix of snake case and camel case inside database JSON.

Provider payloads may preserve original external naming only inside a clearly isolated raw-provider field.

Example:

```json
{
  "provider": "google",
  "raw_provider_payload": {
    "historyId": "123"
  }
}
```

Canonical extracted fields should use Career OS naming.

---

# 32. Search Projection Naming

Recommended future table:

```text
search_documents
```

Recommended columns:

```text
object_id
owner_user_id
object_type
title
body_text
search_vector
updated_at
```

Avoid naming it:

```text
search_index
search_cache
elastic_documents
```

because PostgreSQL is the initial implementation and the conceptual role is a search document projection.

---

# 33. TypeScript Mapping

Database names remain snake case.

TypeScript application code may use camel case.

Example mapping:

```text
owner_user_id → ownerUserId
created_at → createdAt
application_deadline → applicationDeadline
```

Generated database types may initially retain snake-case property names.

Domain models should map database rows into application-facing types when that improves clarity and decoupling.

## 33.1 TypeScript types

Use PascalCase singular nouns.

Examples:

```text
Project
Application
KnowledgeItem
ProfessionalRelationship
```

## 33.2 Repository interfaces

Use:

```text
<Project>Repository
```

Examples:

```text
ProjectRepository
ApplicationRepository
RelationshipRepository
```

## 33.3 Database row types

Use explicit suffixes:

```text
ProjectRow
ApplicationRow
RelationshipRow
```

## 33.4 Input types

Use action-oriented names:

```text
CreateProjectInput
UpdateApplicationInput
RecordInteractionInput
```

---

# 34. API Mapping

API resource names should use plural lowercase path segments.

Examples:

```text
/projects
/applications
/knowledge-items
/professional-relationships
```

URL path segments use kebab case.

Database table:

```text
knowledge_items
```

API resource:

```text
knowledge-items
```

TypeScript type:

```text
KnowledgeItem
```

This mapping should remain predictable.

---

# 35. Environment Variable Naming

Environment variables use uppercase snake case.

Examples:

```text
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET
AI_PROVIDER_API_KEY
```

Server-only secrets must not use the `NEXT_PUBLIC_` prefix.

Environment variables should describe the credential or setting precisely.

Avoid:

```text
API_KEY
SECRET
DB
TOKEN
```

---

# 36. Database Function Parameter Naming

Function parameters should use the `p_` prefix to distinguish them from table columns.

Example:

```sql
create function public.is_object_owner(
  p_object_id uuid
)
returns boolean
```

Local variables may use the `v_` prefix.

Example:

```sql
declare
  v_owner_user_id uuid;
```

This prevents ambiguity in SQL and PL/pgSQL.

---

# 37. Function Return-Column Naming

Table-returning functions should use ordinary canonical column names.

Example:

```sql
returns table (
  object_id uuid,
  display_title text,
  relationship_type text
)
```

Do not prefix return columns with function names.

---

# 38. Temporary Object Naming

Temporary tables use:

```text
tmp_<purpose>
```

Examples:

```text
tmp_duplicate_people
tmp_object_status_backfill
```

Temporary migration columns use a descriptive transitional suffix:

```text
status_v2
normalized_name_new
```

These names must not survive indefinitely. Cleanup migrations should remove or rename them.

---

# 39. Deprecated Object Naming

Do not rename active fields with prefixes such as:

```text
old_
legacy_
deprecated_
```

as a permanent solution.

During a compatibility migration, temporary names may use:

```text
status_legacy
status_v2
```

The Migration Strategy must define removal timing.

---

# 40. Canonical Abbreviations

Avoid abbreviations unless they are universally recognized and improve readability.

Approved examples:

```text
id
url
uri
api
ai
rls
oauth
ip
mime
json
sql
utc
```

Avoid project-specific abbreviations:

```text
opp
app
rel
intg
notif
prof_rel
```

Note: `applications` may be casually called “apps” in conversation, but the database must use `applications`, not `apps`.

---

# 41. Singularization Rules

Use conventional English singular forms in foreign keys and type names.

Examples:

```text
people → person_object_id
opportunities → opportunity_object_id
knowledge_items → knowledge_object_id
```

Special cases:

```text
people → Person
evidence → Evidence
```

Do not use:

```text
people_id
evidences
```

---

# 42. Acronyms in Names

Database identifiers use lowercase acronyms as ordinary words.

Examples:

```text
oauth_account_id
api_version
ai_feedback
rls_policy_version
```

TypeScript types capitalize acronyms consistently according to the project style guide.

Recommended:

```text
AiFeedback
OauthAccount
ApiVersion
```

or, if the TypeScript standard selects full acronym capitalization:

```text
AIFeedback
OAuthAccount
APIVersion
```

Choose one TypeScript convention and apply it consistently. Database names remain unchanged.

---

# 43. Avoiding Ambiguous Terms

The following terms require qualification:

## `source`

Use:

```text
source_type
source_reference
source_uri
source_name
source_object_id
```

rather than a generic `source`.

## `type`

Use domain-specific names:

```text
project_type
evidence_type
interaction_type
```

except in generic registries where `object_type` is canonical.

## `status`

A plain `status` is acceptable within one entity table.

When multiple statuses coexist, qualify them:

```text
sync_status
import_status
verification_status
account_status
```

## `name`

A plain `name` is acceptable when the entity has one clear name.

Use qualification when multiple names exist:

```text
display_name
normalized_name
preferred_name
full_name
source_name
```

---

# 44. Table and Column Comments

Important tables and non-obvious fields should receive PostgreSQL comments in migrations.

Example:

```sql
comment on table public.objects is
  'Universal identity registry for first-class Career OS objects.';

comment on column public.relationships.confidence is
  'Normalized confidence from 0 to 1 for inferred or uncertain edges.';
```

Comments should explain domain meaning, not repeat the identifier.

Poor:

```text
The status column.
```

Better:

```text
Current domain lifecycle status synchronized from the specialized object table.
```

---

# 45. Naming Review Checklist

Before adding a database object, confirm:

1. Does it use canonical glossary terminology?
2. Is it lowercase snake case?
3. Is the table plural?
4. Is the foreign-key role clear?
5. Does the Boolean read naturally?
6. Are timestamp and date suffixes correct?
7. Are units included where necessary?
8. Does the constraint name explain the rule?
9. Does the index name explain the query path?
10. Does the function name start with an action?
11. Is the name free of unnecessary abbreviations?
12. Is it under PostgreSQL’s identifier-length limit?
13. Does it avoid reserved words?
14. Does it map predictably to TypeScript and API names?
15. Would a new engineer understand it without opening the implementation?

---

# 46. Examples of Correct Naming

## Tables

```text
professional_relationships
application_stage_history
integration_accounts
daily_mission_items
```

## Columns

```text
owner_user_id
opportunity_object_id
estimated_duration_minutes
last_verified_at
```

## Constraints

```text
ck_time_blocks__end_after_start
uq_user_preferences__user_key
fk_projects__object_id__objects
```

## Indexes

```text
idx_tasks__owner_status_due__active
trgm_people__full_name
gin_knowledge_items__search_vector
```

## Functions

```text
is_object_owner
assert_object_type
record_lifecycle_transition
```

## Policies

```text
rls_tasks__select__owner
rls_projects__update__object_owner
```

---

# 47. Examples of Incorrect Naming

Avoid:

```text
tblProject
ProjectTable
project_data
proj
apps
relation
rel_type
lastUpdate
createdDate
userID
is_not_active
function1
policy_user
idx1
final_migration
```

Replace with:

```text
projects
applications
relationships
relationship_type
updated_at
created_at
owner_user_id
is_active
is_object_owner
rls_projects__select__object_owner
idx_projects__status_priority_target
202607120001_create_projects.sql
```

---

# 48. Governance

Naming changes are architectural changes when they affect:

* Canonical domain terminology.
* Object-type codes.
* Relationship-type codes.
* Lifecycle states.
* Event codes.
* Public API resources.
* Stored external references.

Such changes require:

1. Documentation update.
2. Migration plan.
3. Compatibility review.
4. Search and indexing review.
5. AI prompt and schema review.
6. TypeScript mapping update.
7. Test updates.
8. ADR when the change is broad or irreversible.

Minor correction of an unused internal name may not require an ADR.

---

# 49. Acceptance Criteria

The naming standard is complete when:

* Every database object category has a convention.
* Table and column naming is predictable.
* Constraints and indexes are consistently named.
* Functions and triggers are distinguishable.
* RLS policies are searchable by table and operation.
* Migration filenames are descriptive and ordered.
* Object, relationship, lifecycle, activity, and notification codes are standardized.
* Storage resources follow secure predictable paths.
* Database, TypeScript, and API mappings are documented.
* Ambiguous terms and abbreviations are controlled.
* New migrations can be reviewed against a clear checklist.

---

# 50. Next Steps

The `04-database` specification set is now complete:

* `01_DATA_DICTIONARY.md`
* `02_ERD.md`
* `03_DATABASE_SCHEMA.md`
* `04_INDEXING_STRATEGY.md`
* `05_RLS_POLICIES.md`
* `06_MIGRATION_STRATEGY.md`
* `07_NAMING_CONVENTIONS.md`

The next implementation milestone is:

```text
supabase/migrations/
```

Recommended first migration:

```text
<timestamp>_enable_postgres_extensions.sql
```

followed by:

```text
<timestamp>_create_shared_enums.sql
<timestamp>_create_users_and_profiles.sql
<timestamp>_create_object_registry.sql
```

