/*
Migration: 20260721000800_create_shared_database_functions.sql
Purpose: Shared authorization and utility functions.
*/
begin;

create schema if not exists private;

create or replace function private.current_user_id()
returns uuid
language sql
stable
as $$
select auth.uid();
$$;

create or replace function private.is_object_owner(p_object_id uuid)
returns boolean
language sql
stable
security definer
set search_path=public
as $$
select exists(
 select 1
 from public.objects
 where id=p_object_id
   and owner_user_id=auth.uid()
   and deleted_at is null
);
$$;

create or replace function private.assert_object_owner(p_object_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
 if not private.is_object_owner(p_object_id) then
   raise exception 'User does not own object.'
   using errcode='42501';
 end if;
end;
$$;

create or replace function private.touch_object(p_object_id uuid)
returns void
language sql
security definer
set search_path=public
as $$
update public.objects
set updated_at=statement_timestamp()
where id=p_object_id;
$$;

create or replace function private.soft_delete_object(p_object_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
 perform private.assert_object_owner(p_object_id);
 update public.objects
 set deleted_at=statement_timestamp(),
     updated_at=statement_timestamp()
 where id=p_object_id
   and deleted_at is null;
end;
$$;

comment on function private.current_user_id() is 'Returns the authenticated user UUID.';
comment on function private.is_object_owner(uuid) is 'Returns true if auth.uid() owns the object.';
comment on function private.assert_object_owner(uuid) is 'Raises if authenticated user does not own the object.';
comment on function private.touch_object(uuid) is 'Updates object updated_at timestamp.';
comment on function private.soft_delete_object(uuid) is 'Performs canonical soft deletion of an object.';

commit;
