Career OS — Storage Foundation

Document ID: COS-SUP-STO-001Version: 1.0.0Status: Approved for implementationCanonical path: docs/05-supabase/06_STORAGE.mdRelated migration: supabase/migrations/20260721000700_create_storage_foundation.sqlLast updated: 2026-07-21

1. Purpose

This document defines the initial Supabase Storage architecture for Career OS.

Supabase Storage stores binary assets outside the relational domain model whilePostgreSQL retains authoritative metadata, ownership, object relationships, andaccess rules.

2. Design Principles

Buckets are private by default.

Storage access is enforced through RLS on storage.objects.

File operations must use the Supabase Storage API rather than direct SQLmutation of object metadata.

The first path segment must be the authenticated user's UUID.

The database domain model remains the source of truth for file meaning.

Public access is permitted only for deliberately public media.

Service-role credentials must never be exposed to clients.

3. Initial Buckets

Bucket

Access

Purpose

Size limit

user-files

Private

Resumes, reports, notes, exports, and general user documents

25 MB

evidence

Private

Application evidence, certificates, research artifacts, and supporting files

50 MB

avatars

Public-read

User profile images

5 MB

4. Object Path Convention

Every user-owned object uses this structure:

<user_uuid>/<domain>/<object_uuid>/<filename>

Examples:

7f...91/applications/31...aa/resume.pdf
7f...91/evidence/48...19/certificate.pdf
7f...91/profile/avatar.webp

The authenticated user's UUID must be the first path segment. RLS policies verifythis path namespace.

5. Security Model

Private buckets

Authenticated users may:

upload into their own UUID namespace;

list and download files they own;

update files they own;

delete files they own.

Avatar bucket

Avatar reads are public because the bucket is public. Upload, update, and deleteremain restricted to the authenticated owner's namespace.

6. Relational Metadata

A later domain migration should introduce an attachment or asset table that links:

storage.objects.id;

bucket ID;

storage path;

owner;

Career OS object;

MIME type;

checksum;

semantic role;

ingestion status;

AI-processing status.

Storage paths alone must not become the authoritative business relationship.

7. Operational Rules

Do not directly insert, update, or delete rows in storage.objects.

Use the Storage API for upload, move, copy, and delete operations.

Signed URLs should be short-lived.

Validate MIME type and size at both client and bucket boundaries.

Sanitize filenames before constructing object paths.

Never trust a client-provided owner ID without RLS validation.

Moving a file between user namespaces requires privileged server-side logic.

8. Initial MIME Restrictions

user-files

PDF

Microsoft Word

OpenXML Word

plain text

CSV

PNG

JPEG

WebP

evidence

PDF

PNG

JPEG

WebP

plain text

CSV

avatars

PNG

JPEG

WebP

9. Testing Requirements

Tests must verify:

users can upload within their own namespace;

users cannot upload into another user's namespace;

users can read their private files;

users cannot read another user's private files;

avatars are publicly readable;

only owners can mutate avatars;

anonymous users cannot upload;

bucket size and MIME restrictions are enforced.

10. Recommended Commit Message

feat(storage): create buckets and owner-scoped policies

11. Root README Addition

- [Storage Foundation](docs/05-supabase/06_STORAGE.md) — bucket architecture, user path conventions, access policies, and file-governance rules.
