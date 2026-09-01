
/*
Migration ID: 20260721012900
Purpose: Replace global project-code and organization-domain uniqueness with owner-scoped uniqueness.
*/
begin;

do $migration$
declare
    r record;
begin
    /* Drop UNIQUE constraints/indexes that globally enforce projects.project_code. */
    for r in
        select c.conname
        from pg_catalog.pg_constraint c
        join pg_catalog.pg_class t on t.oid = c.conrelid
        join pg_catalog.pg_namespace n on n.oid = t.relnamespace
        where n.nspname = 'public'
          and t.relname = 'projects'
          and c.contype = 'u'
          and pg_catalog.pg_get_constraintdef(c.oid) ilike '%project_code%'
    loop
        execute format('alter table public.projects drop constraint %I', r.conname);
    end loop;

    /* Drop UNIQUE constraints globally enforcing organizations.primary_domain. */
    for r in
        select c.conname
        from pg_catalog.pg_constraint c
        join pg_catalog.pg_class t on t.oid = c.conrelid
        join pg_catalog.pg_namespace n on n.oid = t.relnamespace
        where n.nspname = 'public'
          and t.relname = 'organizations'
          and c.contype = 'u'
          and pg_catalog.pg_get_constraintdef(c.oid) ilike '%primary_domain%'
    loop
        execute format('alter table public.organizations drop constraint %I', r.conname);
    end loop;
end;
$migration$;


/*
Owner is intentionally stored only on public.objects. PostgreSQL cannot create a
cross-table unique index, so same-owner uniqueness is enforced transactionally
by validation triggers below. For high-concurrency write paths, application
services should serialize creates/renames per owner or a future migration may
denormalize owner_user_id for native unique indexes.
*/


create or replace function private.enforce_owner_scoped_project_code()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_owner uuid;
begin
    if new.project_code is null then return new; end if;

    select owner_user_id into v_owner
    from public.objects
    where id = new.id and deleted_at is null;

    if exists (
        select 1
        from public.projects p
        join public.objects o on o.id = p.id
        where p.id <> new.id
          and o.owner_user_id = v_owner
          and o.deleted_at is null
          and lower(p.project_code) = lower(new.project_code)
    ) then
        raise exception 'Project code % already exists for this owner.', new.project_code
            using errcode = '23505';
    end if;

    return new;
end;
$$;

drop trigger if exists trg_projects__owner_scoped_project_code on public.projects;
create trigger trg_projects__owner_scoped_project_code
before insert or update of project_code on public.projects
for each row execute function private.enforce_owner_scoped_project_code();

create or replace function private.enforce_owner_scoped_organization_domain()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_owner uuid;
begin
    if new.primary_domain is null then return new; end if;

    select owner_user_id into v_owner
    from public.objects
    where id = new.id and deleted_at is null;

    if exists (
        select 1
        from public.organizations org
        join public.objects o on o.id = org.id
        where org.id <> new.id
          and o.owner_user_id = v_owner
          and o.deleted_at is null
          and lower(org.primary_domain) = lower(new.primary_domain)
    ) then
        raise exception 'Organization domain % already exists for this owner.', new.primary_domain
            using errcode = '23505';
    end if;

    return new;
end;
$$;

drop trigger if exists trg_organizations__owner_scoped_primary_domain on public.organizations;
create trigger trg_organizations__owner_scoped_primary_domain
before insert or update of primary_domain on public.organizations
for each row execute function private.enforce_owner_scoped_organization_domain();

commit;
