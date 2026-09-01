
/*
Migration ID: 20260721013300
Purpose: Enforce at most one active default resume profile and preference profile per owner.
Dependencies: 20260721013200_harden_shared_database_functions.sql
*/
begin;

create or replace function private.enforce_single_default_resume_profile()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare v_owner uuid;
begin
    if new.is_default is distinct from true or new.status <> 'active' then
        return new;
    end if;

    select owner_user_id into v_owner
    from public.objects
    where id=new.id and deleted_at is null;

    if exists (
        select 1
        from public.resume_profiles rp
        join public.objects o on o.id=rp.id
        where rp.id<>new.id
          and rp.is_default=true
          and rp.status='active'
          and o.owner_user_id=v_owner
          and o.deleted_at is null
    ) then
        raise exception 'Only one active default resume profile is allowed per owner.'
            using errcode='23505';
    end if;
    return new;
end;
$$;

drop trigger if exists trg_resume_profiles__single_default on public.resume_profiles;
create trigger trg_resume_profiles__single_default
before insert or update of is_default,status on public.resume_profiles
for each row execute function private.enforce_single_default_resume_profile();

create or replace function private.enforce_single_default_preference_profile()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare v_owner uuid;
begin
    if new.is_default is distinct from true or new.status <> 'active' then
        return new;
    end if;

    select owner_user_id into v_owner
    from public.objects
    where id=new.id and deleted_at is null;

    if exists (
        select 1
        from public.career_preference_profiles cp
        join public.objects o on o.id=cp.id
        where cp.id<>new.id
          and cp.is_default=true
          and cp.status='active'
          and o.owner_user_id=v_owner
          and o.deleted_at is null
    ) then
        raise exception 'Only one active default career preference profile is allowed per owner.'
            using errcode='23505';
    end if;
    return new;
end;
$$;

drop trigger if exists trg_career_preference_profiles__single_default
on public.career_preference_profiles;

create trigger trg_career_preference_profiles__single_default
before insert or update of is_default,status
on public.career_preference_profiles
for each row execute function private.enforce_single_default_preference_profile();

commit;
