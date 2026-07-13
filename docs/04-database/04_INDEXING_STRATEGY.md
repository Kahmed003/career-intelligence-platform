# Career OS PostgreSQL Indexing Strategy

**Document ID:** DB-004
**Version:** 1.0
**Status:** Draft
**Owner:** Ahmed Kazadi Kabuya
**Last Updated:** 2026-07-12

**Related Documents:**

* `docs/02-domain/RELATIONSHIPS.md`
* `docs/02-domain/LIFECYCLES.md`
* `docs/03-architecture/ARCHITECTURE.md`
* `docs/04-database/01_DATA_DICTIONARY.md`
* `docs/04-database/02_ERD.md`
* `docs/04-database/03_DATABASE_SCHEMA.md`
* `docs/04-database/05_RLS_POLICIES.md`

---

# 1. Purpose

This document defines the PostgreSQL indexing strategy for Career OS.

The indexing strategy is designed to support:

* Mission Control.
* User-scoped data access.
* Universal object search.
* Knowledge-graph traversal.
* Object timelines.
* Application pipeline queries.
* Opportunity discovery.
* Task and deadline prioritization.
* Relationship follow-ups.
* Gmail and Calendar synchronization.
* AI context assembly.
* Document retrieval.
* Lifecycle analytics.
* Row-Level Security performance.

This document defines the intended indexes and the reasoning behind them. Final index creation will occur through version-controlled Supabase migrations.

---

# 2. Indexing Principles

## 2.1 Index real query paths

Indexes should be created to support known product and operational queries.

Career OS should not create speculative indexes for hypothetical future features.

## 2.2 Tenant ownership comes first

Most Personal and user-scoped World records are filtered by `owner_user_id`.

Indexes for these records should generally begin with:

```sql
owner_user_id
```

This improves both application queries and Row-Level Security evaluation.

## 2.3 Prefer selective composite indexes

Composite indexes should match:

* Equality filters first.
* Range and sort columns afterward.
* Common ordering requirements.

Example:

```sql
(owner_user_id, status, due_at)
```

supports:

```sql
where owner_user_id = ?
  and status = ?
order by due_at
```

## 2.4 Use partial indexes for active records

Career OS frequently queries active, incomplete, unarchived, or pending records.

Partial indexes should exclude historical rows when possible.

Example:

```sql
where archived_at is null
  and status <> 'completed'
```

## 2.5 Foreign keys require supporting indexes

PostgreSQL does not automatically index referencing foreign-key columns.

Frequently joined foreign keys should receive explicit indexes.

## 2.6 Avoid over-indexing write-heavy ledgers

Tables such as:

* `activities`
* `audit_logs`
* `background_jobs`
* `sync_jobs`

may grow rapidly.

Indexes should support essential queries without making every write unnecessarily expensive.

## 2.7 Use specialized indexes intentionally

Career OS may use:

* B-tree indexes for equality, sorting, and ranges.
* GIN indexes for arrays, JSONB, and full-text search.
* GiST or GIN trigram indexes for fuzzy search.
* Partial unique indexes for business invariants.
* Vector indexes later for semantic search.

## 2.8 Measure before optimizing

Index effectiveness must be validated using:

```sql
explain analyze
```

and production-like data volumes.

Indexes that are unused, redundant, or harmful should be removed through migrations.

---

# 3. Expected Query Categories

The schema must optimize the following query categories.

## 3.1 Mission Control

* Incomplete Tasks due today or soon.
* Today’s Calendar Events.
* Active Daily Mission.
* Actionable Emails.
* Upcoming Application deadlines.
* Upcoming Interviews and Assessments.
* Follow-up Relationships.
* Active Career Risks.
* High-priority Notifications.

## 3.2 Object navigation

* Retrieve object by ID.
* Retrieve object by slug.
* List objects by type and status.
* Retrieve recent objects.
* Retrieve archived or active objects.
* Open Context Panel.

## 3.3 Graph traversal

* Outgoing relationships.
* Incoming relationships.
* Relationships by type.
* Current verified relationships.
* Multi-hop traversal from a selected object.

## 3.4 Timeline

* Activities for one object.
* Recent user activity.
* Lifecycle history.
* Application-stage history.
* Interactions with a Person.

## 3.5 Search

* Search object titles.
* Search People.
* Search Organizations.
* Search Opportunities.
* Search Knowledge.
* Search Documents.
* Fuzzy matching and duplicate detection.

## 3.6 Integrations

* Find external records by provider identifier.
* Incremental sync.
* Pending ingestion candidates.
* Pending approval requests.
* Failed synchronization jobs.
* Relevant Email or Calendar records.

## 3.7 Intelligence

* Active Recommendations.
* Unexpired Insights.
* Current Scores.
* Inputs for a Recommendation.
* AI feedback.
* Daily Missions and Weekly Strategies.

---

# 4. General Index Naming Convention

Use:

```text
idx_<table>__<columns>
```

For unique indexes:

```text
uidx_<table>__<columns>
```

For partial indexes, add a condition suffix:

```text
idx_tasks__owner_due__active
```

For GIN indexes:

```text
gin_<table>__<column>
```

For trigram indexes:

```text
trgm_<table>__<column>
```

Examples:

```sql
idx_objects__owner_type_status
idx_tasks__owner_due__active
uidx_applications__owner_opportunity_cycle__active
gin_user_profiles__career_interests
trgm_people__full_name
```

Names should be descriptive but remain within PostgreSQL’s identifier-length limit.

---

# 5. User and Profile Indexes

## 5.1 `users`

The primary key and unique email constraint create indexes automatically.

Additional index:

```sql
create index idx_users__account_status
  on public.users (account_status);
```

Use case:

* Administrative account-status queries.
* Disabled-account checks.

No index is initially required for `last_active_at` unless usage analytics require it.

---

## 5.2 `user_profiles`

The primary key on `user_id` is sufficient for standard profile access.

Array indexes may be useful later:

```sql
create index gin_user_profiles__career_interests
  on public.user_profiles
  using gin (career_interests);

create index gin_user_profiles__research_interests
  on public.user_profiles
  using gin (research_interests);

create index gin_user_profiles__preferred_locations
  on public.user_profiles
  using gin (preferred_locations);
```

These should be added only when profile-based matching queries are implemented.

---

## 5.3 `user_preferences`

The unique constraint on:

```sql
(user_id, preference_key)
```

supports preference retrieval.

No additional MVP index is required.

---

# 6. Object Registry Indexes

## 6.1 Active objects by owner

```sql
create index idx_objects__owner_type_status__active
  on public.objects (
    owner_user_id,
    object_type,
    status
  )
  where archived_at is null;
```

Supports:

* Listing active Projects.
* Listing active Goals.
* Listing Applications by status.
* Universal module queries.

## 6.2 Recent objects

```sql
create index idx_objects__owner_updated__active
  on public.objects (
    owner_user_id,
    updated_at desc
  )
  where archived_at is null;
```

Supports:

* Recently updated items.
* Continue Working On.
* Recent object activity.

## 6.3 Slug lookup

The schema’s unique constraint supports owner/type/slug lookup.

Where slugs are frequently resolved without object type, add:

```sql
create index idx_objects__owner_slug
  on public.objects (owner_user_id, slug)
  where slug is not null
    and archived_at is null;
```

## 6.4 Display-title search

For prefix and fuzzy search:

```sql
create index trgm_objects__display_title
  on public.objects
  using gin (display_title gin_trgm_ops);
```

## 6.5 Source reference

```sql
create index idx_objects__owner_source_reference
  on public.objects (
    owner_user_id,
    source_reference
  )
  where source_reference is not null;
```

Supports:

* Imported-object deduplication.
* Source-origin lookup.

---

# 7. Relationship Graph Indexes

The `relationships` table is central to graph traversal.

## 7.1 Outgoing traversal

```sql
create index idx_relationships__owner_source_type__current
  on public.relationships (
    owner_user_id,
    source_object_id,
    relationship_type
  )
  where is_current = true;
```

Supports:

* Everything connected outward from an object.
* Projects supporting a Goal.
* Opportunities requiring a Skill.

## 7.2 Incoming traversal

```sql
create index idx_relationships__owner_target_type__current
  on public.relationships (
    owner_user_id,
    target_object_id,
    relationship_type
  )
  where is_current = true;
```

Supports:

* Everything pointing to an object.
* People connected to an Organization.
* Evidence supporting an Insight.

## 7.3 All current neighboring edges

```sql
create index idx_relationships__owner_source__current
  on public.relationships (
    owner_user_id,
    source_object_id
  )
  where is_current = true;

create index idx_relationships__owner_target__current
  on public.relationships (
    owner_user_id,
    target_object_id
  )
  where is_current = true;
```

These may overlap with the typed indexes. Retain them only if query plans show benefit for type-agnostic graph-neighborhood queries.

## 7.4 Relationship-type exploration

```sql
create index idx_relationships__owner_type__current
  on public.relationships (
    owner_user_id,
    relationship_type
  )
  where is_current = true;
```

Supports:

* All mentors.
* All relationships requiring a Skill.
* All Goal-support edges.

## 7.5 Verification and confidence

```sql
create index idx_relationships__owner_verification
  on public.relationships (
    owner_user_id,
    verification_status
  )
  where is_current = true;
```

Supports:

* Pending relationship confirmation.
* Inferred-edge review.

## 7.6 Relationship deduplication

Create targeted partial unique indexes for relationship types requiring one current edge.

Example:

```sql
create unique index uidx_relationships__owner_source_target_type__current
  on public.relationships (
    owner_user_id,
    source_object_id,
    target_object_id,
    relationship_type
  )
  where is_current = true
    and relationship_type in (
      'SUPPORTS',
      'BUILDS',
      'REQUIRES',
      'ABOUT',
      'TARGETS'
    );
```

Do not apply this universally because repeated temporal relationships may be legitimate.

## 7.7 Metadata

Do not create a general GIN index on `relationships.metadata` initially.

Add targeted expression indexes only when a real query requires them.

---

# 8. Activity Ledger Indexes

## 8.1 Object timeline

```sql
create index idx_activities__owner_primary_occurred
  on public.activities (
    owner_user_id,
    primary_object_id,
    occurred_at desc
  )
  where primary_object_id is not null;
```

Supports:

* Application timeline.
* Project timeline.
* Person-related activity.

## 8.2 User-wide recent activity

```sql
create index idx_activities__owner_occurred
  on public.activities (
    owner_user_id,
    occurred_at desc
  );
```

Supports:

* Recent Activity feed.
* Mission Control updates.
* Weekly reviews.

## 8.3 Activity type analytics

```sql
create index idx_activities__owner_type_occurred
  on public.activities (
    owner_user_id,
    activity_type,
    occurred_at desc
  );
```

Supports:

* Recent Applications submitted.
* Recent Tasks completed.
* Recent networking interactions.

## 8.4 Correlation tracing

```sql
create index idx_activities__correlation_id
  on public.activities (correlation_id)
  where correlation_id is not null;
```

Supports:

* Tracing ingestion and workflow events.

## 8.5 `activity_objects`

The primary key begins with `activity_id`.

Add reverse lookup:

```sql
create index idx_activity_objects__object_activity
  on public.activity_objects (
    object_id,
    activity_id
  );
```

This is necessary for object timelines involving secondary related objects.

---

# 9. Lifecycle Indexes

## 9.1 Object lifecycle history

```sql
create index idx_lifecycle_transitions__object_time
  on public.lifecycle_transitions (
    object_id,
    transitioned_at desc
  );
```

## 9.2 User transition analytics

```sql
create index idx_lifecycle_transitions__owner_status_time
  on public.lifecycle_transitions (
    owner_user_id,
    new_status,
    transitioned_at desc
  );
```

## 9.3 Override review

```sql
create index idx_lifecycle_transitions__owner_override
  on public.lifecycle_transitions (
    owner_user_id,
    transitioned_at desc
  )
  where override_used = true;
```

---

# 10. Tags and Object Tags

## 10.1 Tag lookup

The unique constraint on:

```sql
(owner_user_id, normalized_name)
```

supports exact lookup.

For fuzzy Tag search:

```sql
create index trgm_tags__name
  on public.tags
  using gin (name gin_trgm_ops);
```

## 10.2 Reverse Tag lookup

The primary key on `object_tags` begins with `object_id`.

Add:

```sql
create index idx_object_tags__tag_object
  on public.object_tags (
    tag_id,
    object_id
  );
```

Supports:

* Find all objects carrying a Tag.

---

# 11. Goals, Assets, and Decisions

## 11.1 Active Goals

```sql
create index idx_goals__status_priority_target
  on public.goals (
    status,
    priority,
    target_date
  );
```

Because ownership exists through `objects`, most Goal queries will join through Object Registry.

For performance-critical Mission Control queries, a denormalized `owner_user_id` may eventually be added to `goals`, but the MVP should first measure join performance.

## 11.2 Goal Milestones

```sql
create index idx_goal_milestones__goal_status_target
  on public.goal_milestones (
    goal_object_id,
    status,
    target_date
  );
```

## 11.3 Asset history

```sql
create index idx_asset_measurements__asset_measured
  on public.asset_measurements (
    asset_object_id,
    measured_at desc
  );
```

## 11.4 Decision deadlines

```sql
create index idx_decisions__status_deadline
  on public.decisions (
    status,
    decision_deadline
  )
  where decision_deadline is not null;
```

## 11.5 Decision Options

```sql
create index idx_decision_options__decision_sequence
  on public.decision_options (
    decision_object_id,
    sequence_order
  );
```

## 11.6 Decision Criteria

The unique constraint on Decision and criterion name supports lookup.

Add ordering only if the schema later introduces `sequence_order`.

## 11.7 Decision Evaluations

The unique option-criterion constraint supports both direct keys.

Add:

```sql
create index idx_decision_evaluations__criterion_option
  on public.decision_evaluations (
    decision_criterion_id,
    decision_option_id
  );
```

This supports comparison of all Options against one Criterion.

---

# 12. Project and Task Indexes

## 12.1 Active Projects

```sql
create index idx_projects__status_priority_target
  on public.projects (
    status,
    priority,
    target_end_date
  );
```

## 12.2 Project Milestones

```sql
create index idx_project_milestones__project_status_target
  on public.project_milestones (
    project_object_id,
    status,
    target_date
  );
```

## 12.3 Project Deliverables

```sql
create index idx_deliverables__project_status_target
  on public.deliverables (
    project_object_id,
    status,
    target_date
  );
```

## 12.4 Mission Control Tasks

```sql
create index idx_tasks__owner_status_due__active
  on public.tasks (
    owner_user_id,
    status,
    due_at
  )
  where archived_at is null
    and status not in ('completed', 'cancelled');
```

## 12.5 Tasks ordered by priority

```sql
create index idx_tasks__owner_priority_due__active
  on public.tasks (
    owner_user_id,
    priority,
    due_at
  )
  where archived_at is null
    and status not in ('completed', 'cancelled');
```

## 12.6 Overdue Tasks

```sql
create index idx_tasks__owner_due__open
  on public.tasks (
    owner_user_id,
    due_at
  )
  where archived_at is null
    and completed_at is null
    and due_at is not null;
```

## 12.7 Recently completed Tasks

```sql
create index idx_tasks__owner_completed
  on public.tasks (
    owner_user_id,
    completed_at desc
  )
  where completed_at is not null;
```

## 12.8 Task-object reverse lookup

The primary key begins with `task_id`.

Add:

```sql
create index idx_task_objects__object_task
  on public.task_objects (
    object_id,
    task_id
  );
```

## 12.9 Task dependencies

The primary key supports dependency lookup from Task.

Add:

```sql
create index idx_task_dependencies__dependency_task
  on public.task_dependencies (
    depends_on_task_id,
    task_id
  );
```

Supports:

* Which Tasks are blocked by this prerequisite?

## 12.10 Time Blocks by date

```sql
create index idx_time_blocks__owner_start
  on public.time_blocks (
    owner_user_id,
    start_at
  );
```

## 12.11 Active proposed Time Blocks

```sql
create index idx_time_blocks__owner_status_start
  on public.time_blocks (
    owner_user_id,
    status,
    start_at
  )
  where status in ('proposed', 'scheduled', 'confirmed');
```

## 12.12 Time Blocks by Task

```sql
create index idx_time_blocks__task_start
  on public.time_blocks (
    task_id,
    start_at
  )
  where task_id is not null;
```

## 12.13 Reminders due for delivery

```sql
create index idx_reminders__status_time
  on public.reminders (
    status,
    remind_at
  )
  where status = 'scheduled';
```

## 12.14 User reminder list

```sql
create index idx_reminders__owner_time
  on public.reminders (
    owner_user_id,
    remind_at
  );
```

---

# 13. People and Organization Indexes

## 13.1 Person-name fuzzy search

```sql
create index trgm_people__full_name
  on public.people
  using gin (full_name gin_trgm_ops);
```

## 13.2 Person email

```sql
create index idx_people__primary_email
  on public.people (primary_email)
  where primary_email is not null;
```

Because World objects are user-scoped through Object Registry, cross-user uniqueness should not be enforced.

## 13.3 LinkedIn profile deduplication

```sql
create index idx_people__linkedin_url
  on public.people (linkedin_url)
  where linkedin_url is not null;
```

## 13.4 Organization-name fuzzy search

```sql
create index trgm_organizations__name
  on public.organizations
  using gin (name gin_trgm_ops);
```

## 13.5 Organization normalized name

```sql
create index idx_organizations__normalized_name
  on public.organizations (normalized_name);
```

## 13.6 Organization domain

```sql
create index idx_organizations__primary_domain
  on public.organizations (primary_domain)
  where primary_domain is not null;
```

## 13.7 Parent Organization

```sql
create index idx_organizations__parent
  on public.organizations (parent_organization_object_id)
  where parent_organization_object_id is not null;
```

## 13.8 Person-Organization affiliations

```sql
create index idx_affiliations__owner_person_current
  on public.person_organization_affiliations (
    owner_user_id,
    person_object_id,
    is_current
  );

create index idx_affiliations__owner_organization_current
  on public.person_organization_affiliations (
    owner_user_id,
    organization_object_id,
    is_current
  );
```

## 13.9 Professional Relationships needing follow-up

```sql
create index idx_professional_relationships__owner_follow_up
  on public.professional_relationships (
    owner_user_id,
    next_follow_up_at
  )
  where next_follow_up_at is not null
    and status not in ('ended', 'archived');
```

## 13.10 Dormant Relationships

```sql
create index idx_professional_relationships__owner_last_interaction
  on public.professional_relationships (
    owner_user_id,
    last_interaction_at
  )
  where status not in ('ended', 'archived');
```

## 13.11 Interactions by time

```sql
create index idx_interactions__owner_occurred
  on public.interactions (
    owner_user_id,
    occurred_at desc
  );
```

## 13.12 Interaction participants

The primary key supports Interaction-to-participants.

Add reverse lookup:

```sql
create index idx_interaction_participants__object_interaction
  on public.interaction_participants (
    object_id,
    interaction_id
  );
```

Supports:

* All interactions involving a Person.
* All meetings related to an Application.

---

# 14. Opportunity and Application Indexes

## 14.1 Opportunity deadline pipeline

```sql
create index idx_opportunities__status_deadline
  on public.opportunities (
    status,
    application_deadline
  )
  where application_deadline is not null;
```

## 14.2 Opportunities by Organization

```sql
create index idx_opportunities__organization_status
  on public.opportunities (
    organization_object_id,
    status
  )
  where organization_object_id is not null;
```

## 14.3 Opportunity source deduplication

```sql
create index idx_opportunities__external_identifier
  on public.opportunities (external_identifier)
  where external_identifier is not null;

create index idx_opportunities__source_url
  on public.opportunities (source_url)
  where source_url is not null;
```

Deduplication should combine these indexes with Organization and source context rather than assume global uniqueness.

## 14.4 Opportunity Requirements

```sql
create index idx_opportunity_requirements__opportunity_required
  on public.opportunity_requirements (
    opportunity_object_id,
    required,
    importance
  );
```

## 14.5 Application pipeline

```sql
create index idx_applications__stage_priority_deadline
  on public.applications (
    stage,
    priority,
    application_deadline
  );
```

Because ownership is through Object Registry, application queries typically join Objects.

If pipeline performance is inadequate, consider adding `owner_user_id` directly to `applications` through a future ADR.

## 14.6 Applications by Opportunity

```sql
create index idx_applications__opportunity
  on public.applications (
    opportunity_object_id,
    application_cycle
  );
```

## 14.7 Active Application uniqueness

A partial unique index must account for the owner stored in Object Registry. PostgreSQL cannot directly create a cross-table unique index.

Recommended MVP enforcement:

* Transactional application service.
* Database trigger.

Alternative future schema:

* Add `owner_user_id` directly to `applications`.
* Then create:

```sql
create unique index uidx_applications__owner_opportunity_cycle__active
  on public.applications (
    owner_user_id,
    opportunity_object_id,
    application_cycle
  )
  where status not in (
    'rejected',
    'withdrawn',
    'declined',
    'completed',
    'archived'
  );
```

## 14.8 Application stage history

```sql
create index idx_application_stage_history__application_time
  on public.application_stage_history (
    application_object_id,
    changed_at desc
  );
```

## 14.9 Assessments due soon

```sql
create index idx_assessments__application_status_due
  on public.assessments (
    application_object_id,
    status,
    due_at
  );
```

## 14.10 Interviews by schedule

```sql
create index idx_interviews__application_start
  on public.interviews (
    application_object_id,
    scheduled_start
  );

create index idx_interviews__status_start
  on public.interviews (
    status,
    scheduled_start
  )
  where scheduled_start is not null;
```

## 14.11 Application Documents

The primary key supports Application-to-Documents.

Add reverse lookup:

```sql
create index idx_application_documents__version_application
  on public.application_documents (
    document_version_id,
    application_object_id
  );
```

Supports:

* Which Applications used this resume version?

---

# 15. Skill Indexes

## 15.1 Skill-name search

```sql
create index trgm_skills__name
  on public.skills
  using gin (name gin_trgm_ops);
```

## 15.2 Normalized Skill name

```sql
create index idx_skills__normalized_name
  on public.skills (normalized_name);
```

## 15.3 Skill hierarchy

```sql
create index idx_skills__parent
  on public.skills (parent_skill_object_id)
  where parent_skill_object_id is not null;
```

## 15.4 User Skills

The unique owner/Skill constraint supports direct lookup.

Add:

```sql
create index idx_user_skills__owner_target
  on public.user_skills (
    owner_user_id,
    target_level
  );
```

only when skill-development dashboards require it.

## 15.5 Skill Evidence

The primary key supports UserSkill-to-Evidence.

Add:

```sql
create index idx_skill_evidence__evidence_skill
  on public.skill_evidence (
    evidence_object_id,
    user_skill_id
  );
```

---

# 16. Knowledge and Evidence Indexes

## 16.1 Knowledge full-text search

Add a generated search vector in the migration or maintain it through a trigger.

Conceptual column:

```sql
search_vector tsvector
```

Index:

```sql
create index gin_knowledge_items__search_vector
  on public.knowledge_items
  using gin (search_vector);
```

The vector should include:

* Object display title.
* Knowledge content.
* Knowledge type.
* Source summary.

Because display title is in `objects`, maintaining the combined vector may require a trigger or dedicated search projection.

## 16.2 Knowledge status

```sql
create index idx_knowledge_items__status_type
  on public.knowledge_items (
    status,
    knowledge_type
  );
```

## 16.3 Knowledge Versions

The unique Knowledge/version constraint supports version retrieval.

Add:

```sql
create index idx_knowledge_versions__knowledge_created
  on public.knowledge_versions (
    knowledge_object_id,
    created_at desc
  );
```

## 16.4 Evidence source lookup

```sql
create index idx_evidence__source_uri
  on public.evidence (source_uri)
  where source_uri is not null;
```

## 16.5 Evidence freshness

```sql
create index idx_evidence__verification_last_verified
  on public.evidence (
    verification_status,
    last_verified_at
  );
```

Supports:

* Stale Evidence detection.
* Verification queues.

## 16.6 Evidence publication date

```sql
create index idx_evidence__published
  on public.evidence (published_at desc)
  where published_at is not null;
```

## 16.7 Evidence Claims

```sql
create index idx_evidence_claims__evidence
  on public.evidence_claims (
    evidence_object_id,
    created_at
  );
```

## 16.8 Citation reverse lookup

The unique Citation constraint begins with `source_object_id`.

Add:

```sql
create index idx_citations__evidence_source
  on public.citations (
    evidence_object_id,
    source_object_id
  );
```

Supports:

* Everything supported by this Evidence.

---

# 17. Document and File Indexes

## 17.1 Documents by type and status

```sql
create index idx_documents__type_status
  on public.documents (
    document_type,
    status
  );
```

## 17.2 Document versions

The unique Document/version constraint supports ordered version access.

Add:

```sql
create index idx_document_versions__document_created
  on public.document_versions (
    document_object_id,
    created_at desc
  );
```

## 17.3 File ownership

```sql
create index idx_file_objects__owner_uploaded
  on public.file_objects (
    owner_user_id,
    uploaded_at desc
  );
```

## 17.4 File checksum deduplication

```sql
create index idx_file_objects__owner_checksum
  on public.file_objects (
    owner_user_id,
    checksum
  )
  where checksum is not null;
```

## 17.5 Storage path

```sql
create unique index uidx_file_objects__storage_provider_path
  on public.file_objects (
    storage_provider,
    storage_path
  );
```

## 17.6 Attachments

```sql
create index idx_attachments__parent_object
  on public.attachments (
    parent_object_id,
    created_at
  )
  where parent_object_id is not null;

create index idx_attachments__record_parent
  on public.attachments (
    parent_record_type,
    parent_record_id,
    created_at
  )
  where parent_record_type is not null
    and parent_record_id is not null;
```

---

# 18. Email and Calendar Indexes

## 18.1 Email uniqueness

The unique Integration Account and external message constraint supports provider lookup.

## 18.2 Actionable Emails

```sql
create index idx_email_records__owner_action_sent
  on public.email_records (
    owner_user_id,
    sent_at desc
  )
  where requires_action = true;
```

## 18.3 Email classification

```sql
create index idx_email_records__owner_classification_sent
  on public.email_records (
    owner_user_id,
    classification,
    sent_at desc
  );
```

## 18.4 Email thread

```sql
create index idx_email_records__integration_thread_sent
  on public.email_records (
    integration_account_id,
    external_thread_id,
    sent_at
  )
  where external_thread_id is not null;
```

## 18.5 Email full-text search

Do not index encrypted email bodies directly.

Metadata search may use a generated vector containing:

* Subject.
* Sender summary.
* Recipient summary.
* Snippet.

```sql
create index gin_email_records__metadata_search
  on public.email_records
  using gin (
    to_tsvector(
      'simple',
      coalesce(subject, '') || ' ' ||
      coalesce(sender_summary, '') || ' ' ||
      coalesce(recipient_summary, '') || ' ' ||
      coalesce(snippet, '')
    )
  );
```

Expression-index immutability requirements must be validated during migration implementation. A stored generated column may be preferable.

## 18.6 Email Object Links

The primary key supports Email-to-Objects.

Add reverse lookup:

```sql
create index idx_email_object_links__object_email
  on public.email_object_links (
    object_id,
    email_record_id
  );
```

## 18.7 Calendar Mission Control

```sql
create index idx_calendar_events__owner_start
  on public.calendar_events (
    owner_user_id,
    start_at
  );
```

## 18.8 Active Calendar window

```sql
create index idx_calendar_events__owner_status_start
  on public.calendar_events (
    owner_user_id,
    status,
    start_at
  );
```

## 18.9 Calendar Event external identity

The unique Integration Account/external event constraint supports synchronization.

## 18.10 Calendar Event Object Links

Add reverse lookup:

```sql
create index idx_calendar_event_links__object_event
  on public.calendar_event_object_links (
    object_id,
    calendar_event_id
  );
```

---

# 19. Intelligence Indexes

## 19.1 Active Insights

```sql
create index idx_insights__status_expiration
  on public.insights (
    status,
    expires_at
  )
  where status in ('generated', 'active', 'acknowledged');
```

## 19.2 Recommendations for Mission Control

```sql
create index idx_recommendations__status_priority_valid
  on public.recommendations (
    status,
    priority,
    valid_until
  )
  where status in ('generated', 'presented', 'accepted', 'deferred');
```

## 19.3 Scores by subject

```sql
create index idx_scores__owner_subject_type_calculated
  on public.scores (
    owner_user_id,
    subject_object_id,
    score_type,
    calculated_at desc
  );
```

## 19.4 Current Scores

```sql
create index idx_scores__owner_type_expiration
  on public.scores (
    owner_user_id,
    score_type,
    expires_at
  );
```

## 19.5 Score Factors

```sql
create index idx_score_factors__score
  on public.score_factors (
    score_id,
    id
  );

create index idx_score_factors__source
  on public.score_factors (
    source_object_id,
    score_id
  )
  where source_object_id is not null;
```

## 19.6 Active Career Risks

```sql
create index idx_career_risks__status_severity_expiration
  on public.career_risks (
    status,
    severity desc,
    expires_at
  )
  where status in (
    'detected',
    'active',
    'acknowledged',
    'mitigation_planned',
    'mitigating'
  );
```

## 19.7 Daily Mission uniqueness

Because owner exists in Object Registry, one Mission per owner/date cannot be enforced with a simple table index.

Recommended MVP enforcement:

* Application transaction.
* Database trigger checking Object Registry ownership.

If `owner_user_id` is later added to `daily_missions`, create:

```sql
create unique index uidx_daily_missions__owner_date__active
  on public.daily_missions (
    owner_user_id,
    mission_date
  )
  where status not in ('replaced', 'archived');
```

## 19.8 Daily Mission Items

The unique Mission/sequence constraint supports ordered retrieval.

Add:

```sql
create index idx_daily_mission_items__task
  on public.daily_mission_items (
    related_task_id,
    daily_mission_object_id
  )
  where related_task_id is not null;

create index idx_daily_mission_items__object
  on public.daily_mission_items (
    related_object_id,
    daily_mission_object_id
  )
  where related_object_id is not null;
```

## 19.9 Weekly Strategies

```sql
create index idx_weekly_strategies__week
  on public.weekly_strategies (
    week_start desc,
    week_end
  );
```

## 19.10 Intelligence Inputs

The primary key supports Intelligence-to-inputs.

Add reverse lookup:

```sql
create index idx_intelligence_inputs__input_output
  on public.intelligence_inputs (
    input_object_id,
    intelligence_object_id
  );
```

Supports:

* Which Recommendations depend on this Evidence?
* Which Intelligence must be recalculated when an object changes?

## 19.11 AI Feedback

```sql
create index idx_ai_feedback__intelligence_created
  on public.ai_feedback (
    intelligence_object_id,
    created_at desc
  );

create index idx_ai_feedback__owner_type_created
  on public.ai_feedback (
    owner_user_id,
    feedback_type,
    created_at desc
  );
```

---

# 20. Integration and Ingestion Indexes

## 20.1 Integration Accounts

The unique owner/provider/external account constraint supports direct lookup.

Add:

```sql
create index idx_integration_accounts__owner_status
  on public.integration_accounts (
    owner_user_id,
    status
  );
```

## 20.2 Credentials

Primary key on Integration Account is sufficient.

No token-content indexes should ever be created.

## 20.3 Sync Cursors

The unique account/resource constraint supports cursor retrieval.

## 20.4 Sync Jobs

```sql
create index idx_sync_jobs__account_resource_created
  on public.sync_jobs (
    integration_account_id,
    resource_type,
    created_at desc
  );

create index idx_sync_jobs__status_created
  on public.sync_jobs (
    status,
    created_at
  )
  where status in ('queued', 'running', 'failed', 'retrying');
```

## 20.5 Ingestion review queue

```sql
create index idx_ingestion_candidates__owner_status_created
  on public.ingestion_candidates (
    owner_user_id,
    status,
    created_at desc
  );
```

## 20.6 Candidate source deduplication

```sql
create index idx_ingestion_candidates__account_source
  on public.ingestion_candidates (
    integration_account_id,
    source_record_type,
    source_record_id
  )
  where integration_account_id is not null;
```

A partial unique index may be appropriate when duplicate Candidates should be prohibited.

## 20.7 Candidate expiration

```sql
create index idx_ingestion_candidates__status_expires
  on public.ingestion_candidates (
    status,
    expires_at
  )
  where expires_at is not null;
```

## 20.8 Pending Approvals

```sql
create index idx_approval_requests__owner_status_requested
  on public.approval_requests (
    owner_user_id,
    status,
    requested_at desc
  );
```

## 20.9 Approval expiration

```sql
create index idx_approval_requests__status_expires
  on public.approval_requests (
    status,
    expires_at
  )
  where status = 'pending'
    and expires_at is not null;
```

## 20.10 External References

The unique external-reference constraint supports provider lookup.

Add internal reverse indexes:

```sql
create index idx_external_references__object
  on public.external_references (
    internal_object_id,
    provider
  )
  where internal_object_id is not null;

create index idx_external_references__record
  on public.external_references (
    internal_record_type,
    internal_record_id,
    provider
  )
  where internal_record_type is not null
    and internal_record_id is not null;
```

---

# 21. Notification, Audit, and Job Indexes

## 21.1 Unread Notifications

```sql
create index idx_notifications__owner_unread_created
  on public.notifications (
    owner_user_id,
    created_at desc
  )
  where read_at is null
    and dismissed_at is null;
```

## 21.2 Notification priority

```sql
create index idx_notifications__owner_priority_created
  on public.notifications (
    owner_user_id,
    priority,
    created_at desc
  )
  where dismissed_at is null;
```

## 21.3 Snoozed Notifications

```sql
create index idx_notifications__snoozed_until
  on public.notifications (snoozed_until)
  where snoozed_until is not null
    and dismissed_at is null;
```

## 21.4 Audit correlation

```sql
create index idx_audit_logs__correlation
  on public.audit_logs (correlation_id)
  where correlation_id is not null;
```

## 21.5 Audit user and time

```sql
create index idx_audit_logs__owner_occurred
  on public.audit_logs (
    owner_user_id,
    occurred_at desc
  )
  where owner_user_id is not null;
```

## 21.6 Audit action type

```sql
create index idx_audit_logs__action_occurred
  on public.audit_logs (
    action_type,
    occurred_at desc
  );
```

Avoid indexing broad JSONB audit metadata until a defined investigation query requires it.

## 21.7 Background job queue

```sql
create index idx_background_jobs__status_schedule
  on public.background_jobs (
    status,
    scheduled_at
  )
  where status in ('queued', 'retrying');
```

## 21.8 Background jobs by owner

```sql
create index idx_background_jobs__owner_created
  on public.background_jobs (
    owner_user_id,
    created_at desc
  )
  where owner_user_id is not null;
```

## 21.9 Correlation tracing

```sql
create index idx_background_jobs__correlation
  on public.background_jobs (correlation_id)
  where correlation_id is not null;
```

---

# 22. Full-Text Search Architecture

## 22.1 Phase 1 approach

Use PostgreSQL full-text search and trigram matching.

Searchable object categories:

* Objects.
* People.
* Organizations.
* Opportunities.
* Knowledge Items.
* Documents.
* Skills.

## 22.2 Search projection recommendation

Rather than constructing cross-table search vectors during every query, create a future table:

```text
search_documents
```

Suggested fields:

```sql
object_id
owner_user_id
object_type
title
body_text
search_vector
updated_at
```

This table would act as a search projection, not a canonical data source.

## 22.3 Search projection indexes

```sql
create unique index uidx_search_documents__object
  on public.search_documents (object_id);

create index gin_search_documents__search_vector
  on public.search_documents
  using gin (search_vector);

create index trgm_search_documents__title
  on public.search_documents
  using gin (title gin_trgm_ops);

create index idx_search_documents__owner_type
  on public.search_documents (
    owner_user_id,
    object_type
  );
```

## 22.4 Hybrid ranking

Initial ranking should combine:

* Full-text relevance.
* Title similarity.
* Object type.
* Recency.
* Active status.
* Current context.

Later phases may add:

* Semantic similarity.
* Relationship distance.
* Goal Alignment.
* User interaction history.

---

# 23. Semantic Search and Vector Indexes

Semantic search is deferred until embeddings are implemented.

Potential future table:

```text
object_embeddings
```

Potential fields:

```sql
id
owner_user_id
object_id
embedding_type
model_identifier
content_hash
embedding vector
created_at
```

Potential index:

```sql
create index idx_object_embeddings__vector
  on public.object_embeddings
  using hnsw (embedding vector_cosine_ops);
```

The exact index type and parameters must be selected after measuring:

* Data volume.
* Recall.
* Latency.
* Update frequency.
* Supported Supabase/PostgreSQL version.

Embedding indexes must remain scoped by owner or tenant at query time.

---

# 24. Row-Level Security Performance

RLS policies will commonly compare:

```sql
owner_user_id = auth.uid()
```

Every directly user-owned table should therefore have an index beginning with `owner_user_id`.

Examples:

* `objects`
* `tasks`
* `time_blocks`
* `professional_relationships`
* `interactions`
* `email_records`
* `calendar_events`
* `scores`
* `integration_accounts`
* `notifications`
* `approval_requests`

Tables inheriting ownership through parent objects require join-aware RLS policies.

Where RLS joins become expensive, consider:

* Adding `owner_user_id` directly to high-volume child tables.
* Using security-definer helper functions carefully.
* Maintaining ownership consistency with triggers.
* Avoiding deeply nested policy joins.

Any ownership denormalization requires a documented canonical source and consistency rule.

---

# 25. Mission Control Composite Indexes

Mission Control is the highest-priority read path.

Initial index coverage should support:

## Tasks

```sql
(owner_user_id, status, due_at)
```

## Calendar

```sql
(owner_user_id, start_at)
```

## Notifications

```sql
(owner_user_id, created_at)
where unread
```

## Relationships

```sql
(owner_user_id, next_follow_up_at)
```

## Email

```sql
(owner_user_id, sent_at)
where requires_action
```

## Approvals

```sql
(owner_user_id, status, requested_at)
```

## Daily Mission

Mission ownership currently requires joining Object Registry.

If measured performance is insufficient, add `owner_user_id` directly to:

* `daily_missions`
* `career_risks`
* `recommendations`
* `insights`
* `applications`

through a future schema decision.

---

# 26. Covering Indexes and Included Columns

PostgreSQL supports included columns.

Use `include` only when:

* The query is frequent.
* Index-only scans materially improve performance.
* Included columns are relatively small.
* Write overhead remains acceptable.

Example candidate:

```sql
create index idx_tasks__owner_status_due_cover
  on public.tasks (
    owner_user_id,
    status,
    due_at
  )
  include (
    title,
    priority,
    estimated_duration_minutes
  )
  where archived_at is null
    and status not in ('completed', 'cancelled');
```

Do not create covering indexes until query analysis demonstrates value.

Large text, JSONB, and encrypted fields should not be included.

---

# 27. JSONB Index Policy

Avoid blanket GIN indexes on every JSONB column.

Consider indexing:

* `objects.metadata`
* `relationships.metadata`
* `recommendations.expected_impact`
* `ingestion_candidates.extracted_payload`

only when stable query paths exist.

Prefer expression indexes for important keys.

Example:

```sql
create index idx_ingestion_candidates__payload_deadline
  on public.ingestion_candidates (
    ((extracted_payload ->> 'deadline')::timestamptz)
  )
  where extracted_payload ? 'deadline';
```

Only use this when the payload contract and query are stable.

Canonical domain fields should be promoted from JSONB into typed columns.

---

# 28. Array Index Policy

GIN indexes may support containment queries on:

* Career interests.
* Research interests.
* Preferred locations.
* Shared interests.
* Granted scopes.

Use them only when arrays are actively filtered.

Examples:

```sql
create index gin_professional_relationships__shared_interests
  on public.professional_relationships
  using gin (shared_interests);

create index gin_integration_accounts__granted_scopes
  on public.integration_accounts
  using gin (granted_scopes);
```

Do not add these until corresponding product features exist.

---

# 29. Partial Unique Indexes

Partial unique indexes should enforce important active-record invariants.

Potential examples:

## One current Document Version

Because current state is represented indirectly by `documents.current_version_id`, no additional unique index is required initially.

If version status is used directly:

```sql
create unique index uidx_document_versions__document_current
  on public.document_versions (document_object_id)
  where status = 'current';
```

## One pending Approval per action

```sql
create unique index uidx_approval_requests__candidate_type__pending
  on public.approval_requests (
    ingestion_candidate_id,
    approval_type
  )
  where status = 'pending'
    and ingestion_candidate_id is not null;
```

## One active provider cursor

Already enforced with the Sync Cursor unique constraint.

## One current Professional Relationship

Already enforced through User and Person uniqueness.

## One active edge

Use relationship-type-specific partial unique indexes.

---

# 30. Indexes for Analytics

Analytics queries often span long histories.

Avoid prematurely adding many analytics indexes to transactional tables.

Initial analytics indexes:

* Activities by owner and time.
* Lifecycle transitions by object and time.
* Application stage history by Application and time.
* Asset measurements by Asset and time.
* Scores by subject and calculated time.
* Interactions by owner and time.

Later, introduce:

* Materialized views.
* Aggregation tables.
* Warehouse exports.

Complex analytics should not degrade Mission Control or transactional workloads.

---

# 31. Index Maintenance

## 31.1 Monitor index usage

Use PostgreSQL statistics such as:

* `pg_stat_user_indexes`
* `pg_stat_all_tables`
* `pg_statio_user_indexes`

Review:

* Index scan counts.
* Sequential scans.
* Index size.
* Table size.
* Dead tuples.
* Write amplification.

## 31.2 Remove redundant indexes

A composite index may make a narrower index redundant when the leading columns match.

Example:

```sql
(owner_user_id, status, due_at)
```

may support queries filtering by owner and status, reducing the need for:

```sql
(owner_user_id, status)
```

This must be confirmed through query plans.

## 31.3 Reindexing

Managed PostgreSQL normally handles routine index reliability.

Use `reindex concurrently` only when needed and operationally supported.

## 31.4 Autovacuum

High-write tables require appropriate autovacuum monitoring:

* Activities.
* Email Records.
* Calendar Events.
* Sync Jobs.
* Background Jobs.
* Notifications.

---

# 32. Index Rollout Strategy

## Phase 1 — Foundational indexes

Create:

* Primary keys.
* Unique constraints.
* Foreign-key indexes.
* Ownership indexes.
* Mission Control indexes.
* Graph traversal indexes.
* Timeline indexes.
* Synchronization indexes.

## Phase 2 — Search indexes

Create:

* Trigram indexes.
* Full-text search projection.
* Evidence and Knowledge search.

## Phase 3 — Analytics indexes

Create only after real analytical queries are identified.

## Phase 4 — Semantic indexes

Introduce vector indexes after embedding architecture is approved.

---

# 33. Initial Migration Index Set

The first production index migration should prioritize:

1. Active Objects by owner/type/status.
2. Recent Objects.
3. Object title trigram search.
4. Outgoing and incoming Relationships.
5. Current Relationships by type.
6. Activities by owner/time.
7. Activities by primary Object/time.
8. Activity Object reverse lookup.
9. Lifecycle history by Object/time.
10. Open Tasks by owner/status/due date.
11. Time Blocks by owner/start.
12. Reminders by status/time.
13. People name trigram search.
14. Organization name trigram search.
15. Affiliations by Person and Organization.
16. Relationship follow-up.
17. Interactions by owner/time.
18. Opportunities by deadline.
19. Applications by stage/deadline.
20. Application stage history.
21. Assessments and Interviews by deadline/time.
22. Knowledge full-text search.
23. Evidence verification/freshness.
24. Document versions by Document.
25. Actionable Emails.
26. Calendar Events by owner/start.
27. Active Recommendations and Risks.
28. Scores by subject/type.
29. Intelligence Input reverse lookup.
30. Integration synchronization queues.
31. Pending Ingestion Candidates.
32. Pending Approval Requests.
33. Unread Notifications.
34. Background job queue.
35. Audit correlation lookup.

---

# 34. Index Review Checklist

Before adding an index, confirm:

1. Which query requires it?
2. How frequently does that query run?
3. What percentage of rows does it select?
4. Does another index already support it?
5. Does column order match the query?
6. Can a partial index reduce size?
7. Does the index support RLS filtering?
8. What is the write overhead?
9. Will the index contain sensitive data?
10. Can the query be redesigned instead?
11. Has the query been tested with `EXPLAIN ANALYZE`?
12. Is the index needed in the current product phase?

---

# 35. Risks and Mitigations

## Risk: Too many indexes

Impact:

* Slower writes.
* Larger storage.
* More maintenance.
* Slower migrations.

Mitigation:

* Phase index rollout.
* Monitor usage.
* Remove redundant indexes.

## Risk: RLS policies force expensive joins

Mitigation:

* Index ownership paths.
* Consider controlled owner denormalization.
* Test policy queries at realistic scale.

## Risk: Generic graph traversal becomes slow

Mitigation:

* Maintain source and target indexes.
* Use relationship-type filters.
* Cache common neighborhoods.
* Add graph projection only after measured need.

## Risk: Search results become slow or irrelevant

Mitigation:

* Use a dedicated search projection.
* Combine full-text and trigram ranking.
* Add semantic search later.

## Risk: Encrypted fields cannot be indexed

Mitigation:

* Index safe metadata.
* Maintain approved classifications and structured extracted fields.
* Never weaken encryption solely for search convenience.

## Risk: Partial-index conditions diverge from business states

Mitigation:

* Centralize lifecycle constants.
* Update indexes through reviewed migrations when states change.
* Add regression tests for active-state queries.

---

# 36. Acceptance Criteria

The indexing strategy is ready for implementation when:

* Every primary and foreign-key access path is reviewed.
* Mission Control queries have supporting indexes.
* RLS ownership filtering is indexed.
* Graph traversal supports incoming and outgoing edges.
* Object timelines can be retrieved efficiently.
* Application pipelines and deadlines are indexed.
* Relationship follow-ups are indexed.
* Synchronization queues are indexed.
* Active Intelligence outputs are indexed.
* Search has a phased implementation path.
* Encrypted content is not exposed through indexes.
* Partial indexes correspond to approved lifecycle states.
* Index naming is consistent.
* Redundancy is minimized.
* Indexes can be created through version-controlled migrations.

---

# 37. Next Documents

* `docs/04-database/05_RLS_POLICIES.md`
* `docs/04-database/06_MIGRATION_STRATEGY.md`
* `docs/04-database/07_NAMING_CONVENTIONS.md`
* `supabase/migrations/015_indexes.sql`

