# Career OS Data Dictionary

**Document ID:** DB-001
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
* `docs/09-decisions/ADR-0001-postgresql-graph-compatible-model.md`
* `docs/09-decisions/ADR-0005-hybrid-object-registry.md`
* `docs/09-decisions/ADR-0006-hybrid-relationship-architecture.md`
* `docs/09-decisions/ADR-0007-hybrid-activity-ledger.md`
* `docs/09-decisions/ADR-0008-intelligent-ai-persistence.md`

---

# 1. Purpose

This document defines the persistent data entities used by Career OS.

For each entity, it specifies:

* Business meaning.
* Architectural layer.
* Canonical ownership.
* Persistence role.
* Core attributes.
* Privacy classification.
* Key constraints.
* Lifecycle expectations.
* Relationships.
* AI usage.
* Audit requirements.

This is a logical data dictionary. Final PostgreSQL data types, indexes, foreign keys, enums, and Row-Level Security policies will be specified in later database documents.

---

# 2. Data Classification

## Public

Information already intended for public distribution.

Examples:

* Public company website.
* Public job posting.
* Published research paper.

## Internal

Ordinary Career OS operational data.

Examples:

* Project status.
* Opportunity classification.
* Non-sensitive tags.

## Confidential

Private professional information.

Examples:

* Applications.
* Networking notes.
* Goals.
* Decisions.
* Private documents.

## Restricted

Highly sensitive data requiring strict access controls.

Examples:

* OAuth refresh tokens.
* Email bodies.
* Immigration records.
* Trading records.
* Private contact details.
* Identity documentation.

---

# 3. Shared Persistence Conventions

Most persistent entities should include:

* `id`
* `created_at`
* `updated_at`
* `created_by`
* `archived_at`
* `source_type`
* `source_reference`
* `metadata`

Personal entities should additionally include:

* `owner_user_id`
* `visibility`

Externally sourced entities should preserve:

* Provenance.
* Capture time.
* Source URI or provider identifier.
* Verification status.
* Last verified time where relevant.

AI-generated entities should preserve:

* Model identifier.
* Prompt or instruction version.
* Supporting input references.
* Confidence.
* Generated time.
* Expiration or recalculation condition.

---

# 4. Identity and Tenancy Entities

## 4.1 User

### Business definition

A person with an authenticated Career OS account.

### Architectural layer

Identity layer.

### Canonical owner

Career OS identity system.

### Purpose

Provides account identity, tenancy boundary, ownership, preferences, and access control.

### Core attributes

* `id`
* `email`
* `display_name`
* `avatar_url`
* `timezone`
* `locale`
* `onboarding_status`
* `account_status`
* `created_at`
* `updated_at`
* `last_active_at`

### Privacy classification

Confidential.

### Key constraints

* Email must be unique within the authentication system.
* Account status must use a controlled lifecycle.
* Authentication credentials are not stored in ordinary application tables.

### Relationships

* Owns Personal objects.
* Connects Integration Accounts.
* Receives Notifications.
* Creates Activities.
* Approves Approval Requests.

---

## 4.2 UserProfile

### Business definition

The user’s professional identity and strategic background inside Career OS.

### Purpose

Stores persistent context used for personalization and AI recommendations.

### Core attributes

* `user_id`
* `professional_summary`
* `education_summary`
* `career_interests`
* `research_interests`
* `preferred_locations`
* `work_authorization_summary`
* `short_term_objectives`
* `long_term_objectives`
* `profile_completeness`
* `updated_at`

### Privacy classification

Confidential; some fields may be Restricted.

### Key constraints

* One active profile per User.
* AI-inferred fields must remain distinguishable from user-confirmed fields.

---

## 4.3 UserPreference

### Purpose

Stores configurable product behavior.

### Core attributes

* `id`
* `user_id`
* `preference_key`
* `preference_value`
* `source`
* `created_at`
* `updated_at`

### Examples

* Default reminder interval.
* Preferred dashboard modules.
* Notification frequency.
* AI recommendation aggressiveness.
* Working hours.

---

# 5. Universal Object Platform

## 5.1 ObjectRegistry

### Business definition

The universal identity record for every first-class Career OS object.

### Architectural layer

Object Registry layer.

### Purpose

Provides stable identity across modules and enables:

* Typed relationships.
* Universal search.
* Activities.
* Attachments.
* Tags.
* Intelligence references.
* Context panels.
* Cross-domain navigation.

### Core attributes

* `id`
* `object_type`
* `owner_user_id`
* `display_title`
* `slug`
* `layer`
* `visibility`
* `status`
* `source_type`
* `created_at`
* `updated_at`
* `archived_at`

### Privacy classification

Inherited from the underlying domain object.

### Key constraints

* Each first-class object has exactly one Object Registry record.
* Each registry record maps to no more than one active domain record of its declared type.
* Object type changes are normally prohibited.
* World objects may initially remain user-scoped.

---

## 5.2 Relationship

### Business definition

A typed, directed connection between two registered objects.

### Architectural layer

Graph layer.

### Purpose

Stores the canonical relationship graph.

### Core attributes

* `id`
* `owner_user_id`
* `relationship_type`
* `source_object_id`
* `target_object_id`
* `origin_type`
* `verification_status`
* `confidence`
* `valid_from`
* `valid_until`
* `is_current`
* `evidence_summary`
* `metadata`
* `created_at`
* `updated_at`

### Privacy classification

Inherited from connected objects and relationship sensitivity.

### Key constraints

* Source and target objects must exist.
* Relationship type must support the source and target object types.
* Duplicate active edges should be prevented where the ontology requires uniqueness.
* AI-inferred edges must be clearly marked.

---

## 5.3 Activity

### Business definition

An append-oriented record of a meaningful event or state change.

### Architectural layer

Activity Ledger layer.

### Purpose

Powers:

* Object timelines.
* Audit history.
* Analytics.
* AI context.
* Notifications.
* Lifecycle reconstruction.

### Core attributes

* `id`
* `owner_user_id`
* `activity_type`
* `actor_type`
* `actor_id`
* `primary_object_id`
* `occurred_at`
* `origin_type`
* `correlation_id`
* `summary`
* `metadata`
* `created_at`

### Privacy classification

Inherited from related objects.

### Key constraints

* Activities should be immutable after creation except for controlled corrections.
* Material changes should create compensating Activities rather than overwrite history.
* Sensitive payloads should not be duplicated unnecessarily.

---

## 5.4 ActivityObject

### Purpose

Associates an Activity with additional related objects.

### Core attributes

* `activity_id`
* `object_id`
* `role`

### Example roles

* primary
* related
* actor
* source
* target
* evidence

---

## 5.5 LifecycleTransition

### Purpose

Stores formal status transitions for lifecycle-enabled entities.

### Core attributes

* `id`
* `object_id`
* `previous_status`
* `new_status`
* `transition_origin`
* `transition_reason`
* `override_used`
* `override_reason`
* `initiated_by`
* `transitioned_at`
* `evidence_reference`

### Key constraints

* Transition history is append-only.
* Override transitions require a reason.
* Current object status must be reconcilable with transition history.

---

## 5.6 Tag

### Purpose

Provides lightweight user-defined or system-generated categorization.

### Core attributes

* `id`
* `owner_user_id`
* `name`
* `normalized_name`
* `description`
* `color_reference`
* `created_at`

### Key constraints

* Normalized name should be unique per owner.
* Tags must not replace formal object types or relationship semantics.

---

## 5.7 ObjectTag

### Purpose

Associates Tags with registered objects.

### Core attributes

* `object_id`
* `tag_id`
* `assigned_by`
* `assigned_at`

---

# 6. Career and Strategy Entities

## 6.1 Goal

### Business definition

A desired future outcome pursued by the user.

### Architectural layer

Personal.

### Core attributes

* `object_id`
* `goal_type`
* `description`
* `priority`
* `status`
* `start_date`
* `target_date`
* `success_criteria`
* `motivation`
* `progress_method`
* `progress_value`
* `confidence_level`

### Privacy classification

Confidential.

### Key constraints

* Must reference an Object Registry record of type Goal.
* Active Goals require success criteria.
* AI-estimated progress must be marked as inferred.

---

## 6.2 GoalMilestone

### Purpose

Represents an intermediate outcome supporting a Goal.

### Core attributes

* `id`
* `goal_object_id`
* `title`
* `description`
* `status`
* `target_date`
* `completed_at`
* `weight`
* `sequence_order`

---

## 6.3 Decision

### Business definition

A meaningful choice requiring evaluation of options and evidence.

### Architectural layer

Personal.

### Core attributes

* `object_id`
* `decision_question`
* `description`
* `decision_type`
* `status`
* `importance`
* `reversibility`
* `decision_deadline`
* `final_choice_summary`
* `decision_date`
* `outcome_summary`
* `reflection`

### Privacy classification

Confidential.

---

## 6.4 DecisionOption

### Purpose

Represents one alternative considered within a Decision.

### Core attributes

* `id`
* `decision_object_id`
* `title`
* `description`
* `status`
* `estimated_value`
* `confidence`
* `selected`
* `sequence_order`

---

## 6.5 DecisionCriterion

### Purpose

Defines how Decision Options are evaluated.

### Core attributes

* `id`
* `decision_object_id`
* `name`
* `description`
* `weight`
* `measurement_method`

---

## 6.6 DecisionEvaluation

### Purpose

Stores an Option’s evaluation against a Criterion.

### Core attributes

* `id`
* `decision_option_id`
* `decision_criterion_id`
* `score`
* `rationale`
* `confidence`
* `source_type`

---

## 6.7 Asset

### Business definition

A long-term capability, resource, reputation, relationship, or body of work that increases career value.

### Architectural layer

Personal.

### Core attributes

* `object_id`
* `asset_type`
* `description`
* `status`
* `current_level`
* `measurement_method`
* `last_evaluated_at`

### Privacy classification

Confidential.

---

## 6.8 AssetMeasurement

### Purpose

Stores periodic observations of Asset development.

### Core attributes

* `id`
* `asset_object_id`
* `measured_at`
* `value`
* `measurement_type`
* `confidence`
* `evidence_summary`
* `source_type`

---

# 7. Projects and Execution Entities

## 7.1 Project

### Business definition

A deliberate investment intended to create long-term career value and Deliverables.

### Architectural layer

Personal.

### Core attributes

* `object_id`
* `project_type`
* `description`
* `mission`
* `status`
* `priority`
* `start_date`
* `target_end_date`
* `actual_end_date`
* `expected_outcomes`
* `success_criteria`
* `health_status`

### Privacy classification

Confidential unless explicitly published.

---

## 7.2 ProjectMilestone

### Core attributes

* `id`
* `project_object_id`
* `title`
* `description`
* `status`
* `target_date`
* `completed_at`
* `sequence_order`
* `weight`

---

## 7.3 Deliverable

### Business definition

A concrete output produced by a Project.

### Core attributes

* `object_id`
* `project_object_id`
* `deliverable_type`
* `description`
* `status`
* `target_date`
* `completed_at`
* `external_url`

---

## 7.4 Task

### Business definition

A discrete unit of actionable work.

### Architectural layer

Supporting Personal record.

### Core attributes

* `id`
* `owner_user_id`
* `title`
* `description`
* `status`
* `priority`
* `due_at`
* `estimated_duration_minutes`
* `actual_duration_minutes`
* `completed_at`
* `source_type`
* `created_at`
* `updated_at`

### Privacy classification

Confidential.

### Key constraints

* A Task should represent one executable action.
* Completed Tasks require a completion time.
* Project-like work must not be modeled as a single Task.

---

## 7.5 TaskObject

### Purpose

Associates Tasks with one or more relevant objects.

### Core attributes

* `task_id`
* `object_id`
* `relationship_role`

### Example roles

* supports
* prepares_for
* generated_from
* blocked_by
* about

---

## 7.6 TaskDependency

### Purpose

Defines ordering and blocking dependencies between Tasks.

### Core attributes

* `task_id`
* `depends_on_task_id`
* `dependency_type`
* `created_at`

---

## 7.7 TimeBlock

### Business definition

A scheduled period reserved for intended work.

### Core attributes

* `id`
* `owner_user_id`
* `title`
* `start_at`
* `end_at`
* `timezone`
* `status`
* `task_id`
* `external_calendar_event_id`
* `source_type`
* `created_at`
* `updated_at`

### Key constraints

* End time must follow start time.
* AI-proposed Time Blocks remain proposed until approved.

---

## 7.8 Reminder

### Purpose

Prompts the user about an action or object at a specified time.

### Core attributes

* `id`
* `owner_user_id`
* `remind_at`
* `status`
* `channel`
* `related_object_id`
* `related_task_id`
* `created_at`

---

# 8. Opportunity and Application Entities

## 8.1 Opportunity

### Business definition

An external opening, program, event, resource, or relationship capable of advancing a Goal.

### Architectural layer

World.

### Core attributes

* `object_id`
* `opportunity_type`
* `organization_object_id`
* `description`
* `status`
* `location_text`
* `work_arrangement`
* `eligibility_summary`
* `application_deadline`
* `deadline_timezone`
* `start_date`
* `end_date`
* `compensation_summary`
* `funding_summary`
* `visa_summary`
* `source_url`
* `external_identifier`
* `published_at`
* `last_verified_at`

### Privacy classification

Usually Public or Internal.

### Key constraints

* Externally sourced Opportunities require provenance.
* Expired Opportunities remain available historically.
* Visa and funding claims must preserve source Evidence.

---

## 8.2 OpportunityRequirement

### Purpose

Represents a required or preferred qualification.

### Core attributes

* `id`
* `opportunity_object_id`
* `requirement_type`
* `description`
* `importance`
* `required`
* `source_excerpt`

---

## 8.3 Application

### Business definition

The user’s pursuit of a specific Opportunity.

### Architectural layer

Personal.

### Core attributes

* `object_id`
* `opportunity_object_id`
* `stage`
* `status`
* `priority`
* `application_deadline`
* `submitted_at`
* `decision_date`
* `outcome`
* `source`
* `created_at`
* `updated_at`

### Privacy classification

Confidential.

### Key constraints

* Must reference exactly one Opportunity.
* Only one active Application should normally exist per User and Opportunity.
* Submitted stage requires a submission timestamp.

---

## 8.4 ApplicationStageHistory

### Purpose

Stores detailed Application stage transitions and stage durations.

### Core attributes

* `id`
* `application_object_id`
* `previous_stage`
* `new_stage`
* `changed_at`
* `changed_by`
* `origin_type`
* `reason`
* `evidence_reference`

---

## 8.5 Assessment

### Purpose

Represents a formal evaluation connected to an Application.

### Core attributes

* `object_id`
* `application_object_id`
* `assessment_type`
* `status`
* `invited_at`
* `due_at`
* `completed_at`
* `result_summary`
* `provider`
* `external_url`

---

## 8.6 Interview

### Purpose

Represents a formal interview stage or session.

### Core attributes

* `object_id`
* `application_object_id`
* `interview_type`
* `round_name`
* `status`
* `scheduled_start`
* `scheduled_end`
* `timezone`
* `location_or_link`
* `outcome_summary`

---

## 8.7 ApplicationDocument

### Purpose

Associates a specific Document Version with an Application.

### Core attributes

* `application_object_id`
* `document_version_id`
* `usage_type`
* `submitted_at`

---

# 9. People and Organization Entities

## 9.1 Person

### Business definition

An individual relevant to the user’s professional journey.

### Architectural layer

World.

### Core attributes

* `object_id`
* `full_name`
* `preferred_name`
* `headline`
* `biography`
* `location_text`
* `primary_email`
* `phone_number`
* `linkedin_url`
* `personal_website`
* `source_type`
* `last_verified_at`

### Privacy classification

Public, Confidential, or Restricted depending on the field.

### Key constraints

* Potential duplicates should be reviewed rather than silently merged.
* Relationship strength must not be stored directly on the Person.

---

## 9.2 Organization

### Business definition

A company, university, laboratory, nonprofit, agency, investment firm, or professional institution.

### Architectural layer

World.

### Core attributes

* `object_id`
* `name`
* `normalized_name`
* `organization_type`
* `description`
* `website`
* `primary_domain`
* `headquarters_text`
* `size_category`
* `parent_organization_object_id`
* `source_type`
* `last_verified_at`

### Privacy classification

Usually Public or Internal.

---

## 9.3 PersonOrganizationAffiliation

### Purpose

Stores structured affiliations between People and Organizations.

### Core attributes

* `id`
* `person_object_id`
* `organization_object_id`
* `affiliation_type`
* `title`
* `department`
* `start_date`
* `end_date`
* `is_current`
* `source_type`

---

## 9.4 ProfessionalRelationship

### Business definition

The structured connection between the User and a Person.

### Core attributes

* `id`
* `owner_user_id`
* `person_object_id`
* `relationship_type`
* `status`
* `started_at`
* `last_interaction_at`
* `next_follow_up_at`
* `shared_interests`
* `user_notes`
* `created_at`
* `updated_at`

### Privacy classification

Confidential.

---

## 9.5 Interaction

### Business definition

A meaningful communication or engagement with a Person or Organization.

### Core attributes

* `id`
* `owner_user_id`
* `interaction_type`
* `occurred_at`
* `channel`
* `summary`
* `follow_up_required`
* `follow_up_due_at`
* `source_type`
* `created_at`

### Privacy classification

Confidential.

---

## 9.6 InteractionParticipant

### Purpose

Associates People and Organizations with an Interaction.

### Core attributes

* `interaction_id`
* `object_id`
* `participant_role`

---

# 10. Skills and Growth Entities

## 10.1 Skill

### Business definition

A reusable capability that may be learned, demonstrated, required, or improved.

### Architectural layer

World.

### Core attributes

* `object_id`
* `name`
* `normalized_name`
* `skill_category`
* `description`
* `parent_skill_object_id`
* `source_type`

---

## 10.2 UserSkill

### Purpose

Stores the User’s relationship with a Skill.

### Core attributes

* `id`
* `owner_user_id`
* `skill_object_id`
* `claimed_level`
* `inferred_level`
* `target_level`
* `confidence`
* `last_practiced_at`
* `last_evaluated_at`

### Privacy classification

Confidential.

---

## 10.3 SkillEvidence

### Purpose

Links Skill claims or inferred proficiency to Evidence.

### Core attributes

* `user_skill_id`
* `evidence_object_id`
* `evidence_role`
* `confidence`

---

# 11. Knowledge and Evidence Entities

## 11.1 KnowledgeItem

### Business definition

A reusable unit of understanding.

### Architectural layer

Personal.

### Core attributes

* `object_id`
* `knowledge_type`
* `content`
* `status`
* `confidence`
* `source_summary`
* `created_at`
* `updated_at`

### Privacy classification

Confidential unless explicitly shared.

---

## 11.2 KnowledgeVersion

### Purpose

Stores meaningful revisions to a Knowledge Item.

### Core attributes

* `id`
* `knowledge_object_id`
* `version_number`
* `content`
* `change_summary`
* `created_by`
* `created_at`

---

## 11.3 Evidence

### Business definition

A source-backed fact, communication, record, or artifact.

### Architectural layer

World or user-scoped external reference.

### Core attributes

* `object_id`
* `evidence_type`
* `title`
* `source_uri`
* `source_name`
* `captured_at`
* `published_at`
* `content_excerpt`
* `authority_level`
* `verification_status`
* `last_verified_at`

### Privacy classification

Public, Confidential, or Restricted according to source.

---

## 11.4 EvidenceClaim

### Purpose

Represents a specific claim extracted from Evidence.

### Core attributes

* `id`
* `evidence_object_id`
* `claim_text`
* `claim_type`
* `confidence`
* `valid_from`
* `valid_until`
* `extracted_by`

---

## 11.5 Citation

### Purpose

Links a Knowledge Item, Decision, Insight, Recommendation, or Document to Evidence.

### Core attributes

* `id`
* `source_object_id`
* `evidence_object_id`
* `citation_role`
* `excerpt`
* `created_at`

---

# 12. Document and File Entities

## 12.1 Document

### Business definition

A structured, independently managed professional artifact.

### Architectural layer

Personal.

### Core attributes

* `object_id`
* `document_type`
* `status`
* `current_version_id`
* `description`
* `sensitivity`
* `created_at`
* `updated_at`

### Privacy classification

Confidential or Restricted.

---

## 12.2 DocumentVersion

### Purpose

Represents one immutable version of a Document.

### Core attributes

* `id`
* `document_object_id`
* `version_number`
* `file_object_id`
* `status`
* `change_summary`
* `created_by`
* `created_at`

### Key constraints

* Original versions must not be overwritten.
* Only one version should normally be Current.

---

## 12.3 FileObject

### Purpose

Stores metadata for an uploaded or linked file.

### Core attributes

* `id`
* `owner_user_id`
* `file_name`
* `mime_type`
* `size_bytes`
* `storage_provider`
* `storage_path`
* `checksum`
* `sensitivity`
* `uploaded_at`

### Privacy classification

Inherited from the parent context; private by default.

---

## 12.4 Attachment

### Purpose

Associates a File Object with another object or supporting record.

### Core attributes

* `id`
* `file_id`
* `parent_object_id`
* `parent_record_type`
* `parent_record_id`
* `attachment_role`
* `created_at`

---

# 13. Communication and Calendar Entities

## 13.1 EmailRecord

### Business definition

A Career OS representation of a relevant external email.

### Architectural layer

Integration-supporting record.

### Core attributes

* `id`
* `owner_user_id`
* `integration_account_id`
* `external_message_id`
* `external_thread_id`
* `subject`
* `sender_summary`
* `recipient_summary`
* `sent_at`
* `snippet`
* `classification`
* `requires_action`
* `sensitivity`
* `import_status`
* `created_at`

### Privacy classification

Restricted.

### Key constraints

* Full email body should be stored only when required and approved.
* External identifiers must remain unique within an Integration Account.

---

## 13.2 EmailObjectLink

### Purpose

Links an Email Record to relevant registered objects.

### Core attributes

* `email_record_id`
* `object_id`
* `link_type`
* `confidence`
* `confirmed_by_user`

---

## 13.3 CalendarEvent

### Business definition

A Career OS representation of an external or internal scheduled event.

### Core attributes

* `id`
* `owner_user_id`
* `integration_account_id`
* `external_event_id`
* `title`
* `description`
* `start_at`
* `end_at`
* `timezone`
* `location`
* `event_type`
* `status`
* `import_status`

### Privacy classification

Confidential or Restricted.

---

## 13.4 CalendarEventObjectLink

### Purpose

Links Calendar Events to Applications, People, Projects, Tasks, Interviews, or other objects.

### Core attributes

* `calendar_event_id`
* `object_id`
* `link_type`
* `confidence`
* `confirmed_by_user`

---

# 14. Intelligence Entities

## 14.1 Insight

### Business definition

A durable interpretation derived from Evidence, Knowledge, relationships, or patterns.

### Architectural layer

Intelligence.

### Core attributes

* `object_id`
* `insight_type`
* `summary`
* `status`
* `confidence`
* `generated_at`
* `expires_at`
* `model_identifier`
* `instruction_version`

### Privacy classification

Inherited from supporting inputs.

---

## 14.2 Recommendation

### Business definition

A durable proposal for an action, prioritization, decision, or strategy.

### Architectural layer

Intelligence.

### Core attributes

* `object_id`
* `recommendation_type`
* `recommended_action`
* `reasoning_summary`
* `priority`
* `confidence`
* `expected_impact`
* `status`
* `valid_until`
* `generated_at`
* `model_identifier`

---

## 14.3 Score

### Purpose

Stores an explainable evaluation.

### Core attributes

* `id`
* `owner_user_id`
* `score_type`
* `subject_object_id`
* `value`
* `scale_min`
* `scale_max`
* `confidence`
* `factor_summary`
* `calculated_at`
* `expires_at`
* `model_version`

---

## 14.4 ScoreFactor

### Purpose

Stores the major factors contributing to a Score.

### Core attributes

* `id`
* `score_id`
* `factor_name`
* `factor_value`
* `weight`
* `rationale`
* `source_object_id`

---

## 14.5 CareerRisk

### Business definition

A durable warning about a condition that may reduce Goal success.

### Core attributes

* `object_id`
* `risk_type`
* `description`
* `severity`
* `likelihood`
* `time_horizon`
* `mitigation_summary`
* `status`
* `detected_at`
* `expires_at`

---

## 14.6 DailyMission

### Business definition

A prioritized daily execution plan generated for the User.

### Core attributes

* `object_id`
* `mission_date`
* `summary`
* `status`
* `estimated_workload_minutes`
* `deadline_risk`
* `generated_at`
* `confirmed_at`

---

## 14.7 DailyMissionItem

### Purpose

Associates Tasks, Events, Opportunities, or Recommendations with a Daily Mission.

### Core attributes

* `id`
* `daily_mission_object_id`
* `related_object_id`
* `related_task_id`
* `sequence_order`
* `priority`
* `reasoning_summary`
* `estimated_duration_minutes`

---

## 14.8 WeeklyStrategy

### Business definition

A durable tactical plan for the upcoming week.

### Core attributes

* `object_id`
* `week_start`
* `week_end`
* `summary`
* `status`
* `generated_at`
* `confirmed_at`

---

## 14.9 IntelligenceInput

### Purpose

Links Intelligence objects to the inputs used to generate them.

### Core attributes

* `intelligence_object_id`
* `input_object_id`
* `input_role`
* `weight_or_relevance`

---

## 14.10 AIFeedback

### Purpose

Stores user feedback on an AI-generated output.

### Core attributes

* `id`
* `owner_user_id`
* `intelligence_object_id`
* `feedback_type`
* `rating`
* `correction`
* `explanation`
* `created_at`

---

# 15. Integration and Synchronization Entities

## 15.1 IntegrationAccount

### Business definition

A connection between Career OS and an external provider account.

### Core attributes

* `id`
* `owner_user_id`
* `provider`
* `external_account_id`
* `display_name`
* `status`
* `granted_scopes`
* `connected_at`
* `last_successful_sync_at`
* `last_error_at`

### Privacy classification

Restricted.

---

## 15.2 IntegrationCredential

### Purpose

Stores protected credential material for an Integration Account.

### Core attributes

* `integration_account_id`
* `encrypted_access_token`
* `encrypted_refresh_token`
* `token_expires_at`
* `encryption_version`
* `updated_at`

### Privacy classification

Restricted.

### Key constraints

* Must never be exposed to the client.
* Must never appear in logs.
* Requires strict server-side access control.

---

## 15.3 SyncCursor

### Purpose

Tracks incremental synchronization state.

### Core attributes

* `id`
* `integration_account_id`
* `resource_type`
* `cursor_value`
* `last_synced_at`
* `sync_status`
* `updated_at`

---

## 15.4 SyncJob

### Purpose

Tracks one synchronization execution.

### Core attributes

* `id`
* `integration_account_id`
* `resource_type`
* `status`
* `started_at`
* `completed_at`
* `records_detected`
* `records_processed`
* `records_failed`
* `error_summary`
* `correlation_id`

---

## 15.5 IngestionCandidate

### Business definition

A proposed object creation or update extracted from an external source.

### Core attributes

* `id`
* `owner_user_id`
* `integration_account_id`
* `source_record_type`
* `source_record_id`
* `candidate_type`
* `classification`
* `extracted_payload`
* `confidence`
* `status`
* `created_at`
* `expires_at`

### Privacy classification

Confidential or Restricted.

---

## 15.6 ApprovalRequest

### Business definition

A request for user authorization before a sensitive or consequential action.

### Core attributes

* `id`
* `owner_user_id`
* `approval_type`
* `status`
* `summary`
* `proposed_action`
* `payload_reference`
* `requested_at`
* `decided_at`
* `decision_reason`
* `expires_at`

### Examples

* Import email body.
* Change Application stage.
* Create Calendar event.
* Send email draft.
* Persist extracted Knowledge.

---

## 15.7 ExternalReference

### Purpose

Maps Career OS records to identifiers in external systems.

### Core attributes

* `id`
* `owner_user_id`
* `provider`
* `external_type`
* `external_id`
* `internal_object_id`
* `internal_record_type`
* `internal_record_id`
* `created_at`

---

# 16. Notification and Audit Entities

## 16.1 Notification

### Core attributes

* `id`
* `owner_user_id`
* `notification_type`
* `title`
* `message`
* `priority`
* `related_object_id`
* `read_at`
* `dismissed_at`
* `snoozed_until`
* `created_at`

---

## 16.2 AuditLog

### Business definition

A security-focused record of consequential actions.

### Core attributes

* `id`
* `owner_user_id`
* `actor_type`
* `actor_id`
* `action_type`
* `target_type`
* `target_id`
* `result`
* `ip_summary`
* `correlation_id`
* `metadata`
* `occurred_at`

### Privacy classification

Restricted.

### Examples

* Integration connected.
* Email sent.
* External Calendar changed.
* Sensitive data exported.
* Record permanently deleted.
* Permission changed.

---

## 16.3 BackgroundJob

### Purpose

Tracks asynchronous system work.

### Core attributes

* `id`
* `job_type`
* `status`
* `input_reference`
* `attempt_count`
* `scheduled_at`
* `started_at`
* `completed_at`
* `error_summary`
* `correlation_id`
* `created_at`

---

# 17. Entities Deferred Beyond the MVP

The following may be introduced later:

* Shared Workspace.
* Team Membership.
* Subscription.
* Billing Account.
* University Career Center.
* Shared Template.
* Public Profile.
* Graph Projection Job.
* Browser Capture.
* Market Position.
* Trade.
* Trading Strategy.
* Publication.
* Conference.
* Scholarship.
* Visa Status Instance.
* Custom Field Definition.
* User-Defined Relationship Type.

These are excluded from the initial schema unless an MVP requirement makes them necessary.

---

# 18. Canonical Ownership Matrix

| Information                       | Canonical Entity           |
| --------------------------------- | -------------------------- |
| Universal object identity         | ObjectRegistry             |
| Person identity                   | Person                     |
| Organization identity             | Organization               |
| Opportunity deadline              | Opportunity                |
| Application stage                 | Application                |
| Application stage history         | ApplicationStageHistory    |
| Project mission                   | Project                    |
| Task due time                     | Task                       |
| Calendar schedule                 | CalendarEvent or TimeBlock |
| Relationship edge                 | Relationship               |
| User-to-Person relationship state | ProfessionalRelationship   |
| Object timeline event             | Activity                   |
| Lifecycle change                  | LifecycleTransition        |
| Knowledge content                 | KnowledgeItem              |
| Evidence provenance               | Evidence                   |
| Resume identity                   | Document                   |
| Resume revision                   | DocumentVersion            |
| File storage metadata             | FileObject                 |
| AI recommendation                 | Recommendation             |
| AI score                          | Score                      |
| AI input trace                    | IntelligenceInput          |
| External provider identity        | ExternalReference          |
| Synchronization state             | SyncCursor                 |
| Sensitive action approval         | ApprovalRequest            |
| Consequential security event      | AuditLog                   |

---

# 19. Initial MVP Entity Set

The first production migration should prioritize:

1. User
2. UserProfile
3. ObjectRegistry
4. Relationship
5. Activity
6. LifecycleTransition
7. Tag
8. ObjectTag
9. Goal
10. Project
11. ProjectMilestone
12. Task
13. TaskObject
14. TimeBlock
15. Person
16. Organization
17. PersonOrganizationAffiliation
18. ProfessionalRelationship
19. Interaction
20. Opportunity
21. OpportunityRequirement
22. Application
23. ApplicationStageHistory
24. Assessment
25. Interview
26. Document
27. DocumentVersion
28. FileObject
29. KnowledgeItem
30. Evidence
31. Insight
32. Recommendation
33. Score
34. CareerRisk
35. DailyMission
36. DailyMissionItem
37. IntegrationAccount
38. IntegrationCredential
39. SyncCursor
40. SyncJob
41. IngestionCandidate
42. ApprovalRequest
43. EmailRecord
44. CalendarEvent
45. Notification
46. AuditLog
47. BackgroundJob

---

# 20. Open Data-Model Questions

1. Should World objects be globally shared or user-scoped in Version 1?
2. Should Object Registry use one global namespace across all tenants?
3. Which relationships require dedicated optimized tables?
4. Which supporting records also require Object Registry identity?
5. Should Tasks become registered objects?
6. Should Assessments and Interviews become first-class objects?
7. How should sensitive email content be encrypted?
8. How should immutable Activities be corrected?
9. How should AI-generated fields be separated from user-confirmed values?
10. Which entity fields require history beyond the Activity Ledger?
11. How should custom properties be modeled?
12. How should soft deletion interact with Relationships and Intelligence records?
13. Which data should be retained after an Integration Account is disconnected?
14. Which entities require hard-delete cascades?
15. How should shared public Evidence be deduplicated?

---

# 21. Acceptance Criteria

The Data Dictionary is ready for ERD design when:

* Every MVP capability maps to at least one entity.
* Each entity has one clear purpose.
* Canonical ownership is unambiguous.
* Personal, World, and Intelligence layers are distinguishable.
* Sensitive entities are identified.
* Object Registry participation is defined.
* Supporting records are separated from first-class objects.
* External synchronization state is modeled.
* Approval-gated actions are modeled.
* AI outputs and their inputs are traceable.
* No major concept is duplicated across multiple entities.

---

# 22. Next Documents

* `docs/04-database/02_ERD.md`
* `docs/04-database/03_DATABASE_SCHEMA.md`
* `docs/04-database/04_INDEXING_STRATEGY.md`
* `docs/04-database/05_RLS_POLICIES.md`
* `docs/04-database/06_MIGRATION_STRATEGY.md`
* `docs/04-database/07_NAMING_CONVENTIONS.md`

