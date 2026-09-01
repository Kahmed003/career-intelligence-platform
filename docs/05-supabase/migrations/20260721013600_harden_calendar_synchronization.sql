
/*
Migration ID: 20260721013600
Purpose: Harden calendar timezone and external synchronization integrity.
Dependencies: 20260721013500_harden_interaction_consistency.sql
*/
begin;

create or replace function private.validate_calendar_event()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_linked_owner uuid;
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

    if v_type <> 'calendar_event' then
        raise exception 'Object % must have object_type calendar_event.', new.id
            using errcode = '23514';
    end if;

    if new.source_object_id is not null then
        select owner_user_id into v_linked_owner
        from public.objects
        where id = new.source_object_id and deleted_at is null;

        if not found then
            raise exception 'Source object % does not exist or is deleted.', new.source_object_id
                using errcode = '23503';
        end if;
        if v_linked_owner <> v_owner then
            raise exception 'Calendar event and source object must share owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.parent_object_id is not null then
        select owner_user_id into v_linked_owner
        from public.objects
        where id = new.parent_object_id and deleted_at is null;

        if not found then
            raise exception 'Parent object % does not exist or is deleted.', new.parent_object_id
                using errcode = '23503';
        end if;
        if v_linked_owner <> v_owner then
            raise exception 'Calendar event and parent object must share owner.'
                using errcode = '42501';
        end if;
    end if;

    new.title := btrim(new.title);

    if new.timezone is not null then
        new.timezone := nullif(btrim(new.timezone), '');
    end if;

    if new.all_day = false then
        if new.timezone is null then
            raise exception 'Timed calendar event requires timezone.'
                using errcode = '23514';
        end if;

        if not exists (
            select 1
            from pg_catalog.pg_timezone_names
            where name = new.timezone
        ) then
            raise exception 'Unknown PostgreSQL/IANA timezone: %.', new.timezone
                using errcode = '23514';
        end if;
    elsif new.timezone is not null and not exists (
        select 1 from pg_catalog.pg_timezone_names where name = new.timezone
    ) then
        raise exception 'Unknown PostgreSQL/IANA timezone: %.', new.timezone
            using errcode = '23514';
    end if;

    if new.location_text is not null then
        new.location_text := nullif(btrim(new.location_text), '');
    end if;

    if new.recurrence_rule is not null then
        new.recurrence_rule := nullif(btrim(new.recurrence_rule), '');
    end if;

    return new;
end;
$$;

drop index if exists public.ux_external_calendar_links__provider_event;

do $migration$
begin
    if exists (
        select 1
        from public.external_calendar_links
        group by calendar_event_id, provider, external_calendar_id
        having count(*) > 1
    ) then
        raise exception
            'Duplicate external calendar links exist for the same Career OS event/provider/calendar.'
            using errcode = '23505';
    end if;
end;
$migration$;

create unique index if not exists ux_external_calendar_links__event_provider_calendar
on public.external_calendar_links(calendar_event_id, provider, external_calendar_id);

create or replace function private.validate_external_calendar_link()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_event_owner uuid;
begin
    select o.owner_user_id
      into v_event_owner
      from public.objects o
      join public.calendar_events ce on ce.id = o.id
     where ce.id = new.calendar_event_id
       and o.deleted_at is null;

    if not found then
        raise exception 'Calendar event % does not exist or is deleted.',
            new.calendar_event_id using errcode = '23503';
    end if;

    new.external_calendar_id := btrim(new.external_calendar_id);
    new.external_event_id := btrim(new.external_event_id);

    if new.etag is not null then
        new.etag := nullif(btrim(new.etag), '');
    end if;

    if new.sync_error is not null then
        new.sync_error := nullif(btrim(new.sync_error), '');
    end if;

    if new.sync_status = 'failed' and new.sync_error is null then
        raise exception 'Failed calendar sync requires sync_error.'
            using errcode = '23514';
    end if;

    /*
    External provider identifiers are only unique within the owner's calendar
    namespace. This trigger avoids the original cross-user global uniqueness.
    */
    if exists (
        select 1
        from public.external_calendar_links ecl
        join public.objects eo on eo.id = ecl.calendar_event_id
        where ecl.id <> new.id
          and eo.owner_user_id = v_event_owner
          and eo.deleted_at is null
          and ecl.provider = new.provider
          and ecl.external_calendar_id = new.external_calendar_id
          and ecl.external_event_id = new.external_event_id
    ) then
        raise exception 'External calendar event is already linked for this owner.'
            using errcode = '23505';
    end if;

    return new;
end;
$$;

commit;
