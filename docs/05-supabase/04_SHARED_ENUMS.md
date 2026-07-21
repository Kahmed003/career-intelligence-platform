Career OS — Shared PostgreSQL Enums

Document ID: COS-SUP-ENUM-001Version: 1.0.0Status: Approved for implementationCanonical path: docs/05-supabase/04_SHARED_ENUMS.mdRelated migration: supabase/migrations/20260721000200_create_shared_enums.sqlLast updated: 2026-07-21

1. Purpose

This document defines the initial PostgreSQL enums shared across the Career OS backend.

Enums are reserved for values that are:

structurally stable;

used across multiple domains;

required for database-level integrity;

unlikely to require frequent customer-specific extension;

meaningful enough to justify a dedicated PostgreSQL type.

Extensible business taxonomies, such as opportunity types, relationship types, project categories, skills, industries, and knowledge classifications, must use reference tables rather than PostgreSQL enums.

2. Design Rule

A PostgreSQL enum should be introduced only when all of the following are true:

the value set is closed or changes rarely;

the values have platform-wide meaning;

invalid values must be rejected at the database boundary;

ordering and comparison semantics are not likely to change;

a reference table would add complexity without meaningful configurability.

3. Initial Shared Enums

3.1 public.lifecycle_status

Represents the high-level lifecycle state shared by first-class Career OS objects.

Value

Meaning

draft

The record exists but is not yet operational or complete.

active

The record is currently operational or in progress.

paused

Work or activity is temporarily suspended.

completed

The intended lifecycle outcome has been achieved.

cancelled

The record was intentionally terminated before completion.

archived

The record is retained for history but removed from normal active use.

This enum is intentionally broad. Specialized tables may add domain-specific status fields where necessary, but those states must remain compatible with the canonical lifecycle state.

3.2 public.visibility_scope

Represents the default visibility boundary for a Career OS object.

Value

Meaning

private

Accessible only to the owner and explicitly privileged system processes.

shared

Accessible to explicitly authorized users, teams, or workspaces.

public

Eligible for public or externally accessible presentation, subject to policy.

Visibility does not replace Row-Level Security. It is one input into authorization decisions.

3.3 public.relationship_directionality

Represents whether a graph relationship has semantic direction.

Value

Meaning

directed

The source and target roles are distinct and order matters.

undirected

The relationship is symmetric and endpoint order has no semantic meaning.

3.4 public.activity_actor_type

Identifies the category of actor responsible for an activity-ledger event.

Value

Meaning

user

A human user initiated the activity.

system

Career OS internal logic initiated the activity.

agent

An AI agent initiated or materially executed the activity.

integration

An external connected service initiated the activity.

4. Naming Standard

PostgreSQL enum type names:

use lowercase snake_case;

are singular;

are schema-qualified;

describe the semantic concept rather than a specific table;

do not use an _enum suffix.

Enum values:

use lowercase snake_case;

must be concise and semantically stable;

must not encode display labels;

must not contain spaces or punctuation.

5. Change Management

Existing enum values must not be renamed or removed casually because PostgreSQL enum evolution can affect data, generated types, migrations, and application compatibility.

Permitted changes:

add a new value through a dedicated forward migration;

document the business reason;

update generated TypeScript types;

add tests for the new state;

verify ordering assumptions before using BEFORE or AFTER.

Deprecated values should normally remain in the type and be blocked from new writes through constraints or validation until historical data is migrated safely.

6. Security Considerations

Enums do not grant access. They provide type integrity only.

Authorization must remain enforced through:

ownership columns;

membership tables;

Row-Level Security policies;

security-definer functions with fixed search paths;

service-role controls.

7. Validation Requirements

The migration is valid when:

all four enum types exist in public;

each type contains the documented values;

rerunning the migration logic does not duplicate types;

invalid values are rejected by PostgreSQL;

generated TypeScript types can represent every enum value.

8. Recommended Commit Message

feat(database): create shared platform enums

9. Root README Addition

- [Shared PostgreSQL Enums](docs/05-supabase/04_SHARED_ENUMS.md) — stable cross-domain lifecycle, visibility, graph, and activity actor types.
