Career OS — Object Registry

Document ID: COS-SUP-OBJ-001Version: 1.0.0Status: Approved for implementationCanonical path: docs/05-supabase/06_OBJECT_REGISTRY.mdRelated migration: supabase/migrations/20260721000400_create_object_registry.sqlLast updated: 2026-07-21

1. Purpose

The Object Registry provides the canonical identity layer for every first-classCareer OS domain object.

Projects, tasks, people, organizations, opportunities, applications, knowledgerecords, evidence records, recommendations, and future domain entities receiveone registry record before or alongside creation of their specialized table row.

2. Responsibilities

The registry centralizes:

globally unique object identity;

canonical owner;

object type;

lifecycle state;

visibility;

human-readable title;

extensible metadata;

creation and update timestamps;

archival and soft-deletion state;

cross-domain references.

3. Table

public.objects

Column

Purpose

id

Canonical UUID for the object

owner_user_id

User who owns the object

object_type

Stable machine-readable type code

title

Human-readable primary label

lifecycle_status

Canonical high-level state

visibility

Default access boundary

metadata

Non-authoritative extensible JSON metadata

created_at

Creation timestamp

updated_at

Last update timestamp

archived_at

Time the object entered archived state

deleted_at

Soft-deletion timestamp

4. Object Type Strategy

object_type is stored as constrained text rather than a PostgreSQL enum.

Reason:

object types will grow as vertical slices are introduced;

deployments may add new domain modules;

type codes require controlled extensibility;

a future reference table can add display labels and capability metadata.

The first migration permits these type codes:

project

task

person

organization

opportunity

application

knowledge

evidence

recommendation

5. Integrity Rules

Every object must have an owner.

Every object type must use lowercase snake_case.

Titles cannot be blank.

Archived objects must use lifecycle state archived.

A deleted object must have a deletion timestamp.

Metadata must be a JSON object.

updated_at is maintained by a database trigger.

Owners cannot be silently changed through normal client updates once domainauthorization rules are introduced.

6. Indexes

The migration creates indexes for:

owner and active objects;

owner and lifecycle status;

object type and lifecycle status;

active-object creation time;

GIN search over metadata;

trigram search over titles.

7. Security Posture

RLS is enabled immediately.

Initial policies allow authenticated users to:

read their own objects;

create objects owned by themselves;

update their own objects;

delete their own objects.

Shared and workspace access will be added in later migrations after membership andpermission structures exist.

8. Specialized Table Contract

Every specialized object table must:

use the same UUID as public.objects.id;

reference public.objects(id) with a named foreign key;

enforce the expected object_type;

avoid duplicating canonical owner, title, lifecycle, and visibility unless adocumented denormalization is required;

delete or archive consistently with the registry.

9. Recommended Commit Message

feat(database): create canonical object registry

10. Root README Addition

- [Object Registry](docs/05-supabase/06_OBJECT_REGISTRY.md) — canonical identity, ownership, lifecycle, visibility, and metadata for first-class domain objects.
