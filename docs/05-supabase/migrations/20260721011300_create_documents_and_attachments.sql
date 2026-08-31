
/*
Migration: 20260721011300_create_documents_and_attachments.sql
Purpose: Create governed document metadata and reusable object attachments.
*/
begin;

create table if not exists public.documents (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    document_type text not null default 'other'
        check (
            document_type in (
                'resume',
                'cover_letter',
                'offer_letter',
                'transcript',
                'certificate',
                'portfolio',
                'presentation',
                'research_output',
                'writing_sample',
                'project_deliverable',
                'interview_material',
                'application_material',
                'evidence',
                'reference',
                'other'
            )
        ),

    bucket_id text not null
        check (
            bucket_id in (
                'user-files',
                'evidence',
                'avatars'
            )
        ),

    storage_path text not null
        check (length(btrim(storage_path)) > 0),

    original_filename text not null
        check (length(btrim(original_filename)) > 0),

    display_filename text
        check (
            display_filename is null
            or length(btrim(display_filename)) > 0
        ),

    mime_type text
        check (
            mime_type is null
            or length(btrim(mime_type)) > 0
        ),

    file_extension text
        check (
            file_extension is null
            or file_extension ~ '^[a-z0-9][a-z0-9._+-]{0,31}$'
        ),

    file_size_bytes bigint
        check (
            file_size_bytes is null
            or file_size_bytes >= 0
        ),

    checksum_sha256 text
        check (
            checksum_sha256 is null
            or checksum_sha256 ~ '^[0-9a-fA-F]{64}$'
        ),

    document_status text not null default 'active'
        check (
            document_status in (
                'active',
                'archived',
                'replaced',
                'deleted'
            )
        ),

    source_type text not null default 'upload'
        check (
            source_type in (
                'upload',
                'generated',
                'imported',
                'email',
                'integration',
                'system',
                'other'
            )
        ),

    source_name text
        check (
            source_name is null
            or length(btrim(source_name)) > 0
        ),

    version_number integer not null default 1
        check (version_number > 0),

    supersedes_document_id uuid
        references public.documents(id)
        on update restrict
        on delete set null,

    is_primary boolean not null default false,

    description text,

    metadata jsonb not null default '{}'::jsonb
        check (jsonb_typeof(metadata) = 'object'),

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_documents__no_self_supersede
        check (
            supersedes_document_id is null
            or supersedes_document_id <> id
        )
);

comment on table public.documents is
'Governed file metadata for Career OS documents stored in Supabase Storage.';

create table if not exists public.document_attachments (
    document_id uuid not null
        references public.documents(id)
        on update restrict
        on delete cascade,

    object_id uuid not null
        references public.objects(id)
        on update restrict
        on delete restrict,

    attachment_role text not null default 'other'
        check (
            attachment_role in (
                'resume',
                'cover_letter',
                'offer_letter',
                'supporting_material',
                'evidence',
                'portfolio_item',
                'transcript',
                'certificate',
                'reference',
                'deliverable',
                'preparation',
                'other'
            )
        ),

    is_primary boolean not null default false,

    attached_at timestamptz not null default statement_timestamp(),

    metadata jsonb not null default '{}'::jsonb
        check (jsonb_typeof(metadata) = 'object'),

    primary key (document_id, object_id, attachment_role)
);

comment on table public.document_attachments is
'Reusable owner-scoped links between governed documents and canonical Career OS objects.';

drop trigger if exists trg_documents__set_updated_at
on public.documents;

create trigger trg_documents__set_updated_at
before update on public.documents
for each row
execute function private.set_updated_at();

create or replace function private.validate_document_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_supersedes_owner uuid;
    v_owner_prefix text;
begin
    select object_type, owner_user_id
      into v_type, v_owner
      from public.objects
     where id = new.id
       and deleted_at is null;

    if not found then
        raise exception 'Canonical object % does not exist or is deleted.', new.id
            using errcode = '23503';
    end if;

    if v_type <> 'document' then
        raise exception 'Object % must have object_type document.', new.id
            using errcode = '23514';
    end if;

    new.storage_path := btrim(new.storage_path);
    new.original_filename := btrim(new.original_filename);

    if new.display_filename is not null then
        new.display_filename := btrim(new.display_filename);
    end if;

    if new.mime_type is not null then
        new.mime_type := lower(btrim(new.mime_type));
    end if;

    if new.file_extension is not null then
        new.file_extension := lower(btrim(new.file_extension));
    end if;

    if new.checksum_sha256 is not null then
        new.checksum_sha256 := lower(btrim(new.checksum_sha256));
    end if;

    if new.source_name is not null then
        new.source_name := btrim(new.source_name);
    end if;

    v_owner_prefix := v_owner::text || '/';

    if left(new.storage_path, length(v_owner_prefix)) <> v_owner_prefix then
        raise exception 'Document storage path must begin with owner UUID %.', v_owner
            using errcode = '23514';
    end if;

    if new.supersedes_document_id is not null then
        select owner_user_id
          into v_supersedes_owner
          from public.objects
         where id = new.supersedes_document_id
           and object_type = 'document'
           and deleted_at is null;

        if not found then
            raise exception 'Superseded document % does not exist or is deleted.',
                new.supersedes_document_id
                using errcode = '23503';
        end if;

        if v_supersedes_owner <> v_owner then
            raise exception 'Document versions must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_documents__validate
on public.documents;

create trigger trg_documents__validate
before insert or update
on public.documents
for each row
execute function private.validate_document_object();

create or replace function private.validate_document_attachment()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_document_owner uuid;
    v_object_owner uuid;
begin
    select o.owner_user_id
      into v_document_owner
      from public.objects o
      join public.documents d on d.id = o.id
     where d.id = new.document_id
       and o.deleted_at is null;

    if not found then
        raise exception 'Document % does not exist or is deleted.', new.document_id
            using errcode = '23503';
    end if;

    select owner_user_id
      into v_object_owner
      from public.objects
     where id = new.object_id
       and deleted_at is null;

    if not found then
        raise exception 'Attachment target object % does not exist or is deleted.',
            new.object_id
            using errcode = '23503';
    end if;

    if v_document_owner <> v_object_owner then
        raise exception 'Document and attachment target must have the same owner.'
            using errcode = '42501';
    end if;

    return new;
end;
$$;

drop trigger if exists trg_document_attachments__validate
on public.document_attachments;

create trigger trg_document_attachments__validate
before insert or update
on public.document_attachments
for each row
execute function private.validate_document_attachment();

create unique index if not exists ux_documents__bucket_storage_path
    on public.documents(bucket_id, storage_path);

create index if not exists ix_documents__type_status
    on public.documents(document_type, document_status);

create index if not exists ix_documents__supersedes
    on public.documents(supersedes_document_id)
    where supersedes_document_id is not null;

create index if not exists ix_documents__primary_active
    on public.documents(document_type, created_at desc)
    where is_primary = true
      and document_status = 'active';

create index if not exists ix_documents__checksum
    on public.documents(checksum_sha256)
    where checksum_sha256 is not null;

create index if not exists ix_document_attachments__object
    on public.document_attachments(object_id, attachment_role, attached_at desc);

create index if not exists ix_document_attachments__document
    on public.document_attachments(document_id, attached_at desc);

create index if not exists ix_document_attachments__primary
    on public.document_attachments(object_id, attachment_role)
    where is_primary = true;

alter table public.documents enable row level security;
alter table public.document_attachments enable row level security;

create policy documents_select_owner
on public.documents
for select to authenticated
using (private.is_object_owner(id));

create policy documents_insert_owner
on public.documents
for insert to authenticated
with check (
    private.is_object_owner(id)
    and (
        supersedes_document_id is null
        or private.is_object_owner(supersedes_document_id)
    )
);

create policy documents_update_owner
on public.documents
for update to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and (
        supersedes_document_id is null
        or private.is_object_owner(supersedes_document_id)
    )
);

create policy documents_delete_owner
on public.documents
for delete to authenticated
using (private.is_object_owner(id));

create policy document_attachments_select_owner
on public.document_attachments
for select to authenticated
using (
    private.is_object_owner(document_id)
    and private.is_object_owner(object_id)
);

create policy document_attachments_insert_owner
on public.document_attachments
for insert to authenticated
with check (
    private.is_object_owner(document_id)
    and private.is_object_owner(object_id)
);

create policy document_attachments_update_owner
on public.document_attachments
for update to authenticated
using (
    private.is_object_owner(document_id)
    and private.is_object_owner(object_id)
)
with check (
    private.is_object_owner(document_id)
    and private.is_object_owner(object_id)
);

create policy document_attachments_delete_owner
on public.document_attachments
for delete to authenticated
using (
    private.is_object_owner(document_id)
    and private.is_object_owner(object_id)
);

revoke all on table public.documents from anon;
revoke all on table public.document_attachments from anon;

grant select, insert, update, delete
on table public.documents
to authenticated;

grant select, insert, update, delete
on table public.document_attachments
to authenticated;

commit;
