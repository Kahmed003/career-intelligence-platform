
begin;

alter table public.resume_content
add column if not exists parent_resume_content_id uuid
references public.resume_content(id)
on update restrict
on delete set null;

alter table public.resume_content
drop constraint if exists ck_resume_content__no_self_parent;

alter table public.resume_content
add constraint ck_resume_content__no_self_parent
check (parent_resume_content_id is null or parent_resume_content_id <> id);

create or replace function private.validate_resume_content_lineage()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_owner uuid;
    v_parent_owner uuid;
    v_parent_type text;
    v_cycle boolean;
begin
    select owner_user_id into v_owner
    from public.objects
    where id = new.id
      and object_type = 'resume_content'
      and deleted_at is null;

    if not found then
        raise exception 'Resume content canonical object % is unavailable.', new.id
            using errcode='23503';
    end if;

    if new.is_master_version = true and new.parent_resume_content_id is not null then
        raise exception 'Master resume content cannot be a child variant.'
            using errcode='23514';
    end if;

    if new.parent_resume_content_id is not null then
        select o.owner_user_id, rc.content_type
          into v_parent_owner, v_parent_type
        from public.resume_content rc
        join public.objects o on o.id = rc.id
        where rc.id = new.parent_resume_content_id
          and o.deleted_at is null;

        if not found then
            raise exception 'Parent resume content % is unavailable.',
                new.parent_resume_content_id using errcode='23503';
        end if;

        if v_parent_owner <> v_owner then
            raise exception 'Resume content lineage must stay within one owner.'
                using errcode='42501';
        end if;

        if v_parent_type <> new.content_type then
            raise exception 'Resume content variant must keep parent content_type.'
                using errcode='23514';
        end if;

        with recursive lineage(id,parent_resume_content_id) as (
            select rc.id, rc.parent_resume_content_id
            from public.resume_content rc
            where rc.id = new.parent_resume_content_id
            union all
            select rc.id, rc.parent_resume_content_id
            from public.resume_content rc
            join lineage l on rc.id = l.parent_resume_content_id
        )
        select exists(select 1 from lineage where id = new.id) into v_cycle;

        if v_cycle then
            raise exception 'Resume content lineage cycle detected.'
                using errcode='23514';
        end if;
    end if;

    if new.is_master_version = true
       and new.content_status not in ('superseded','archived')
       and exists (
            select 1
            from public.resume_content rc
            join public.objects o on o.id = rc.id
            where rc.id <> new.id
              and o.owner_user_id = v_owner
              and o.deleted_at is null
              and rc.is_master_version = true
              and rc.content_status not in ('superseded','archived')
              and rc.content_type = new.content_type
              and rc.source_object_id is not distinct from new.source_object_id
       ) then
        raise exception 'Only one active master resume content record is allowed per owner/content type/source.'
            using errcode='23505';
    end if;

    return new;
end;
$$;

drop trigger if exists trg_resume_content__validate_lineage on public.resume_content;

create trigger trg_resume_content__validate_lineage
before insert or update of parent_resume_content_id,is_master_version,content_type,content_status,source_object_id
on public.resume_content
for each row execute function private.validate_resume_content_lineage();

create index if not exists ix_resume_content__parent
on public.resume_content(parent_resume_content_id)
where parent_resume_content_id is not null;

commit;
