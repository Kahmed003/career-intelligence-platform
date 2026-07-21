/*
Migration: 20260721000300_create_users_and_profiles.sql
*/
begin;
create schema if not exists private;
create table if not exists public.profiles(
 id uuid constraint pk_profiles primary key references auth.users(id) on delete cascade,
 display_name text,
 email extensions.citext not null unique,
 status public.lifecycle_status not null default 'active',
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create or replace function private.handle_new_user()
returns trigger language plpgsql security definer
set search_path=public,auth,extensions
as $$
begin
 insert into public.profiles(id,email,display_name)
 values(new.id,new.email,coalesce(new.raw_user_meta_data->>'display_name',split_part(new.email,'@',1)))
 on conflict(id) do nothing;
 return new;
end;
$$;
drop trigger if exists trg_auth_user_created on auth.users;
create trigger trg_auth_user_created after insert on auth.users
for each row execute function private.handle_new_user();
commit;
