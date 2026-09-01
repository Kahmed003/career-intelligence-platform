## Scope

This batch addresses deployment-blocking and ownership-integrity issues discovered after the first vertical-slice sequence.

It contains forward migrations only. Previously applied migrations are not edited.

## Fixes

### 1. Object Registry type expansion

The original Object Registry allowed only the initial domain types. Later vertical slices introduced additional first-class objects. The registry constraint is widened to accept every first-class object currently used by the schema.

### 2. Owner-scoped Project codes

Project codes should be unique per owner rather than globally unique.

### 3. Owner-scoped Organization domains

Organization `primary_domain` should be unique per owner rather than globally unique, allowing separate users to independently track the same real-world organization.

### 4. Task hierarchy ownership

Task project/parent references must resolve to active objects owned by the same user. Recursive parent cycles are rejected.

## Deployment Order

1. `20260721012800_expand_object_registry_types.sql`
2. `20260721012900_harden_project_and_organization_uniqueness.sql`
3. `20260721013000_harden_task_hierarchy.sql`
4. run `supabase/tests/database/001_hardening_batch_1.sql`

## Recovery

These are forward-hardening migrations. Rollback should also be performed through a new forward migration after dependency analysis.

