
/*
Migration ID: 20260721013400
Purpose: Harden document primary-link and version-chain integrity.
Dependencies: 20260721013300_enforce_single_default_profiles.sql
*/
begin;

do $migration$
begin
    if exists (
        select 1
        from public.document_attachments
        where is_primary = true
        group by object_id, attachment_role
        having count(*) > 1
    ) then
        raise exception
            'Cannot enforce primary attachment uniqueness: duplicate primary links exist. Resolve duplicates first.'
            using errcode = '23505';
    end if;
end;
$migration$;

create unique index if not exists ux_document_attachments__one_primary_per_role
    on public.document_attachments(object_id, attachment_role)
    where is_primary = true;

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
    v_supersedes_type text;
    v_supersedes_version integer;
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
        new.display_filename := nullif(btrim(new.display_filename), '');
    end if;

    if new.mime_type is not null then
        new.mime_type := nullif(lower(btrim(new.mime_type)), '');
    end if;

    if new.file_extension is not null then
        new.file_extension := nullif(lower(btrim(new.file_extension)), '');
    end if;

    if new.checksum_sha256 is not null then
        new.checksum_sha256 := nullif(lower(btrim(new.checksum_sha256)), '');
    end if;

    if new.source_name is not null then
        new.source_name := nullif(btrim(new.source_name), '');
    end if;

    v_owner_prefix := v_owner::text || '/';

    if left(new.storage_path, length(v_owner_prefix)) <> v_owner_prefix then
        raise exception 'Document storage path must begin with owner UUID %.', v_owner
            using errcode = '23514';
    end if;

    if new.supersedes_document_id is not null then
        select o.owner_user_id, d.document_type, d.version_number
          into v_supersedes_owner, v_supersedes_type, v_supersedes_version
          from public.documents d
          join public.objects o on o.id = d.id
         where d.id = new.supersedes_document_id
           and o.object_type = 'document'
           and o.deleted_at is null;

        if not found then
            raise exception 'Superseded document % does not exist or is deleted.',
                new.supersedes_document_id
                using errcode = '23503';
        end if;

        if v_supersedes_owner <> v_owner then
            raise exception 'Document versions must have the same owner.'
                using errcode = '42501';
        end if;

        if v_supersedes_type <> new.document_type then
            raise exception 'A document may supersede only the same document_type.'
                using errcode = '23514';
        end if;

        if new.version_number <= v_supersedes_version then
            raise exception
                'Document version % must exceed superseded version %.',
                new.version_number, v_supersedes_version
                using errcode = '23514';
        end if;
    end if;

    return new;
end;
$$;

commit;
