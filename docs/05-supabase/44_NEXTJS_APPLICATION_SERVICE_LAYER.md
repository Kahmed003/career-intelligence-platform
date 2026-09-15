# Career OS — Next.js Application Service Layer

**Document ID:** COS-APP-SVC-001  
**Version:** 1.0.0  
**Status:** Approved for implementation  
**Depends on:** `43_NEXTJS_TYPESCRIPT_DATA_ACCESS_LAYER.md`

## Purpose

The Application Service Layer owns Career OS use-case orchestration.

Repositories remain responsible for persistence. PostgreSQL remains responsible for RLS,
constraints, cross-owner integrity, and authoritative validation. Services coordinate
multi-repository workflows and Activity Ledger writes.

## Boundary

```text
Next.js UI / Server Actions / Route Handlers
                    |
                    v
           Application Services
                    |
                    v
              Repositories
                    |
                    v
         Supabase / PostgreSQL
```

UI code must not compose database mutations directly.

## Implemented services

- `ProjectsService`
- `TasksService`
- `OrganizationsService`
- `PeopleService`
- `OpportunitiesService`
- `ApplicationsService`
- `ActivityLedgerService`

## Workflow rules

### Create
A create workflow:
1. calls the domain repository;
2. receives the canonical object plus domain row;
3. records `object_created` in the Activity Ledger.

### Update
A material update:
1. updates the domain row;
2. optionally updates canonical object fields such as `title`;
3. records `object_updated`.

### Application transitions
Application status changes are routed through `ApplicationsService.transitionStatus()`.
The database still validates the lifecycle. The service adds workflow timestamps where
the transition semantics are unambiguous and records `status_changed`.

### Failure semantics
The domain mutation is authoritative. Activity logging is attempted after the domain
mutation. If ledger insertion fails, the service throws `WorkflowPartialFailureError`
rather than pretending the entire operation rolled back.

For workflows that require strict all-or-nothing semantics, create a PostgreSQL RPC in
a future database migration and invoke it from the service.

## Security

Services never accept an `owner_user_id` from client input. Supabase Auth + RLS establish
the caller identity. No service-role client belongs in browser code.

## Commit

`feat(application): add core Career OS workflow services`
