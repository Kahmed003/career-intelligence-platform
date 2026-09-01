
/*
Migration ID: 20260721013900
Purpose: Preserve notification failure history and enforce valid lifecycle transitions.
Dependencies: 20260721013800_harden_discovery_provenance.sql
*/
begin;

create or replace function private.validate_notification_transition()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
    if tg_op = 'UPDATE' and new.status is distinct from old.status then
        if old.status in ('acknowledged','dismissed','cancelled') then
            raise exception 'Notification status % is terminal and cannot transition to %.',
                old.status, new.status using errcode = '23514';
        end if;

        if old.status = 'read'
           and new.status not in ('acknowledged','dismissed','cancelled','read') then
            raise exception 'Read notification cannot transition back to %.',
                new.status using errcode = '23514';
        end if;

        if old.status = 'delivered'
           and new.status not in (
               'read','acknowledged','dismissed','failed','cancelled','delivered'
           ) then
            raise exception 'Delivered notification cannot transition to %.',
                new.status using errcode = '23514';
        end if;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_notifications__validate_transition on public.notifications;
create trigger trg_notifications__validate_transition
before update on public.notifications
for each row execute function private.validate_notification_transition();

create or replace function private.validate_notification()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_rule_owner uuid;
    v_source_owner uuid;
    v_parent_owner uuid;
begin
    select o.owner_user_id
      into v_rule_owner
      from public.objects o
      join public.notification_rules r on r.id = o.id
     where r.id = new.notification_rule_id
       and o.deleted_at is null;

    if not found then
        raise exception 'Notification rule % does not exist or is deleted.',
            new.notification_rule_id using errcode = '23503';
    end if;

    if new.source_object_id is not null then
        select owner_user_id into v_source_owner
        from public.objects
        where id = new.source_object_id and deleted_at is null;

        if not found then
            raise exception 'Source object % does not exist or is deleted.',
                new.source_object_id using errcode = '23503';
        end if;

        if v_source_owner <> v_rule_owner then
            raise exception 'Notification source object and rule must share owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.parent_object_id is not null then
        select owner_user_id into v_parent_owner
        from public.objects
        where id = new.parent_object_id and deleted_at is null;

        if not found then
            raise exception 'Parent object % does not exist or is deleted.',
                new.parent_object_id using errcode = '23503';
        end if;

        if v_parent_owner <> v_rule_owner then
            raise exception 'Notification parent object and rule must share owner.'
                using errcode = '42501';
        end if;
    end if;

    new.title := btrim(new.title);
    new.body := btrim(new.body);
    new.dedupe_key := btrim(new.dedupe_key);

    if new.failure_reason is not null then
        new.failure_reason := nullif(btrim(new.failure_reason), '');
    end if;

    if new.status = 'failed' then
        if new.failure_reason is null then
            raise exception 'Failed notifications require failure_reason.'
                using errcode = '23514';
        end if;
        if new.failed_at is null then
            raise exception 'Failed notifications require failed_at.'
                using errcode = '23514';
        end if;
    end if;

    if new.delivered_at is not null and new.delivered_at < new.created_at then
        raise exception 'delivered_at cannot precede created_at.' using errcode='23514';
    end if;
    if new.read_at is not null and new.read_at < new.created_at then
        raise exception 'read_at cannot precede created_at.' using errcode='23514';
    end if;
    if new.acknowledged_at is not null and new.acknowledged_at < new.created_at then
        raise exception 'acknowledged_at cannot precede created_at.' using errcode='23514';
    end if;
    if new.dismissed_at is not null and new.dismissed_at < new.created_at then
        raise exception 'dismissed_at cannot precede created_at.' using errcode='23514';
    end if;
    if new.failed_at is not null and new.failed_at < new.created_at then
        raise exception 'failed_at cannot precede created_at.' using errcode='23514';
    end if;

    return new;
end;
$$;

commit;
