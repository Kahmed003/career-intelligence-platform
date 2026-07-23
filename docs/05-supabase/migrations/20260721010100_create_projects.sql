/*
Migration: 20260721010100_create_projects.sql
Purpose: Create the Projects domain.
*/
begin;

create table if not exists public.projects(
    id uuid
        constraint pk_projects primary key
        references public.objects(id)
        on delete restrict,

    project_code text
        constraint uq_projects__project_code unique,

    summary text,

    target_date date,

    priority smallint
        constraint ck_projects__priority
        check (priority between 1 and 5)
        default 3,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp()
);

comment on table public.projects is
'Domain-specific attributes for project objects.';

create trigger trg_projects__set_updated_at
before update on public.projects
for each row
execute function private.set_updated_at();

create or replace function private.validate_project_object()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
    v_type text;
begin
    select object_type
      into v_type
      from public.objects
     where id=new.id;

    if not found then
        raise exception 'Missing canonical object.';
    end if;

    if v_type <> 'project' then
        raise exception 'Object type must be project.';
    end if;

    return new;
end;
$$;

create trigger trg_projects__validate
before insert or update
on public.projects
for each row
execute function private.validate_project_object();

create index if not exists ix_projects__target_date
on public.projects(target_date);

create index if not exists ix_projects__priority
on public.projects(priority);

alter table public.projects enable row level security;

create policy projects_select_owner
on public.projects
for select
to authenticated
using (private.is_object_owner(id));

create policy projects_insert_owner
on public.projects
for insert
to authenticated
with check (private.is_object_owner(id));

create policy projects_update_owner
on public.projects
for update
to authenticated
using (private.is_object_owner(id))
with check (private.is_object_owner(id));

create policy projects_delete_owner
on public.projects
for delete
to authenticated
using (private.is_object_owner(id));

grant select,insert,update,delete
on public.projects
to authenticated;

commit;
