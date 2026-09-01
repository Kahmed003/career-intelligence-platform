
/*
Migration ID: 20260721013200
Purpose: Harden shared authorization/mutation helper functions.
Dependencies: 20260721013100_fix_opportunity_matching_industry.sql
*/
begin;

create or replace function private.current_user_id()
returns uuid
language sql
stable
set search_path = pg_catalog, public
as $$
select auth.uid();
$$;

create or replace function private.is_object_owner(p_object_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
select exists (
    select 1
    from public.objects
    where id = p_object_id
      and owner_user_id = auth.uid()
      and deleted_at is null
);
$$;

create or replace function private.assert_object_owner(p_object_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
    if not private.is_object_owner(p_object_id) then
        raise exception 'User does not own active object %.', p_object_id
            using errcode = '42501';
    end if;
end;
$$;

create or replace function private.touch_object(p_object_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
    perform private.assert_object_owner(p_object_id);

    update public.objects
       set updated_at = statement_timestamp()
     where id = p_object_id
       and deleted_at is null;
end;
$$;

create or replace function private.soft_delete_object(p_object_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
    perform private.assert_object_owner(p_object_id);

    update public.objects
       set deleted_at = statement_timestamp(),
           updated_at = statement_timestamp()
     where id = p_object_id
       and deleted_at is null;
end;
$$;

revoke all on function private.current_user_id() from public, anon;
revoke all on function private.is_object_owner(uuid) from public, anon;
revoke all on function private.assert_object_owner(uuid) from public, anon;
revoke all on function private.touch_object(uuid) from public, anon;
revoke all on function private.soft_delete_object(uuid) from public, anon;

grant execute on function private.current_user_id() to authenticated;
grant execute on function private.is_object_owner(uuid) to authenticated;
grant execute on function private.assert_object_owner(uuid) to authenticated;
grant execute on function private.touch_object(uuid) to authenticated;
grant execute on function private.soft_delete_object(uuid) to authenticated;

commit;
