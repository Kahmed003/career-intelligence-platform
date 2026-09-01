## 1. Purpose

Defines how Supabase Auth identities map into Career OS authorization and profile data.

## 2. Identity Model

`auth.users` is the authentication identity source.

`public.profiles` is the Career OS application profile associated one-to-one with the authenticated user ID.

Domain ownership is expressed through canonical `public.objects.owner_user_id`.

## 3. Authentication vs Authorization

Authentication answers:

> Who is the caller?

Authorization answers:

> What may the caller access or mutate?

Supabase Auth establishes identity. PostgreSQL RLS and validation functions enforce authorization.

Frontend checks are convenience controls only and must not be treated as security boundaries.

## 4. User Provisioning

On account creation, Career OS should create or ensure the corresponding application profile transactionally through an approved database/Auth integration path.

Provisioning must be idempotent.

## 5. JWT Identity

RLS policies use the authenticated JWT subject through `auth.uid()` or approved shared wrapper functions.

Client-supplied owner IDs are never trusted without comparing them to authenticated identity.

## 6. Service Role

The Supabase service role bypasses normal RLS and is therefore privileged infrastructure.

Rules:

- never expose it to browser/mobile clients;
- use it only in trusted server/Edge Function environments;
- minimize code paths that require it;
- perform explicit owner/authorization checks when acting on behalf of users;
- audit sensitive service operations.

## 7. Anonymous Users

Anonymous database access is denied by default unless a capability is explicitly designed to be public.

Public avatar reads are a documented Storage exception.

## 8. Account Deletion

Account deletion requires an explicit data-retention workflow.

The system must determine:

- which user-owned records are hard-deleted;
- which audit records require retention;
- how Storage objects are removed;
- how external integration credentials are revoked;
- how pending sync jobs are cancelled.

## 9. Security Requirements

- RLS enabled on every user-accessible table.
- Same-owner foreign references validated.
- No authorization decisions based solely on request payload fields.
- Privileged functions use hardened `search_path`.
- Function EXECUTE privileges follow least privilege.
- Auth tokens and refresh tokens are never stored in ordinary domain tables.

## 10. Testing Requirements

Authentication tests must cover:

- unauthenticated denial;
- owner read/write;
- cross-user read denial;
- cross-user mutation denial;
- forged owner IDs;
- deleted-object behavior;
- privileged server paths.
