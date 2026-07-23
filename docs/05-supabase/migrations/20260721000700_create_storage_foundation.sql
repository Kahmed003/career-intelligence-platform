/*
===============================================================================
Career OS Database Migration

Migration ID:    20260721000700
Filename:        20260721000700_create_storage_foundation.sql
Version:         1.0.0
Purpose:         Create the initial Supabase Storage buckets and owner-scoped
                 access policies.

Dependencies:
  - Supabase Storage schema and service
  - 20260721000300_create_users_and_profiles.sql

Affected Schemas:
  - storage

Security Considerations:
  - User files and evidence are private.
  - Avatar reads are public, but mutations remain owner-scoped.
  - User UUID must be the first object-path segment.
  - Service-role access bypasses RLS and must remain server-side.

Rollback Strategy:
  Removing buckets may orphan or destroy access to stored assets. Rollback must
  be performed through the Storage API after retention review. Policies may be
  removed through a dedicated forward migration.

Important:
  Supabase Storage object operations must use the Storage API. This migration
  configures buckets and RLS policies only; it does not mutate stored objects.
===============================================================================
*/

begin;

/*
Create and configure the initial buckets.

Bucket configuration is applied deterministically so clean database resets
produce the same development environment.
*/
insert into storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
values
    (
        'user-files',
        'user-files',
        false,
        26214400,
        array[
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'text/plain',
            'text/csv',
            'image/png',
            'image/jpeg',
            'image/webp'
        ]
    ),
    (
        'evidence',
        'evidence',
        false,
        52428800,
        array[
            'application/pdf',
            'text/plain',
            'text/csv',
            'image/png',
            'image/jpeg',
            'image/webp'
        ]
    ),
    (
        'avatars',
        'avatars',
        true,
        5242880,
        array[
            'image/png',
            'image/jpeg',
            'image/webp'
        ]
    )
on conflict (id) do update
set
    name = excluded.name,
    public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

/*
Private file reads.

The owner_id field is populated from the JWT subject by Supabase Storage.
The path-prefix check adds defense in depth and creates a predictable namespace.
*/
drop policy if exists career_os_private_files_select_own
on storage.objects;

create policy career_os_private_files_select_own
on storage.objects
for select
to authenticated
using (
    bucket_id in ('user-files', 'evidence')
    and owner_id = (select auth.uid()::text)
    and (storage.foldername(name))[1] = (select auth.uid()::text)
);

/*
Private file uploads.
*/
drop policy if exists career_os_private_files_insert_own
on storage.objects;

create policy career_os_private_files_insert_own
on storage.objects
for insert
to authenticated
with check (
    bucket_id in ('user-files', 'evidence')
    and (storage.foldername(name))[1] = (select auth.uid()::text)
);

/*
Private file updates, including API-based upserts.
*/
drop policy if exists career_os_private_files_update_own
on storage.objects;

create policy career_os_private_files_update_own
on storage.objects
for update
to authenticated
using (
    bucket_id in ('user-files', 'evidence')
    and owner_id = (select auth.uid()::text)
    and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
    bucket_id in ('user-files', 'evidence')
    and owner_id = (select auth.uid()::text)
    and (storage.foldername(name))[1] = (select auth.uid()::text)
);

/*
Private file deletion.
*/
drop policy if exists career_os_private_files_delete_own
on storage.objects;

create policy career_os_private_files_delete_own
on storage.objects
for delete
to authenticated
using (
    bucket_id in ('user-files', 'evidence')
    and owner_id = (select auth.uid()::text)
    and (storage.foldername(name))[1] = (select auth.uid()::text)
);

/*
Avatar uploads remain owner-scoped even though reads are public through the
public bucket access model.
*/
drop policy if exists career_os_avatars_insert_own
on storage.objects;

create policy career_os_avatars_insert_own
on storage.objects
for insert
to authenticated
with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists career_os_avatars_update_own
on storage.objects;

create policy career_os_avatars_update_own
on storage.objects
for update
to authenticated
using (
    bucket_id = 'avatars'
    and owner_id = (select auth.uid()::text)
    and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
    bucket_id = 'avatars'
    and owner_id = (select auth.uid()::text)
    and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists career_os_avatars_delete_own
on storage.objects;

create policy career_os_avatars_delete_own
on storage.objects
for delete
to authenticated
using (
    bucket_id = 'avatars'
    and owner_id = (select auth.uid()::text)
    and (storage.foldername(name))[1] = (select auth.uid()::text)
);

/*
Indexes supporting the policy predicates. Supabase permits custom indexes on
Storage metadata tables but recommends against structural schema alterations.
*/
create index if not exists ix_storage_objects__bucket_owner_name
on storage.objects(bucket_id, owner_id, name);

commit;
