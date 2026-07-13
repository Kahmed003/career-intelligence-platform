# Career OS Relationship Ontology

**Document ID:** DOM-004
**Version:** 1.0
**Status:** Draft
**Owner:** Ahmed Kazadi Kabuya
**Last Updated:** 2026-07-12

**Related Documents:**

* `docs/00-vision/MANIFESTO.md`
* `docs/01-product/PRD.md`
* `docs/02-domain/DOMAIN_MODEL.md`
* `docs/02-domain/GLOSSARY.md`
* `docs/02-domain/OBJECTS.md`
* `docs/02-domain/LIFECYCLES.md`

---

## Purpose

This document defines the canonical relationship types used throughout Career OS.

Objects describe what exists.

Relationships describe:

* How objects are connected.
* What those connections mean.
* How the graph changes over time.
* Which connections are user-entered, imported, or inferred.
* Which connections the AI may use for reasoning.

The relationship ontology supports:

* Knowledge-graph traversal.
* Search and discovery.
* AI recommendations.
* Opportunity matching.
* Relationship intelligence.
* Goal-impact analysis.
* Decision support.
* Analytics.
* Future multi-user collaboration.

---

# 1. Relationship Contract

Every relationship should support the following conceptual fields.

## Identity

* `id`
* `relationship_type`
* `source_object_type`
* `source_object_id`
* `target_object_type`
* `target_object_id`

## Ownership and origin

* `owner_user_id`
* `origin_type`

  * user_created
  * imported
  * system_generated
  * ai_inferred
* `created_by`
* `created_at`
* `updated_at`

## Time

* `valid_from`
* `valid_until`
* `ended_at`
* `is_current`

## Confidence and provenance

* `confidence`
* `verification_status`
* `evidence_ids`
* `source_summary`

## Optional metadata

* `role`
* `status`
* `strength`
* `priority`
* `notes`
* `metadata`

---

# 2. Relationship Rules

1. Every relationship must use one canonical relationship type.
2. Relationship direction must be explicit.
3. Inverse relationships may be derived where appropriate.
4. Historical relationships must not be overwritten by current relationships.
5. AI-inferred relationships must remain distinguishable from verified relationships.
6. Time-sensitive relationships should include validity dates.
7. Sensitive relationship metadata should default to private.
8. Ambiguous relationships should be flagged for confirmation.
9. Relationships must not be used to infer protected or highly sensitive personal attributes without explicit justification and consent.
10. New relationship types require glossary and ontology review.

---

# 3. Relationship Categories

Career OS groups relationships into the following domains:

1. Identity and ownership
2. People and networking
3. Organizations and institutions
4. Opportunities and applications
5. Projects and deliverables
6. Goals, assets, and growth
7. Skills and learning
8. Knowledge and evidence
9. Decisions and recommendations
10. Documents and versions
11. Tasks, time, and execution
12. Research and publications
13. Geography and immigration
14. Intelligence and analytics

---

# 4. Identity and Ownership Relationships

## OWNS

**Direction:** User → Personal Object

**Meaning:** The user owns the personal object.

**Examples:**

* Ahmed `OWNS` Goal
* Ahmed `OWNS` Project
* Ahmed `OWNS` Decision

**Multiplicity:** One user may own many objects.

**Constraints:**

* Required for Personal Layer objects.
* Does not apply to independent World objects.

---

## CREATED

**Direction:** User or System → Object

**Meaning:** Identifies who or what created the object.

---

## CREATED_FOR

**Direction:** Intelligence Object → User

**Meaning:** The intelligence output was generated specifically for the user.

---

## MANAGES

**Direction:** User → Object

**Meaning:** The user actively manages the object without owning the underlying real-world entity.

**Example:**

* Ahmed `MANAGES` Organization record for ASML.

---

## IMPORTED_FROM

**Direction:** Object → External Source or Integration

**Meaning:** The object originated from an external system.

**Examples:**

* Email Record `IMPORTED_FROM` Gmail
* Calendar Event `IMPORTED_FROM` Google Calendar

---

## REPRESENTS

**Direction:** Internal Object → External Entity or Record

**Meaning:** The internal object represents something outside Career OS.

---

# 5. People and Networking Relationships

## KNOWS

**Direction:** Person → Person

**Meaning:** One person has a professional or personal connection to another.

**Use carefully:** Prefer a more specific relationship when known.

---

## CONNECTED_TO

**Direction:** Person → Person

**Meaning:** A generic verified professional connection exists.

**Constraint:** Used only when no more specific relationship is available.

---

## MET

**Direction:** User → Person

**Meaning:** The user has met the person.

**Metadata:**

* Date
* Location
* Event
* Context

---

## CONTACTED

**Direction:** User → Person

**Meaning:** The user initiated communication with the person.

---

## CONTACTED_BY

**Direction:** User ← Person

**Meaning:** The person initiated communication with the user.

---

## COMMUNICATED_WITH

**Direction:** User ↔ Person

**Meaning:** A meaningful communication exchange occurred.

---

## MENTORED_BY

**Direction:** User → Person

**Inverse:** MENTORS

**Meaning:** The user receives mentorship from the person.

---

## MENTORS

**Direction:** Person → User

**Inverse:** MENTORED_BY

---

## ADVISED_BY

**Direction:** User → Person

**Meaning:** The person provides formal or informal advice.

---

## SUPERVISED_BY

**Direction:** User → Person

**Meaning:** The person formally supervises the user's work, research, or study.

---

## COLLABORATED_WITH

**Direction:** Person ↔ Person

**Meaning:** The people worked together on a shared activity or output.

---

## INTRODUCED_BY

**Direction:** User or Person → Person

**Meaning:** A connection was enabled by another person.

**Example:**

* Ahmed `INTRODUCED_BY` Mentor to Recruiter.

A more explicit implementation may use an Introduction supporting record.

---

## INTRODUCED_TO

**Direction:** Person → Person

**Meaning:** One person introduced another to a third person.

---

## REFERRED_BY

**Direction:** User → Person

**Meaning:** The person referred the user to an Opportunity or Organization.

---

## REFERRED_TO

**Direction:** Person → Opportunity or Organization

**Meaning:** The person referred the user toward the target.

---

## RECOMMENDED_BY

**Direction:** User or Object → Person

**Meaning:** The person gave a professional or academic recommendation.

---

## RECOMMENDS

**Direction:** Person → User, Opportunity, Document, or Resource

**Meaning:** The person recommended the target.

---

## RECRUITED_BY

**Direction:** User → Person

**Meaning:** The person participated in recruiting the user.

---

## INTERVIEWED_BY

**Direction:** User → Person

**Meaning:** The person interviewed the user.

---

## WORKED_WITH

**Direction:** Person ↔ Person

**Meaning:** The people worked together professionally.

---

## STUDIED_WITH

**Direction:** Person ↔ Person

**Meaning:** The people studied in the same academic context.

---

## CO_AUTHORED_WITH

**Direction:** Person ↔ Person

**Meaning:** The people jointly authored a publication or document.

---

## FOLLOWS_WORK_OF

**Direction:** User → Person

**Meaning:** The user intentionally follows the person's work or research.

---

## INTERESTED_IN_CONTACTING

**Direction:** User → Person

**Meaning:** The user may want to establish a relationship with the person.

---

## RELATIONSHIP_WITH

**Direction:** User → Person

**Meaning:** Links the user and Person to the structured Relationship supporting record.

---

# 6. Organization and Institution Relationships

## WORKS_FOR

**Direction:** Person → Organization

**Inverse:** EMPLOYS

---

## EMPLOYS

**Direction:** Organization → Person

---

## WORKED_FOR

**Direction:** Person → Organization

**Meaning:** Historical employment relationship.

---

## STUDIES_AT

**Direction:** Person → Organization

**Meaning:** Current academic enrollment.

---

## STUDIED_AT

**Direction:** Person → Organization

**Meaning:** Historical academic enrollment.

---

## TEACHES_AT

**Direction:** Person → Organization

---

## RESEARCHES_AT

**Direction:** Person → Organization

---

## AFFILIATED_WITH

**Direction:** Person or Organization → Organization

**Meaning:** General institutional affiliation.

---

## MEMBER_OF

**Direction:** Person → Organization

---

## FOUNDED

**Direction:** Person → Organization

---

## CO_FOUNDED

**Direction:** Person → Organization

---

## LEADS

**Direction:** Person → Organization, Team, Laboratory, or Project

---

## MANAGES_TEAM_AT

**Direction:** Person → Organization

---

## PARTNER_OF

**Direction:** Organization ↔ Organization

---

## COLLABORATES_WITH

**Direction:** Organization ↔ Organization

---

## FUNDED_BY

**Direction:** Organization, Project, Opportunity, or Research → Organization

---

## FUNDS

**Direction:** Organization → Project, Opportunity, Research, or Person

---

## SPONSORED_BY

**Direction:** Event, Project, Opportunity, or Program → Organization

---

## PARENT_OF

**Direction:** Organization → Organization

**Inverse:** SUBSIDIARY_OF

---

## SUBSIDIARY_OF

**Direction:** Organization → Organization

---

## DIVISION_OF

**Direction:** Organization → Organization

---

## LAB_WITHIN

**Direction:** Organization → Organization

**Meaning:** A Laboratory is housed within a University or Research Institute.

---

## HOSTS

**Direction:** Organization → Event, Program, Opportunity, or Project

---

## LOCATED_IN

**Direction:** Organization → Location or Country

---

## OPERATES_IN

**Direction:** Organization → Country or Region

---

## ACTIVE_IN_INDUSTRY

**Direction:** Organization → Industry

---

## SPECIALIZES_IN

**Direction:** Organization or Person → Technology, Skill, Research Area, or Industry

---

# 7. Opportunity and Application Relationships

## OFFERS

**Direction:** Organization → Opportunity

---

## HOSTED_BY

**Direction:** Opportunity → Organization

---

## ASSOCIATED_WITH

**Direction:** Opportunity → Organization, Person, Program, or Event

---

## PURSUED_THROUGH

**Direction:** Application → Opportunity

**Meaning:** The Application represents the user's pursuit of the Opportunity.

---

## APPLIED_TO

**Direction:** User → Opportunity

**Preferred implementation:** Derived from Application.

---

## TARGETS

**Direction:** Application → Opportunity

---

## SUBMITTED_TO

**Direction:** Application → Organization

---

## SOURCED_FROM

**Direction:** Opportunity → Source, Person, Platform, or Organization

---

## DISCOVERED_THROUGH

**Direction:** Opportunity → Person, Email, Website, Event, or Platform

---

## REFERRED_FOR

**Direction:** Person → Opportunity

---

## REQUIRES

**Direction:** Opportunity → Skill, Document, Qualification, or Action

---

## PREFERS

**Direction:** Opportunity → Skill, Experience, or Qualification

---

## PROVIDES

**Direction:** Opportunity → Asset, Skill, Funding, Experience, or Benefit

---

## SUPPORTS_GOAL

**Direction:** Opportunity → Goal

---

## ALIGNS_WITH

**Direction:** Opportunity → Goal, Interest, Skill, Asset, or Career Path

---

## CONFLICTS_WITH

**Direction:** Opportunity → Goal, Constraint, Schedule, or Decision

---

## LOCATED_IN

**Direction:** Opportunity → Country, Region, or City

---

## REQUIRES_VISA_PATHWAY

**Direction:** Opportunity → Visa Pathway

---

## SUPPORTS_VISA_PATHWAY

**Direction:** Opportunity or Organization → Visa Pathway

---

## REQUIRES_DOCUMENT

**Direction:** Opportunity or Application → Document Type

---

## USES_DOCUMENT

**Direction:** Application → Document or Document Version

---

## HAS_ASSESSMENT

**Direction:** Application → Assessment supporting record

---

## HAS_INTERVIEW

**Direction:** Application → Interview or Calendar Event

---

## RESULTED_IN

**Direction:** Application → Outcome

---

## COMPETES_WITH

**Direction:** Opportunity ↔ Opportunity

**Meaning:** The Opportunities compete for the same time, commitment, or decision.

---

## SIMILAR_TO

**Direction:** Opportunity ↔ Opportunity

---

# 8. Project and Deliverable Relationships

## SUPPORTS

**Direction:** Project → Goal

---

## BUILDS

**Direction:** Project → Asset

---

## DEVELOPS

**Direction:** Project → Skill

---

## PRODUCES

**Direction:** Project → Deliverable or Document

---

## CONTAINS_TASK

**Direction:** Project → Task

---

## CONTAINS_MILESTONE

**Direction:** Project → Milestone

---

## DEPENDS_ON

**Direction:** Project, Task, or Milestone → Project, Task, Skill, Document, or Resource

---

## BLOCKED_BY

**Direction:** Project or Task → Risk, Task, Decision, Person, or Resource

---

## CONTRIBUTED_TO_BY

**Direction:** Project → Person

**Inverse:** CONTRIBUTES_TO

---

## CONTRIBUTES_TO

**Direction:** Person → Project

---

## LED_BY

**Direction:** Project → Person

---

## COLLABORATION_WITH

**Direction:** Project → Person or Organization

---

## USES

**Direction:** Project → Skill, Technology, Document, Dataset, or Tool

---

## BASED_ON

**Direction:** Project → Knowledge Item, Evidence Source, Research Paper, or Prior Project

---

## CONTINUES

**Direction:** Project → Project

---

## DERIVED_FROM

**Direction:** Project or Deliverable → Project, Knowledge Item, Document, or Evidence

---

## FEATURED_IN

**Direction:** Project → Document, Resume, Portfolio, or Application

---

## DEMONSTRATES

**Direction:** Project → Skill, Asset, or Achievement

---

## ARCHIVED_AS

**Direction:** Project → Document, Repository, or Portfolio Artifact

---

# 9. Goal, Asset, and Growth Relationships

## SUPPORTS

**Direction:** Project, Opportunity, Task, Skill, Asset, or Relationship → Goal

---

## ADVANCES

**Direction:** Action, Task, Project, or Opportunity → Goal

---

## REQUIRED_FOR

**Direction:** Asset or Skill → Goal

---

## DEPENDS_ON

**Direction:** Goal → Asset, Skill, Decision, Opportunity, or Milestone

---

## MEASURED_BY

**Direction:** Goal or Asset → Metric, Milestone, Evidence, or Score

---

## CONFLICTS_WITH

**Direction:** Goal ↔ Goal

---

## COMPLEMENTS

**Direction:** Goal ↔ Goal

---

## PRIORITIZED_OVER

**Direction:** Goal → Goal

**Meaning:** The user explicitly prioritizes one Goal over another in a context.

---

## BUILT_BY

**Direction:** Asset → Project, Opportunity, Skill Practice, Interaction, or Achievement

---

## SUPPORTED_BY_EVIDENCE

**Direction:** Asset or Goal Progress → Evidence Source

---

## CONTAINS_SKILL

**Direction:** Asset → Skill

---

## CONTRIBUTES_TO_CAREER_CAPITAL

**Direction:** Asset, Project, Opportunity, or Relationship → Career Capital

---

## HAS_MILESTONE

**Direction:** Goal → Milestone

---

## AT_RISK_FROM

**Direction:** Goal → Career Risk, Constraint, Decision, or Deadline

---

## PROGRESS_EVALUATED_BY

**Direction:** Goal → Score or Insight

---

# 10. Skills and Learning Relationships

## HAS_SKILL

**Direction:** User or Person → Skill

---

## CLAIMS_PROFICIENCY_IN

**Direction:** User or Person → Skill

---

## DEMONSTRATED_BY

**Direction:** Skill → Evidence, Project, Document, or Achievement

---

## REQUIRED_BY

**Direction:** Skill → Opportunity, Project, Goal, or Role

---

## DEVELOPED_THROUGH

**Direction:** Skill → Project, Course, Opportunity, Task, or Practice Session

---

## PREREQUISITE_FOR

**Direction:** Skill → Skill, Project, Opportunity, or Goal

---

## SUBSKILL_OF

**Direction:** Skill → Skill

**Inverse:** HAS_SUBSKILL

---

## RELATED_TO

**Direction:** Skill ↔ Skill

---

## APPLIED_IN

**Direction:** Skill → Project, Task, Research, or Opportunity

---

## ASSESSED_BY

**Direction:** Skill → Assessment, Interview, Evidence, or Score

---

## TARGET_LEVEL_FOR

**Direction:** Skill Proficiency Record → Goal or Opportunity

---

## GAP_FOR

**Direction:** Skill Gap → Opportunity, Goal, Project, or Role

---

## LEARNING_RESOURCE_FOR

**Direction:** Knowledge Item, Document, Course, or Evidence Source → Skill

---

# 11. Knowledge and Evidence Relationships

## DERIVED_FROM

**Direction:** Knowledge Item → Evidence Source, Experience, Interaction, or Knowledge Item

---

## SUPPORTED_BY

**Direction:** Knowledge Item, Insight, Recommendation, or Decision → Evidence Source

---

## CONTRADICTED_BY

**Direction:** Knowledge Item, Insight, or Claim → Evidence Source or Knowledge Item

---

## CONFIRMED_BY

**Direction:** Knowledge Item or Insight → Evidence Source

---

## SUMMARIZES

**Direction:** Knowledge Item → Evidence Source, Document, Meeting, Paper, or Email Thread

---

## ABOUT

**Direction:** Knowledge Item, Evidence, or Document → Any relevant Object

---

## REFERENCES

**Direction:** Knowledge Item or Document → Object, Evidence, or External Source

---

## CITES

**Direction:** Knowledge Item, Document, or Decision → Evidence Source

---

## RELATED_TO

**Direction:** Knowledge Item ↔ Knowledge Item or other Object

---

## EXTENDS

**Direction:** Knowledge Item → Knowledge Item

---

## REFINES

**Direction:** Knowledge Item → Knowledge Item or Insight

---

## REPLACES

**Direction:** Knowledge Item or Version → Knowledge Item or Version

---

## CONVERTED_FROM

**Direction:** Knowledge Item → Note, Email, Meeting Record, or Raw Input

---

## EXTRACTED_FROM

**Direction:** Evidence, Knowledge, or Structured Record → Document, Email, Website, or File

---

## HAS_PROVENANCE

**Direction:** Object or Relationship → Evidence Source or External Source

---

## HAS_CONFIDENCE_BASIS

**Direction:** Insight, Score, or Recommendation → Evidence Source or Knowledge Item

---

# 12. Decision and Recommendation Relationships

## CONSIDERS

**Direction:** Decision → Option, Opportunity, Goal, Person, Organization, or Project

---

## HAS_OPTION

**Direction:** Decision → Decision Option

---

## EVALUATED_BY

**Direction:** Decision Option → Criterion

---

## SUPPORTED_BY

**Direction:** Decision or Option → Evidence or Knowledge

---

## OPPOSED_BY

**Direction:** Decision Option → Evidence, Risk, Constraint, or Goal

---

## AFFECTS

**Direction:** Decision → Goal, Project, Application, Relationship, or Asset

---

## RESULTED_IN

**Direction:** Decision → Outcome, Project, Application, or Action

---

## RECOMMENDED_BY

**Direction:** Decision or Action → Recommendation

---

## RECOMMENDS

**Direction:** Recommendation → Action, Opportunity, Decision Option, Project, or Task

---

## BASED_ON

**Direction:** Recommendation, Score, or Insight → Evidence, Knowledge, Goal, or Relationship

---

## SUPPORTS_DECISION

**Direction:** Insight or Knowledge → Decision

---

## IDENTIFIES_TRADEOFF

**Direction:** Insight → Decision, Goal, or Options

---

## IDENTIFIES_RISK

**Direction:** Insight or Recommendation → Career Risk

---

## ALTERNATIVE_TO

**Direction:** Decision Option, Opportunity, Project, or Action ↔ Another option

---

## ACCEPTED_BY

**Direction:** Recommendation → User

---

## REJECTED_BY

**Direction:** Recommendation → User

---

## LED_TO_ACTION

**Direction:** Recommendation or Insight → Task, Decision, Application, or Event

---

## OUTCOME_OF

**Direction:** Outcome → Decision or Recommendation

---

# 13. Document and Version Relationships

## HAS_VERSION

**Direction:** Document → Document Version

---

## VERSION_OF

**Direction:** Document Version → Document

---

## SUPERSEDES

**Direction:** Document Version → Document Version

---

## DERIVED_FROM

**Direction:** Document or Version → Document, Knowledge Item, Evidence, or Template

---

## CREATED_FOR

**Direction:** Document → Opportunity, Application, Project, Goal, or Organization

---

## SUBMITTED_WITH

**Direction:** Document Version → Application

---

## USED_IN

**Direction:** Document or Version → Application, Project, Interview, or Decision

---

## ATTACHED_TO

**Direction:** Attachment → Object or Supporting Record

---

## REFERENCES_OBJECT

**Direction:** Document → Person, Organization, Project, Skill, or Evidence

---

## DEMONSTRATES

**Direction:** Document → Skill, Asset, Experience, or Achievement

---

## REVIEWED_BY

**Direction:** Document → Person or AI system

---

## GENERATED_FROM

**Direction:** Document Version → Template, Prior Version, Knowledge, or AI Draft

---

# 14. Task, Time, and Execution Relationships

## SUPPORTS

**Direction:** Task → Goal, Project, Application, Decision, Relationship, or Opportunity

---

## SCHEDULED_AS

**Direction:** Task → Time Block

---

## REPRESENTED_BY

**Direction:** Time Block → Calendar Event

---

## PREPARES_FOR

**Direction:** Task or Time Block → Interview, Event, Application, Meeting, or Decision

---

## DUE_FOR

**Direction:** Task → Object

---

## ASSIGNED_TO

**Direction:** Task → User or Person

---

## BLOCKED_BY

**Direction:** Task → Task, Decision, Document, Person, or Event

---

## DEPENDS_ON

**Direction:** Task → Task or Object

---

## FOLLOWS

**Direction:** Task or Event → Task or Event

---

## PRECEDES

**Direction:** Task or Event → Task or Event

---

## COMPLETED_DURING

**Direction:** Task → Time Block or Calendar Event

---

## GENERATED_FROM

**Direction:** Task → Email, Recommendation, Opportunity, Decision, or Risk

---

## TRIGGERS

**Direction:** Activity, Deadline, or Status Change → Reminder, Notification, Task, or Recommendation

---

## REMINDS_ABOUT

**Direction:** Reminder → Task, Event, Opportunity, Relationship, or Goal

---

## NOTIFIES_ABOUT

**Direction:** Notification → Object, Risk, Event, or Recommendation

---

## CONFLICTS_WITH

**Direction:** Time Block or Calendar Event ↔ Another Time Block or Event

---

# 15. Research and Publication Relationships

## AUTHORED

**Direction:** Person → Document, Publication, or Research Paper

---

## CO_AUTHORED

**Direction:** Person → Publication

---

## PUBLISHED_BY

**Direction:** Publication or Paper → Organization, Journal, or Conference

---

## PRESENTED_AT

**Direction:** Research, Project, Paper, or Person → Conference or Event

---

## CITES

**Direction:** Publication or Knowledge Item → Publication or Evidence Source

---

## BUILDS_ON

**Direction:** Research, Publication, or Project → Publication, Knowledge, or Evidence

---

## REPLICATES

**Direction:** Research or Project → Research, Publication, or Experiment

---

## CONTRADICTS

**Direction:** Research or Publication → Publication, Knowledge, or Claim

---

## SUPPORTS_FINDING

**Direction:** Evidence or Research → Knowledge Item or Claim

---

## CONDUCTED_AT

**Direction:** Research or Project → Organization or Laboratory

---

## SUPERVISED_BY

**Direction:** Research or Project → Person

---

## FUNDED_BY

**Direction:** Research or Publication → Organization, Fellowship, or Grant

---

## USES_METHOD

**Direction:** Research or Project → Skill, Technology, or Method

---

## STUDIES_TOPIC

**Direction:** Research, Paper, or Person → Topic, Technology, Industry, or Skill

---

## RELATED_TO_RESEARCH_INTEREST

**Direction:** Person, Paper, Project, or Opportunity → User Research Interest

---

# 16. Geography and Immigration Relationships

## LOCATED_IN

**Direction:** Person, Organization, Opportunity, or Event → Location or Country

---

## CITIZEN_OF

**Direction:** Person → Country

**Sensitive:** Strict privacy controls required.

---

## RESIDES_IN

**Direction:** Person → Country or Location

---

## ELIGIBLE_FOR

**Direction:** User or Person → Visa Pathway, Opportunity, or Program

**Constraint:** Must distinguish verified eligibility from estimated eligibility.

---

## MAY_BE_ELIGIBLE_FOR

**Direction:** User → Visa Pathway or Opportunity

**Meaning:** Preliminary, unverified inference.

---

## REQUIRES

**Direction:** Opportunity, Country, or Employment Route → Visa Pathway

---

## ENABLES

**Direction:** Visa Pathway → Employment, Study, Residence, or Opportunity Type

---

## TRANSITIONS_TO

**Direction:** Visa Pathway → Visa Pathway

---

## VALID_IN

**Direction:** Visa Pathway → Country

---

## GOVERNED_BY

**Direction:** Visa Pathway → Authority or Official Evidence

---

## VERIFIED_BY

**Direction:** Visa Pathway Rule → Evidence Source

---

## EXPIRES_ON

**Direction:** Visa Status or Pathway Record → Date or Deadline

---

## CONSTRAINS

**Direction:** Visa Pathway or Rule → Opportunity, Goal, Location, or Timeline

---

# 17. Intelligence and Analytics Relationships

## GENERATED_FROM

**Direction:** Insight, Score, Recommendation, Risk, Daily Mission, or Weekly Strategy → Input Objects

---

## EXPLAINS

**Direction:** Insight → Score, Recommendation, Risk, Pattern, or Change

---

## EVALUATES

**Direction:** Score or Insight → Object, Relationship, Goal, or Decision

---

## SCORES

**Direction:** Score → Opportunity, Project, Relationship, Goal, Skill Fit, or Readiness

---

## PRIORITIZES

**Direction:** Daily Mission, Weekly Strategy, or Recommendation → Task, Goal, Project, or Opportunity

---

## DETECTS

**Direction:** Insight or Risk → Pattern, Gap, Deadline, Conflict, or Opportunity

---

## WARNS_ABOUT

**Direction:** Career Risk or Notification → Goal, Application, Visa Pathway, Relationship, or Deadline

---

## SUGGESTS

**Direction:** Recommendation → Action, Task, Opportunity, Person, Project, or Decision

---

## EXPIRES_WHEN

**Direction:** Intelligence Object → Condition, Date, or Input Change

---

## SUPERSEDES

**Direction:** Intelligence Object → Prior Intelligence Object

---

## CONFIRMED_BY_USER

**Direction:** Intelligence Object → User Feedback

---

## CORRECTED_BY_USER

**Direction:** Intelligence Object → User Feedback or Knowledge

---

## CONTRIBUTES_TO

**Direction:** Insight, Score, or Recommendation → Daily Mission, Weekly Strategy, or Decision

---

# 18. Relationship Multiplicity Guidelines

## One-to-one

Use when only one current relationship is valid.

Examples:

* Application `TARGETS` one Opportunity.
* Document Version `VERSION_OF` one Document.

## One-to-many

Examples:

* Organization `OFFERS` many Opportunities.
* Goal `HAS_MILESTONE` many Milestones.
* Project `CONTAINS_TASK` many Tasks.

## Many-to-many

Examples:

* Projects `DEVELOP` many Skills.
* Skills are `DEVELOPED_THROUGH` many Projects.
* Knowledge Items may be `ABOUT` many objects.
* People may `COLLABORATE_WITH` many People.

## Temporal multiplicity

Historical and current relationships must coexist when appropriate.

Example:

A Person may have:

* Worked for Organization A from 2021–2024.
* Works for Organization B from 2024 onward.

---

# 19. Inverse Relationship Policy

Inverse relationships should be defined when they improve readability and graph traversal.

Examples:

| Forward      | Inverse       |
| ------------ | ------------- |
| WORKS_FOR    | EMPLOYS       |
| MENTORED_BY  | MENTORS       |
| PARENT_OF    | SUBSIDIARY_OF |
| HAS_VERSION  | VERSION_OF    |
| HAS_SUBSKILL | SUBSKILL_OF   |
| OFFERS       | HOSTED_BY     |
| CREATED_FOR  | RECEIVES      |

Not every relationship requires a stored inverse edge. The database implementation may derive inverses dynamically.

---

# 20. Relationship Strength

Some relationships may include a strength or weight.

Examples:

* Relationship relevance.
* Goal contribution.
* Skill importance.
* Evidence support.
* Opportunity alignment.

Strength values must:

1. Be contextual.
2. Preserve their calculation method.
3. Avoid false precision.
4. Include confidence where inferred.
5. Be recalculated when underlying evidence changes.

---

# 21. Relationship Provenance

Every relationship should identify how it became known.

Possible origins:

* User entry.
* Gmail import.
* Calendar import.
* Uploaded document.
* Official webpage.
* Research paper.
* Application record.
* AI inference.
* System rule.

AI-inferred relationships should include:

* Confidence.
* Supporting Evidence.
* Model version.
* Inference timestamp.
* User confirmation state.

---

# 22. Relationship Validation

Before creating or modifying a relationship, Career OS should validate:

1. Both objects exist.
2. The relationship type supports the object types.
3. Direction is correct.
4. Duplicate active relationships are avoided.
5. Required metadata is present.
6. Dates are logically consistent.
7. Provenance is recorded.
8. AI-inferred relationships remain reviewable.
9. Sensitive relationships receive appropriate privacy controls.

---

# 23. Relationship Naming Standard

Relationship names should:

* Use uppercase snake case in technical contexts.
* Use active verbs.
* Be specific.
* Preserve direction.
* Avoid ambiguous terms where a more precise type exists.

Preferred:

```text
WORKS_FOR
MENTORED_BY
SUPPORTS_GOAL
REQUIRES_SKILL
DERIVED_FROM
```

Avoid:

```text
HAS
LINKED_TO
ASSOCIATED
RELATED
```

Generic relationships may be used only when the precise meaning is genuinely unknown.

---

# 24. Extending the Ontology

A new relationship type may be introduced when:

1. Existing relationships cannot accurately represent the meaning.
2. The relationship improves AI reasoning, search, workflow, or analytics.
3. Its direction and inverse behavior are clear.
4. Its valid source and target object types are defined.
5. It does not duplicate an existing relationship.

Each new relationship type should document:

* Name.
* Category.
* Definition.
* Valid source types.
* Valid target types.
* Direction.
* Multiplicity.
* Inverse relationship.
* Required metadata.
* Example.
* Validation constraints.

---

# 25. Initial Graph Query Requirements

The relationship ontology must support questions such as:

* Which People have mentored me?
* Which Opportunities came through my network?
* Which Projects most strongly support my PhD Goal?
* Which Skills repeatedly appear in my highest-priority Opportunities?
* Which Documents were used in successful Applications?
* Which People are connected to Organizations I want to join?
* Which Knowledge Items support an active Decision?
* Which Assets have received the least investment this quarter?
* Which Relationships are becoming dormant?
* Which Opportunities align with both my research and immigration constraints?
* Which Projects demonstrate a particular Skill?
* Which Evidence supports a Recommendation?
* Which Decisions materially changed my Career Trajectory?
* Which People could introduce me to a target Organization?
* Which Tasks should be prioritized based on deadlines and Goal impact?

---

# 26. Open Questions

The following issues will be resolved in later architecture and database documents:

1. Whether relationships use one generic edge table or domain-specific join tables.
2. Whether highly common relationships receive dedicated relational tables.
3. Whether graph traversal occurs in PostgreSQL or through a dedicated graph system.
4. How inferred relationship confidence is recalculated.
5. How relationship histories are versioned.
6. Which relationships are globally shared versus user-specific.
7. How external identity resolution works.
8. How user-defined custom relationship types are governed.
9. How sensitive relationships are encrypted or access-controlled.
10. How ontology migrations are handled when a relationship type changes.

---

# Next Documents

* `docs/02-domain/LIFECYCLES.md`
* `docs/03-architecture/ARCHITECTURE.md`
* `docs/04-database/ERD.md`
* `docs/06-ai/AI_ARCHITECTURE.md`
