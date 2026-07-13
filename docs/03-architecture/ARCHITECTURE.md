# Career OS System Architecture Specification

**Document ID:** ARC-001
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
* `docs/02-domain/RELATIONSHIPS.md`
* `docs/02-domain/LIFECYCLES.md`
* `docs/09-decisions/ADR-0001-postgresql-graph-compatible-model.md`
* `docs/09-decisions/ADR-0002-modular-monolith.md`
* `docs/09-decisions/ADR-0003-mission-control-ai-interface.md`
* `docs/09-decisions/ADR-0004-controlled-intelligence-ingestion.md`

---

# 1. Purpose

This document defines the system architecture for Career OS.

It translates the product vision and domain model into an implementable technical structure covering:

* Frontend architecture.
* Backend architecture.
* Domain modules.
* PostgreSQL-based knowledge graph.
* AI reasoning and recommendation services.
* Google integrations.
* Controlled ingestion.
* Authentication and authorization.
* Background processing.
* Search.
* File storage.
* Notifications.
* Security.
* Observability.
* Deployment.
* Testing.
* Scalability.

This document defines architecture rather than final database tables, endpoint payloads, component designs, or sprint tasks. Those will be specified in downstream documents.

---

# 2. Architectural Objectives

Career OS must:

1. Answer **“What should I do today?”**
2. Keep professional information organized and connected.
3. Support tasks, notes, calendars, emails, documents, and applications.
4. Identify relevant opportunities and risks.
5. Support better career decisions.
6. Preserve explainability for AI-generated outputs.
7. Protect user privacy.
8. Require approval before consequential external actions.
9. Support gradual expansion without premature distributed-system complexity.
10. Remain maintainable by a small development team during the MVP phase.

---

# 3. Architecture Principles

## 3.1 AI-native, not AI-only

AI is embedded throughout the platform, but structured workflows remain primary.

Mission Control, applications, projects, contacts, documents, and tasks must remain useful even when AI services are unavailable.

## 3.2 Domain-first design

Code organization follows Career OS domain concepts rather than database tables or screen layouts.

Primary modules include:

* Goals
* Projects
* Opportunities
* Applications
* People
* Organizations
* Relationships
* Knowledge
* Documents
* Tasks
* Decisions
* Intelligence
* Integrations

## 3.3 Modular monolith first

Career OS begins as one deployable application with strong internal module boundaries.

Services may be extracted only when justified by:

* Independent scaling needs.
* Security isolation.
* Deployment frequency.
* Long-running workloads.
* Operational reliability.
* Team ownership.

## 3.4 PostgreSQL as transactional system of record

PostgreSQL stores canonical objects, relationships, lifecycle history, permissions, and integration state.

Graph semantics are represented explicitly through typed relationships.

## 3.5 Controlled ingestion

External systems do not automatically populate the user’s graph without filtering and approval.

The ingestion pipeline separates:

* Detection
* Classification
* Extraction
* Recommendation
* User approval
* Persistence

## 3.6 User agency

Career OS may recommend, classify, extract, draft, and schedule proposals.

It may not execute consequential external actions without explicit authorization.

## 3.7 Explainability

Every system-generated Recommendation, Insight, Score, or Career Risk must preserve:

* Supporting Evidence.
* Input objects.
* Reasoning summary.
* Confidence.
* Assumptions.
* Model version.
* Generation timestamp.

## 3.8 Privacy by default

The platform should collect the minimum data necessary for the requested capability.

Raw email bodies, private documents, sensitive identity information, and immigration records require heightened protection.

---

# 4. High-Level System Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                         User                                │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Web Application                          │
│                                                             │
│  Mission Control │ Objects │ Search │ Command Palette       │
│  Applications    │ People  │ Tasks  │ Embedded AI           │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Application Layer                          │
│                                                             │
│  Commands │ Queries │ Workflows │ Approval Gates            │
└───────────────┬───────────────────┬─────────────────────────┘
                │                   │
                ▼                   ▼
┌──────────────────────────┐   ┌──────────────────────────────┐
│      Domain Layer        │   │     Intelligence Layer       │
│                          │   │                              │
│ Goals                    │   │ Context Assembly             │
│ Projects                 │   │ Classification               │
│ Opportunities            │   │ Insights                     │
│ Applications             │   │ Recommendations              │
│ Relationships            │   │ Scores and Risks             │
│ Knowledge                │   │ Daily Mission                │
│ Decisions                │   │ Explainability               │
└───────────────┬──────────┘   └──────────────┬───────────────┘
                │                             │
                └──────────────┬──────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                  Infrastructure Layer                       │
│                                                             │
│ PostgreSQL │ Storage │ Queues │ Search │ Audit │ Cache       │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Integration Layer                          │
│                                                             │
│ Gmail │ Calendar │ Drive │ Sheets │ Contacts │ GitHub        │
└─────────────────────────────────────────────────────────────┘
```

---

# 5. Technology Stack

## 5.1 Web application

* Next.js
* React
* TypeScript
* App Router
* Server Components where appropriate
* Client Components only where interactivity requires them
* Tailwind CSS
* Accessible component primitives
* Schema validation with Zod or an equivalent typed validation library

## 5.2 Database and backend services

* PostgreSQL
* Supabase-managed database
* Supabase Auth
* Row-Level Security
* Supabase Storage
* Database migrations under version control
* Generated TypeScript database types

## 5.3 Deployment

* Vercel for the web application
* Supabase for database, authentication, and storage
* Scheduled jobs through a managed scheduler or Supabase-compatible mechanism
* Optional worker service when long-running background processing becomes necessary

## 5.4 AI providers

The AI layer must use a provider abstraction.

No domain module should depend directly on one model vendor.

The abstraction should support:

* Structured generation.
* Tool use.
* Embeddings.
* Classification.
* Summarization.
* Context limits.
* Cost tracking.
* Model version tracking.

## 5.5 External integrations

Initial integrations:

* Google OAuth
* Gmail
* Google Calendar
* Google Drive
* Google Sheets
* Google Contacts
* GitHub

Future integrations may include:

* LinkedIn-compatible manual imports
* University career portals
* Job boards
* Research databases
* Market-data systems
* Slack
* Browser extension capture

---

# 6. Repository Architecture

Career OS uses a monorepo.

```text
career-intelligence-platform/
│
├── apps/
│   └── web/
│       ├── app/
│       ├── components/
│       ├── features/
│       ├── lib/
│       ├── styles/
│       └── tests/
│
├── packages/
│   ├── domain/
│   ├── database/
│   ├── ui/
│   ├── ai/
│   ├── integrations/
│   ├── search/
│   ├── observability/
│   ├── config/
│   └── shared/
│
├── supabase/
│   ├── migrations/
│   ├── functions/
│   ├── seed/
│   └── config/
│
├── docs/
├── scripts/
├── tests/
├── .github/
├── package.json
└── turbo.json
```

A monorepo orchestrator may be used when it provides meaningful value for task caching and package coordination.

---

# 7. Module Boundaries

Each domain module should own:

* Domain types.
* Validation rules.
* Commands.
* Queries.
* Policies.
* Lifecycle behavior.
* Event definitions.
* Tests.

## 7.1 Goals module

Responsibilities:

* Goal creation.
* Goal milestones.
* Progress calculation.
* Goal risks.
* Goal relationships.
* Goal-related recommendations.

## 7.2 Projects module

Responsibilities:

* Project lifecycle.
* Milestones.
* Deliverables.
* Project health.
* Project-to-Skill and Project-to-Asset relationships.
* Project Tasks.

## 7.3 Opportunities module

Responsibilities:

* Opportunity capture.
* Eligibility.
* Deadlines.
* Source provenance.
* Opportunity matching.
* Opportunity lifecycle.
* Expiration.

## 7.4 Applications module

Responsibilities:

* Application stage management.
* Submitted materials.
* Assessments.
* Interviews.
* Outcomes.
* Stage history.
* Email linkage.

## 7.5 People and relationships module

Responsibilities:

* Person identity.
* Deduplication.
* Organization affiliations.
* Relationship history.
* Interactions.
* Follow-ups.
* Relationship intelligence.

## 7.6 Knowledge module

Responsibilities:

* Knowledge Items.
* Evidence.
* Citations.
* Provenance.
* Contradictions.
* Version history.
* Knowledge retrieval.

## 7.7 Documents module

Responsibilities:

* Document identity.
* Versions.
* File storage.
* Resume variants.
* Application usage.
* AI review.
* Export.

## 7.8 Tasks and execution module

Responsibilities:

* Tasks.
* Dependencies.
* Time Blocks.
* Reminders.
* Daily execution.
* Calendar proposals.
* Completion tracking.

## 7.9 Decisions module

Responsibilities:

* Decision framing.
* Options.
* Criteria.
* Evidence.
* Tradeoffs.
* Final choice.
* Outcomes.
* Reflections.

## 7.10 Intelligence module

Responsibilities:

* Insights.
* Recommendations.
* Scores.
* Career Risks.
* Daily Mission.
* Weekly Strategy.
* Explainability.
* User feedback on intelligence.

## 7.11 Integration module

Responsibilities:

* OAuth accounts.
* Token lifecycle.
* Provider clients.
* Synchronization cursors.
* Webhooks.
* Ingestion jobs.
* Import approval.

---

# 8. Frontend Architecture

## 8.1 Primary interface

Career OS uses:

* Mission Control.
* Object pages.
* Context side panels.
* Global command palette.
* Embedded AI insights.
* Search.
* Notification center.

## 8.2 Mission Control

Mission Control should display:

* Today’s top priorities.
* Calendar commitments.
* Actionable email classifications.
* Upcoming deadlines.
* Interview preparation.
* Relationship follow-ups.
* Important Opportunities.
* Career Risks.
* Goal progress.
* Selected market-review items.

Mission Control should prioritize action over raw metrics.

## 8.3 Context panel

Clicking an object should normally open a side panel containing:

* Summary.
* Current status.
* Relevant relationships.
* Timeline.
* Next actions.
* Embedded AI insight.
* Link to full page.

## 8.4 Full object page

Full pages support deeper work such as:

* Editing.
* Timeline review.
* Relationship exploration.
* Document management.
* Decision analysis.
* AI recommendations.
* Activity history.

## 8.5 Command palette

The command palette should support:

* Search.
* Navigation.
* Add Task.
* Add Person.
* Add Opportunity.
* Create Knowledge Item.
* Log Interaction.
* Open Today.
* Run context-aware AI action.

## 8.6 State management

Use the smallest state-management scope possible.

Preferred hierarchy:

1. Server-rendered data.
2. URL state.
3. Component-local state.
4. Query cache for client data.
5. Global client state only for genuinely global interface state.

Canonical domain state must remain server-side.

---

# 9. Application Layer

The application layer coordinates use cases.

It should not contain complex UI logic or infrastructure-specific code.

Examples:

* Create an Opportunity.
* Approve an imported Interview invitation.
* Move an Application to Assessment.
* Schedule a proposed Time Block.
* Record an Interaction.
* Generate a Daily Mission.
* Accept or reject a Recommendation.

Each command should:

1. Validate input.
2. Authorize the user.
3. Load relevant domain data.
4. Enforce lifecycle and business rules.
5. Persist changes transactionally.
6. Record Activity.
7. Publish internal events where needed.
8. Return a typed result.

---

# 10. Database Architecture

## 10.1 Canonical relational storage

PostgreSQL is the canonical system of record.

Major table groups will include:

* Users and identities.
* Domain objects.
* Supporting records.
* Typed relationships.
* Lifecycle transitions.
* Activities.
* Integrations.
* Intelligence outputs.
* Files and Document versions.
* Approval requests.
* Audit logs.

## 10.2 Graph-compatible relationship model

Career OS should maintain a typed relationship table conceptually containing:

```text
id
owner_user_id
relationship_type
source_object_type
source_object_id
target_object_type
target_object_id
origin_type
confidence
valid_from
valid_until
verification_status
metadata
created_at
updated_at
```

High-frequency relationships may later receive optimized domain-specific tables.

## 10.3 Object registry

A shared object registry may be introduced to provide:

* Stable cross-domain object identity.
* Generic relationships.
* Universal search.
* Activity linkage.
* Tags.
* Attachments.

Domain-specific fields remain in domain-specific tables.

## 10.4 Lifecycle history

Status changes must use append-only transition records where practical.

Current state may be stored for efficient access but must remain reconcilable with transition history.

## 10.5 Multi-tenancy

Even though Version 1 is built for Ahmed, Personal Layer records should include an owner or tenant identifier.

Row-Level Security must prevent cross-user access.

## 10.6 World objects

Version 1 may treat World objects as user-scoped records to simplify privacy and identity resolution.

A later release may introduce shared canonical World objects with user-specific overlays.

---

# 11. Controlled Intelligence Ingestion Pipeline

External information enters Career OS through a controlled pipeline.

```text
External Source
      ↓
Fetch Metadata
      ↓
Relevance Classification
      ↓
Entity and Event Extraction
      ↓
Deduplication
      ↓
Proposed Object or Update
      ↓
User Approval
      ↓
Transactional Persistence
      ↓
Activity and Intelligence Refresh
```

## 11.1 Pipeline stages

### Detect

Identify new or changed external records.

### Filter

Determine whether the item is potentially relevant to Career OS.

### Classify

Examples:

* Application confirmation.
* Interview invitation.
* Rejection.
* Offer.
* Networking reply.
* Professor outreach.
* Research collaboration.
* Deadline.

### Extract

Extract structured information:

* Organization.
* Opportunity.
* Person.
* Date.
* Deadline.
* Action required.
* Related Application.
* Confidence.

### Resolve

Match extracted entities against existing records.

### Propose

Create an approval item describing the proposed changes.

### Approve

The user approves, edits, or rejects the proposed changes.

### Persist

Approved changes are stored transactionally.

## 11.2 Raw content policy

Career OS should avoid storing full raw content when metadata, structured extraction, or short excerpts are sufficient.

Raw sensitive data retention should be configurable.

---

# 12. Google Integration Architecture

## 12.1 OAuth

Google integrations use OAuth 2.0.

Career OS must never request or store the user’s Google password.

Scopes should be requested incrementally.

## 12.2 Gmail

Initial Gmail capabilities:

* Search relevant messages.
* Read message metadata and selected bodies.
* Classify career-related emails.
* Connect emails to Applications, People, Organizations, and Opportunities.
* Propose Tasks and status updates.
* Create draft replies with approval.

No automatic sending in Version 1.

## 12.3 Google Calendar

Capabilities:

* Read scheduled events.
* Identify interviews, meetings, classes, and career commitments.
* Connect events to Career OS objects.
* Propose Time Blocks.
* Create or modify events only after user approval.

## 12.4 Google Drive

Capabilities:

* Locate selected career Documents.
* Read metadata.
* Link files without unnecessary duplication.
* Import selected files into Career OS storage when explicitly requested.

## 12.5 Google Sheets

Sheets is a reporting and interoperability layer.

Use cases:

* Applications export.
* Contact export.
* Weekly actions.
* Visa comparison.
* Analytics backup.

PostgreSQL remains the canonical system of record.

## 12.6 Google Contacts

Capabilities:

* Match known People.
* Retrieve user-approved contact details.
* Prevent duplicate Person records.

---

# 13. AI Architecture

## 13.1 AI responsibilities

AI may:

* Classify.
* Extract.
* Summarize.
* Compare.
* Recommend.
* Detect risks.
* Draft.
* Explain.
* Suggest relationships.
* Assemble Daily Missions.
* Support Decisions.

## 13.2 AI authority limits

AI may not independently:

* Send emails.
* Submit Applications.
* Accept offers.
* Execute trades.
* Make legal determinations.
* Change external calendars.
* Delete user data permanently.
* Finalize major Decisions.

## 13.3 Context assembly

AI requests should receive only the context required for the task.

Context may include:

* Current object.
* Relevant Goals.
* Recent Activities.
* Connected People.
* Related Knowledge and Evidence.
* Active Tasks.
* Deadlines.
* User preferences.

## 13.4 Intelligence persistence

Insights, Recommendations, Scores, and Risks must be persisted when they affect the user experience or downstream decisions.

Transient drafting assistance does not always require persistence.

## 13.5 Structured outputs

AI outputs used programmatically must use validated structured schemas.

Unparseable output should fail safely and never silently mutate records.

## 13.6 Explainability record

Persist:

* Input object references.
* Evidence references.
* Model identifier.
* Prompt or instruction version.
* Reasoning summary.
* Confidence.
* Generated timestamp.
* Expiration conditions.

The platform should expose concise reasoning rather than hidden internal chain-of-thought.

## 13.7 Human feedback

Users may:

* Accept.
* Reject.
* Edit.
* Dismiss.
* Mark incorrect.
* Provide an explanation.

Feedback should improve future relevance without treating one response as a universal rule.

---

# 14. Search Architecture

Career OS requires universal search across:

* People.
* Organizations.
* Opportunities.
* Applications.
* Projects.
* Goals.
* Decisions.
* Knowledge.
* Documents.
* Tasks.
* Skills.

## 14.1 Search phases

### Phase 1

PostgreSQL full-text search and indexed filtering.

### Phase 2

Semantic search using embeddings for Knowledge, Documents, Opportunities, and People.

### Phase 3

Hybrid ranking combining:

* Text relevance.
* Semantic similarity.
* Relationship distance.
* Recency.
* Goal alignment.
* Current context.

## 14.2 Search permissions

Search results must obey the same authorization and privacy rules as direct object access.

---

# 15. Background Processing

Background jobs are needed for:

* Gmail synchronization.
* Calendar synchronization.
* Token refresh.
* Opportunity expiration.
* Reminder scheduling.
* Intelligence refresh.
* Search indexing.
* Document processing.
* Duplicate detection.
* Stale Evidence detection.

## 15.1 Job requirements

Jobs should be:

* Idempotent.
* Retryable.
* Observable.
* Time-bounded.
* Deduplicated.
* Safe against partial failure.

## 15.2 Job records

Store:

* Job type.
* Input reference.
* Status.
* Attempt count.
* Started time.
* Completed time.
* Error summary.
* Correlation ID.

---

# 16. Internal Event Architecture

Career OS may use internal domain events within the modular monolith.

Examples:

* `application.submitted`
* `application.stage_changed`
* `interaction.recorded`
* `opportunity.discovered`
* `task.completed`
* `goal.at_risk`
* `document.version_created`
* `recommendation.accepted`

Events initially run through in-process handlers or durable database-backed jobs.

An external message broker is not required for the MVP.

---

# 17. Authentication and Identity

## 17.1 Authentication

Supabase Auth provides authentication.

Initial sign-in methods:

* Google sign-in.
* Optional email magic link.

## 17.2 Identity separation

Career OS identity and Google integration identity must be modeled separately.

A user may eventually connect multiple Google accounts.

## 17.3 Sessions

Sessions should use secure, HTTP-only cookies.

Server-side authorization must not rely only on client state.

---

# 18. Authorization

## 18.1 Row-Level Security

Personal data must be protected by PostgreSQL Row-Level Security.

## 18.2 Authorization checks

All server operations should verify:

* Authenticated user.
* Tenant or owner.
* Object access.
* Action permission.
* Integration permission.
* Approval requirement.

## 18.3 Future sharing

The architecture should permit future object sharing without assuming all records are shareable.

Sharing should be explicit and object-scoped.

---

# 19. Security Architecture

## 19.1 Secrets

Secrets must never be committed to GitHub.

Use managed environment variables.

## 19.2 OAuth tokens

OAuth tokens should be encrypted at rest.

Refresh tokens require stricter protection than ordinary application data.

## 19.3 Sensitive data

Sensitive categories include:

* Email contents.
* Immigration information.
* Trading records.
* Personal identity data.
* Private Documents.
* Contact details.

## 19.4 Audit logging

Audit consequential actions including:

* External writes.
* Email drafts and sends.
* Calendar changes.
* Application status changes.
* Data export.
* Integration connection.
* Permission changes.
* Permanent deletion.

## 19.5 Approval gates

Approval is required before:

* Sending email.
* Creating or changing external Calendar events.
* Importing sensitive full content.
* Updating consequential Application stages from inference.
* Exporting sensitive data.
* Deleting important objects permanently.

---

# 20. File and Document Storage

Supabase Storage may store uploaded files.

Document metadata remains in PostgreSQL.

## 20.1 Storage rules

* Use private buckets by default.
* Generate short-lived signed URLs.
* Preserve original files.
* New edits create new Document Versions.
* Calculate checksums.
* Scan uploads where practical.
* Restrict file types and sizes.

---

# 21. Notifications

Notification categories:

* Deadline.
* Interview.
* Relationship follow-up.
* Opportunity.
* Career Risk.
* Visa timeline.
* Recommendation.
* System and integration issue.

## 21.1 Notification principles

* High-priority notifications must be rare.
* Duplicate alerts must be suppressed.
* Users must be able to dismiss and snooze.
* Sensitive content should not be exposed unnecessarily in notification previews.
* Notifications should link to the relevant object and action.

---

# 22. Observability

Career OS should support:

* Structured logs.
* Error tracking.
* Performance metrics.
* Background-job monitoring.
* Integration health.
* AI latency and cost.
* Database health.
* Audit events.

## 22.1 Correlation IDs

Requests, jobs, external synchronization, and AI calls should use correlation IDs for traceability.

## 22.2 Privacy

Logs must not include unnecessary raw email content, access tokens, private Documents, or other sensitive information.

---

# 23. Testing Architecture

## 23.1 Unit tests

Test:

* Domain rules.
* Lifecycle transitions.
* Scoring factors.
* Validation.
* Permissions.
* Parsing.
* Deduplication.

## 23.2 Integration tests

Test:

* Database operations.
* Row-Level Security.
* OAuth flows.
* Gmail and Calendar adapters.
* Background jobs.
* AI structured outputs.

## 23.3 End-to-end tests

Test critical journeys:

* Sign in.
* Add an Opportunity.
* Create an Application.
* Add a Person.
* Record an Interaction.
* Create a Task.
* Review Mission Control.
* Approve a Gmail-detected Interview.
* Generate and review a Recommendation.

## 23.4 AI evaluation

AI features require evaluation datasets covering:

* Correct classification.
* Extraction accuracy.
* Recommendation relevance.
* Unsupported claims.
* Explanation quality.
* Sensitive action compliance.

---

# 24. Deployment Environments

Career OS should use:

* Local development.
* Preview deployment.
* Staging.
* Production.

Each environment must have separate:

* Database.
* OAuth configuration.
* Storage.
* Secrets.
* Integration credentials.

Production data must not be copied casually into development environments.

---

# 25. CI/CD

GitHub Actions should eventually run:

* Dependency installation.
* Type checking.
* Linting.
* Unit tests.
* Integration tests.
* Build validation.
* Migration checks.
* Security scanning.

Pull requests should receive preview deployments when possible.

Production deployments should occur only after required checks pass.

---

# 26. Performance Strategy

Initial performance goals:

* Mission Control should load quickly enough for daily use.
* Side panels should feel immediate.
* Search should return useful results rapidly.
* AI should not block ordinary CRUD workflows.
* Background synchronization should not delay the main interface.

Use:

* Database indexes.
* Server-side rendering.
* Incremental loading.
* Query caching where safe.
* Pagination.
* Precomputed intelligence where appropriate.

---

# 27. Scalability Roadmap

## Phase 1 — Personal MVP

* One primary user.
* Modular monolith.
* PostgreSQL graph-compatible relationships.
* Manual and controlled Google synchronization.
* Basic AI intelligence.
* Vercel and Supabase.

## Phase 2 — Expanded personal platform

* More integrations.
* Semantic search.
* Richer Opportunity Radar.
* Advanced decision support.
* Improved analytics.
* More background jobs.

## Phase 3 — Multi-user beta

* Strong tenant separation.
* Shared World objects.
* User onboarding.
* Usage quotas.
* Billing-ready architecture.
* Shared templates.

## Phase 4 — Platform extraction

Potential extracted services:

* Intelligence workers.
* Search and indexing.
* Integration ingestion.
* Notification delivery.
* Document processing.
* Graph analytics.

## Phase 5 — Dedicated graph projection

Consider a graph engine when PostgreSQL traversal becomes a demonstrated constraint.

PostgreSQL remains the transactional source of truth unless a later ADR explicitly changes that decision.

---

# 28. Explicit Non-Goals for the MVP

The MVP will not include:

* Autonomous email sending.
* Autonomous Application submission.
* Automated trading.
* Personalized legal advice.
* Native mobile applications.
* Public social networking.
* Enterprise collaboration.
* A dedicated graph database.
* Complex microservices.
* Fully autonomous AI agents.
* Automatic ingestion of all Gmail or Drive content.

---

# 29. Architecture Risks

## Risk: Excessive scope

Mitigation:

* Build a narrow MVP.
* Prioritize Mission Control, Applications, People, Tasks, and controlled Gmail integration.

## Risk: AI unreliability

Mitigation:

* Structured outputs.
* Evidence references.
* Approval gates.
* Human feedback.
* AI-independent workflows.

## Risk: Sensitive-data exposure

Mitigation:

* Minimum scopes.
* Encryption.
* RLS.
* Private storage.
* Restricted logs.
* Approval-based ingestion.

## Risk: Knowledge graph complexity

Mitigation:

* PostgreSQL first.
* Typed relationship ontology.
* Query patterns defined before optimization.
* Dedicated graph engine only after measured need.

## Risk: Dashboard overload

Mitigation:

* Daily prioritization.
* Collapsible sections.
* User customization.
* Small number of critical alerts.
* Context panels instead of excessive navigation.

---

# 30. Initial MVP Architecture Scope

The first implementation should support:

1. Google authentication.
2. Mission Control shell.
3. Opportunities.
4. Applications.
5. People and Organizations.
6. Relationships and Interactions.
7. Tasks and deadlines.
8. Basic Calendar read integration.
9. Controlled Gmail classification.
10. Documents and resume versions.
11. Basic Insights and Recommendations.
12. Google Sheets export.
13. Audit and approval records.

---

# 31. Architecture Acceptance Criteria

This architecture is successful when:

* The core product works without microservices.
* Domain modules remain clearly separated.
* Google integrations can be disabled without breaking core workflows.
* AI failures do not prevent ordinary use.
* Every consequential external action requires approval.
* Every intelligence output can reference its inputs.
* Personal records are protected by database authorization.
* New object types can be added without redesigning the entire system.
* A future graph projection can be added without replacing the transactional model.
* The repository remains understandable to a new engineer.

---

# 32. Open Architecture Questions

The following require later specifications or ADRs:

1. Exact monorepo tooling.
2. Final UI component library.
3. AI provider selection.
4. Embedding model and vector-storage approach.
5. Background-job platform.
6. Database object registry design.
7. Generic versus specialized relationship tables.
8. OAuth token encryption implementation.
9. Notification delivery channels.
10. Analytics event schema.
11. Search ranking algorithm.
12. Shared World-object strategy.
13. Data-retention rules.
14. Backup and disaster recovery.
15. Market and trading integration boundaries.

---

# 33. Next Documents

* `docs/03-architecture/SECURITY.md`
* `docs/03-architecture/INTEGRATIONS.md`
* `docs/04-database/ERD.md`
* `docs/04-database/DATABASE_SCHEMA.md`
* `docs/05-api/API_SPECIFICATION.md`
* `docs/06-ai/AI_ARCHITECTURE.md`
* `docs/08-ui-ux/DESIGN_SYSTEM.md`
* `docs/10-engineering/ENGINEERING_PRINCIPLES.md`
* `docs/12-roadmap/MVP_ROADMAP.md`

