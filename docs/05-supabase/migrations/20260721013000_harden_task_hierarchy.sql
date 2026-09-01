
/*
Migration ID: 20260721013000
Purpose: Enforce same-owner project/parent references and prevent recursive task cycles.
*/
begin;

create or replace function private.validate_task_hierarchy()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_owner uuid;
    v_ref_owner uuid;
    v_cycle boolean;
begin
    select owner_user_id into v_owner
    from public.objects
    where id = new.id
      and object_type = 'task'
      and deleted_at is null;

    if not found then
        raise exception 'Task canonical object % is missing, deleted, or has wrong type.', new.id
            using errcode = '23503';
    end if;

    if new.project_id is not null then
        select owner_user_id into v_ref_owner
        from public.objects
        where id = new.project_id
          and object_type = 'project'
          and deleted_at is null;

        if not found or v_ref_owner <> v_owner then
            raise exception 'Task project must be an active same-owner project.'
                using errcode = '42501';
        end if;
    end if;

    if new.parent_task_id is not null then
        if new.parent_task_id = new.id then
            raise exception 'Task cannot parent itself.' using errcode = '23514';
        end if;

        select owner_user_id into v_ref_owner
        from public.objects
        where id = new.parent_task_id
          and object_type = 'task'
          and deleted_at is null;

        if not found or v_ref_owner <> v_owner then
            raise exception 'Parent task must be an active same-owner task.'
                using errcode = '42501';
        end if;

        with recursive ancestors(id, parent_task_id) as (
            select t.id, t.parent_task_id
            from public.tasks t
            where t.id = new.parent_task_id
            union all
            select t.id, t.parent_task_id
            from public.tasks t
            join ancestors a on t.id = a.parent_task_id
        )
        select exists (
            select 1 from ancestors where id = new.id
        ) into v_cycle;

        if v_cycle then
            raise exception 'Task hierarchy cycle detected.' using errcode = '23514';
        end if;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_tasks__validate_hierarchy on public.tasks;
create trigger trg_tasks__validate_hierarchy
before insert or update of project_id, parent_task_id
on public.tasks
for each row execute function private.validate_task_hierarchy();

commit;
