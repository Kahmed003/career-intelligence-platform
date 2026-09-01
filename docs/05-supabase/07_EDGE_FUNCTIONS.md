
# Career OS — Edge Functions

**Document ID:** COS-SUP-EDGE-001  
**Version:** 1.0.0  
**Status:** Approved for implementation  
**Canonical path:** `docs/05-supabase/07_EDGE_FUNCTIONS.md`

## 1. Purpose

Defines when and how Career OS uses Supabase Edge Functions.

## 2. Appropriate Uses

Edge Functions are appropriate for:

- webhook receivers;
- external API integrations;
- secure server-side orchestration;
- notification delivery;
- calendar synchronization;
- opportunity ingestion;
- AI-provider calls requiring secrets;
- document-generation orchestration;
- scheduled worker entry points.

## 3. Inappropriate Uses

Do not move database invariants into Edge Functions when PostgreSQL can enforce them reliably.

Edge Functions must not become:

- an alternate authorization system;
- a duplicate object registry;
- a second lifecycle-state authority;
- an untracked store for business data.

## 4. Authentication

User-facing functions should validate the caller's Supabase JWT.

Service-to-service functions require an explicit trusted authentication mechanism.

Never trust user IDs supplied in request bodies as proof of identity.

## 5. Authorization

Prefer RLS-preserving user-context database access when possible.

When a service-role client is required, the function must explicitly validate the user's authorization before accessing or mutating data.

## 6. Secrets

Secrets belong in approved environment/secret management.

Never store provider API keys, OAuth client secrets, refresh tokens, cookies, or passwords in normal Career OS domain tables.

## 7. Idempotency

Webhook and ingestion functions must support retries.

Use stable external event IDs, message IDs, dedupe keys, or idempotency keys where available.

A repeated provider delivery must not create duplicate canonical records.

## 8. Error Handling

Functions should return structured errors without leaking:

- secrets;
- database credentials;
- stack traces containing sensitive data;
- provider tokens;
- private user content.

Operational failures should be logged with correlation identifiers.

## 9. Timeouts and Long Work

Long-running workflows should be decomposed into resumable jobs or provider-specific workers rather than relying on one long request.

## 10. Observability

Record enough metadata to trace:

```text
request
→ authenticated actor
→ integration/provider
→ correlation ID
→ database mutation
→ activity event
→ delivery/sync result
```

## 11. Testing

Each function should have:

- authentication tests;
- authorization tests;
- request validation tests;
- idempotency tests;
- provider failure tests;
- database integration tests;
- retry behavior tests where relevant.
