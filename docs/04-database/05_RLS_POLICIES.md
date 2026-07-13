# Career OS Row-Level Security (RLS) Policies

**Document ID:** DB-005
**Version:** 1.0
**Status:** Draft

---

# 1. Purpose

This document defines the Row-Level Security (RLS) architecture for Career OS.

It specifies:

* ownership rules
* authorization model
* tenant isolation
* server-only tables
* AI permissions
* integration permissions
* approval workflows
* inheritance of ownership
* security boundaries

Every table in Career OS must have an explicit RLS strategy.

No table should rely on application code alone for security.

---

# 2. Security Philosophy

Career OS follows four principles.

## Principle 1 — Default Deny

Every table begins with

```sql
ALTER TABLE ... ENABLE ROW LEVEL SECURITY;
```

and contains **no public access** until policies are explicitly added.

---

## Principle 2 — User owns their world

A user can only access:

* their Personal Objects
* their World Objects
* their Intelligence Objects

unless a future sharing model explicitly grants access.

---

## Principle 3 — Server owns automation

AI jobs

Background workers

Email synchronization

Calendar synchronization

Approval pipelines

may bypass RLS only through carefully audited server roles.

The client never bypasses RLS.

---

## Principle 4 — Database enforces security

The frontend

API

mobile app

AI

must never be responsible for enforcing ownership.

Only PostgreSQL decides whether a query succeeds.

---

# 3. Roles

Career OS assumes the following roles.

## Anonymous

Unauthenticated visitor.

Permissions:

None.

---

## Authenticated User

Standard logged-in user.

Permissions:

Read and modify only their own data.

---

## Service Role

Backend only.

Used by:

* AI pipelines
* scheduled jobs
* synchronization workers
* migration scripts

Never exposed to clients.

---

## Database Owner

Migration role.

No application should use this role.

---

# 4. Ownership Models

Career OS uses four ownership patterns.

---

## Model A

Direct ownership.

Example:

```text
tasks.owner_user_id
```

Policy:

```text
owner_user_id = auth.uid()
```

---

## Model B

Object ownership.

Example:

```text
projects.object_id

↓

objects.owner_user_id
```

Ownership is inherited.

---

## Model C

Join ownership.

Example:

```text
goal_milestones

↓

goal

↓

object

↓

owner
```

Ownership flows through the parent.

---

## Model D

Server owned.

Examples:

* audit logs
* credentials
* sync jobs

No client access.

---

# 5. Ownership Matrix

| Table Type           | Ownership |
| -------------------- | --------- |
| users                | direct    |
| objects              | direct    |
| tasks                | direct    |
| reminders            | direct    |
| organizations        | object    |
| people               | object    |
| projects             | object    |
| goals                | object    |
| applications         | object    |
| opportunities        | object    |
| skills               | object    |
| evidence             | object    |
| knowledge            | object    |
| documents            | object    |
| insights             | object    |
| recommendations      | object    |
| career risks         | object    |
| interactions         | direct    |
| integration accounts | direct    |
| email records        | direct    |
| calendar events      | direct    |
| audit logs           | server    |
| credentials          | server    |

---

# 6. Object Ownership

Every registered object has

```text
objects.owner_user_id
```

This field is the canonical ownership source.

All object-specialized tables inherit ownership through it.

Example

```text
projects

↓

objects

↓

owner_user_id
```

---

# 7. Direct Ownership Policy

Example:

```sql
USING (
    owner_user_id = auth.uid()
)
```

Insert:

```sql
WITH CHECK (
    owner_user_id = auth.uid()
)
```

---

# 8. Object Ownership Policy

Projects

Goals

Applications

People

Organizations

Knowledge

Evidence

Documents

Recommendations

use

```sql
EXISTS (
    SELECT 1
    FROM objects
    WHERE objects.id = projects.object_id
      AND objects.owner_user_id = auth.uid()
)
```

This pattern becomes the standard policy.

---

# 9. Child Ownership Policy

Example

Goal Milestone

Ownership path

```text
Goal Milestone

↓

Goal

↓

Object

↓

Owner
```

Policy

```sql
EXISTS (...)

```

following the parent chain.

---

# 10. CRUD Rules

Every table defines permissions separately.

| Operation | Rule                         |
| --------- | ---------------------------- |
| SELECT    | owner only                   |
| INSERT    | owner only                   |
| UPDATE    | owner only                   |
| DELETE    | owner only unless restricted |

---

# 11. Objects Policies

SELECT

Owner only.

INSERT

User must set

```text
owner_user_id = auth.uid()
```

UPDATE

Owner only.

DELETE

Owner only.

Future shared objects will extend this policy.

---

# 12. Relationship Policies

Relationships inherit ownership through

```text
owner_user_id
```

Users may only create edges inside their graph.

No cross-user edges.

---

# 13. Activity Policies

Activities are immutable.

Users:

SELECT

Yes.

INSERT

Only through application services.

UPDATE

Never.

DELETE

Never.

---

# 14. Lifecycle Policies

Users:

Read

Yes.

Insert

Application service.

Update

No.

Delete

No.

History must remain immutable.

---

# 15. Tasks

Users may

Create

Update

Delete

their own tasks.

No access to others.

---

# 16. Applications

Users may manage only applications connected to objects they own.

Application history inherits ownership.

---

# 17. People

People records remain private.

Even if another user creates

"John Smith"

it is a different object.

Version 1 has no global people directory.

---

# 18. Organizations

Organizations are also user scoped.

Future versions may introduce

shared organizations.

---

# 19. Documents

Users may read

their own documents.

Document versions inherit document ownership.

Files inherit document ownership.

---

# 20. Evidence

Evidence remains private.

Only the owner may modify it.

Future shared evidence libraries are outside MVP.

---

# 21. Email Security

Users may access only

their own email metadata.

Email body:

never directly exposed.

Decryption occurs only through backend services.

---

# 22. Calendar Security

Users may access only

their own calendar events.

Imported events remain private.

---

# 23. Integration Accounts

Users may

view

connect

disconnect

only their own integrations.

---

# 24. Credentials

Integration credentials

never

receive client policies.

Only service role.

---

# 25. AI Policies

AI never authenticates as a user.

The backend:

1.

validates request

2.

uses service role

3.

logs action

4.

returns filtered result

The AI never receives unrestricted database access.

---

# 26. Background Jobs

Background jobs

Server only.

No client access.

---

# 27. Notifications

Users may read

their own notifications.

Only backend creates notifications.

---

# 28. Audit Logs

Users do not access raw audit logs.

Administrative tooling only.

---

# 29. Sync Jobs

Server only.

---

# 30. Approval Requests

User

Read

Approve

Reject

only requests belonging to them.

---

# 31. Ingestion Candidates

User reviews only

their own candidates.

---

# 32. Intelligence

Recommendations

Insights

Career Risks

Scores

Daily Missions

Weekly Strategies

inherit ownership from

Objects.

---

# 33. Sharing Roadmap

Version 1

Private only.

Version 2

Object-level sharing.

Version 3

Workspace collaboration.

Version 4

Organization teams.

---

# 34. Security Helper Functions

Recommended helper:

```sql
is_object_owner(
    object_uuid uuid
)
```

returns boolean.

This removes repeated EXISTS clauses.

---

Second helper:

```sql
owns_registered_record(...)
```

for specialized tables.

---

# 35. Security Definer Functions

Allowed only for

* AI jobs
* synchronization
* migrations

Never callable directly from frontend.

---

# 36. Policy Naming

Naming convention:

```text
rls_<table>_<operation>
```

Example

```text
rls_tasks_select

rls_tasks_insert

rls_tasks_update

rls_tasks_delete
```

---

# 37. Performance

All ownership columns must be indexed.

Object ownership queries depend on

```text
objects.owner_user_id
```

which already has dedicated indexes.

Policies should avoid expensive recursive joins.

---

# 38. Testing Requirements

Every table must have tests verifying:

✔ owner can read

✔ owner can update

✔ owner cannot read another user's records

✔ owner cannot update another user's records

✔ anonymous user denied

✔ service role succeeds

---

# 39. Security Checklist

Every new table must answer:

* Who owns it?
* Can users insert?
* Can users update?
* Can users delete?
* Is history immutable?
* Is it server only?
* Does ownership inherit?
* Does it need helper functions?
* Does it require indexes?
* Does it require audit logging?

---

# 40. Acceptance Criteria

The RLS architecture is complete when:

* every table has an ownership model
* ownership inheritance is defined
* server-only tables are isolated
* object ownership is canonical
* helper functions are identified
* testing strategy exists
* future sharing can be added without redesign

---

# 41. Next Documents

* `docs/04-database/06_MIGRATION_STRATEGY.md`
* `docs/04-database/07_NAMING_CONVENTIONS.md`
* `supabase/migrations/`

