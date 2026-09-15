# Career OS — Next.js Server Actions and Validation

**Document ID:** COS-APP-ACT-001
**Version:** 1.0.0
**Status:** Approved for implementation
**Depends on:** Data Access Batch 1; Application Services Batch 2

## Purpose
This is the authenticated mutation boundary between the Next.js UI and Career OS Application Services.

## Request Path
Client/Form → Server Action → Zod validation → authenticated server Supabase client → Application Service → ActionResult → cache revalidation.

## Rules
- Mutation modules use `"use server"`.
- Authentication is verified before services are called.
- External input is validated with Zod.
- PostgreSQL/RLS remains authoritative for ownership and cross-domain integrity.
- Expected failures return serializable `ActionResult`.
- Successful writes revalidate affected paths.
- No service-role credential is exposed to browser code.

## Implemented
Projects, Tasks, Organizations, People, Opportunities, Applications, and application status transitions.

## Commit
`feat(actions): add authenticated validated server action boundary`
