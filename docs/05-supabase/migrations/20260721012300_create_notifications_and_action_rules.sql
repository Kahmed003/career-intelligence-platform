
/*
Migration: 20260721012300_create_notifications_and_action_rules.sql
Purpose: Create governed notification rules and generated notification records.
*/
begin;

create table if not exists public.notification_rules (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    name text not null
        check (length(btrim(name)) > 0),

    status text not null default 'draft'
        check (
            status in (
                'draft',
                'active',
                'paused',
                'archived'
            )
        ),

    source_type text not null default 'other'
        check (
            source_type in (
                'opportunity',
                'application',
                'interview',
                'assessment',
                'offer',
                'interaction',
                'task',
                'other'
            )
        ),

    action_type text
        check (
            action_type is null
            or action_type in (
                'application_deadline',
                'application_next_action',
                'scheduled_interview',
                'scheduled_assessment',
                'assessment_deadline',
                'offer_decision',
                'networking_follow_up',
                'task_due',
                'other'
            )
        ),

    urgency_filter text not null default 'any'
        check (
            urgency_filter in (
                'overdue',
                'today',
                'next_3_days',
                'next_7_days',
                'later',
                'any'
            )
        ),

    priority_max smallint
        check (
            priority_max is null
            or priority_max between 1 and 5
        ),

    lead_time_minutes integer not null default 0
        check (lead_time_minutes >= 0),

    repeat_interval_minutes integer
        check (
            repeat_interval_minutes is null
            or repeat_interval_minutes > 0
        ),

    channel text not null default 'in_app'
        check (
            channel in (
                'in_app',
                'email',
                'push',
                'sms',
                'webhook',
                'other'
            )
        ),

    is_digest boolean not null default false,

    quiet_hours_behavior text not null default 'defer'
        check (
            quiet_hours_behavior in (
                'defer',
                'deliver',
                'suppress'
            )
        ),

    metadata jsonb not null default '{}'::jsonb
        check (jsonb_typeof(metadata) = 'object'),

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp()
);

comment on table public.notification_rules is
'User-owned rules that define when and how deadline intelligence should generate reminders.';

create table if not exists public.notifications (
    id uuid primary key default gen_random_uuid(),

    notification_rule_id uuid not null
        references public.notification_rules(id)
        on update restrict
        on delete cascade,

    source_object_id uuid
        references public.objects(id)
        on update restrict
        on delete set null,

    parent_object_id uuid
        references public.objects(id)
        on update restrict
        on delete set null,

    source_type text not null
        check (
            source_type in (
                'opportunity',
                'application',
                'interview',
                'assessment',
                'offer',
                'interaction',
                'task',
                'other'
            )
        ),

    action_type text not null
        check (
            action_type in (
                'application_deadline',
                'application_next_action',
                'scheduled_interview',
                'scheduled_assessment',
                'assessment_deadline',
                'offer_decision',
                'networking_follow_up',
                'task_due',
                'other'
            )
        ),

    title text not null
        check (length(btrim(title)) > 0),

    body text not null
        check (length(btrim(body)) > 0),

    scheduled_for timestamptz not null,

    status text not null default 'pending'
        check (
            status in (
                'pending',
                'scheduled',
                'delivered',
                'read',
                'acknowledged',
                'dismissed',
                'failed',
                'cancelled'
            )
        ),

    channel text not null
        check (
            channel in (
                'in_app',
                'email',
                'push',
                'sms',
                'webhook',
                'other'
            )
        ),

    dedupe_key text not null
        check (length(btrim(dedupe_key)) > 0),

    delivered_at timestamptz,
    read_at timestamptz,
    acknowledged_at timestamptz,
    dismissed_at timestamptz,
    failed_at timestamptz,

    failure_reason text,

    metadata jsonb not null default '{}'::jsonb
        check (jsonb_typeof(metadata) = 'object'),

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_notifications__delivered_state
        check (
            status not in ('delivered', 'read', 'acknowledged')
            or delivered_at is not null
        ),

    constraint ck_notifications__read_state
        check (
            status <> 'read'
            or read_at is not null
        ),

    constraint ck_notifications__acknowledged_state
        check (
            status <> 'acknowledged'
            or acknowledged_at is not null
        ),

    constraint ck_notifications__dismissed_state
        check (
            status <> 'dismissed'
            or dismissed_at is not null
        ),

    constraint ck_notifications__failed_state
        check (
            status <> 'failed'
            or failed_at is not null
        )
);

comment on table public.notifications is
'Generated reminder and notification ledger with source provenance and delivery state.';

drop trigger if exists trg_notification_rules__set_updated_at
on public.notification_rules;

create trigger trg_notification_rules__set_updated_at
before update on public.notification_rules
for each row execute function private.set_updated_at();

drop trigger if exists trg_notifications__set_updated_at
on public.notifications;

create trigger trg_notifications__set_updated_at
before update on public.notifications
for each row execute function private.set_updated_at();

create or replace function private.validate_notification_rule()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
begin
    select object_type
      into v_type
      from public.objects
     where id = new.id
       and deleted_at is null;

    if not found then
        raise exception 'Canonical object % does not exist or is deleted.', new.id
            using errcode = '23503';
    end if;

    if v_type <> 'notification_rule' then
        raise exception 'Object % must have object_type notification_rule.', new.id
            using errcode = '23514';
    end if;

    new.name := btrim(new.name);

    return new;
end;
$$;

drop trigger if exists trg_notification_rules__validate
on public.notification_rules;

create trigger trg_notification_rules__validate
before insert or update on public.notification_rules
for each row execute function private.validate_notification_rule();

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
            new.notification_rule_id
            using errcode = '23503';
    end if;

    if new.source_object_id is not null then
        select owner_user_id
          into v_source_owner
          from public.objects
         where id = new.source_object_id
           and deleted_at is null;

        if not found then
            raise exception 'Source object % does not exist or is deleted.',
                new.source_object_id
                using errcode = '23503';
        end if;

        if v_source_owner <> v_rule_owner then
            raise exception 'Notification source object and rule must share owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.parent_object_id is not null then
        select owner_user_id
          into v_parent_owner
          from public.objects
         where id = new.parent_object_id
           and deleted_at is null;

        if not found then
            raise exception 'Parent object % does not exist or is deleted.',
                new.parent_object_id
                using errcode = '23503';
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
        new.failure_reason := btrim(new.failure_reason);
        if new.failure_reason = '' then
            new.failure_reason := null;
        end if;
    end if;

    if new.status = 'failed'
       and new.failure_reason is null then
        raise exception 'Failed notifications require failure_reason.'
            using errcode = '23514';
    end if;

    if new.status <> 'failed'
       and new.failure_reason is not null then
        raise exception 'failure_reason is only valid for failed notifications.'
            using errcode = '23514';
    end if;

    if new.delivered_at is not null and new.delivered_at < new.created_at then
        raise exception 'delivered_at cannot precede created_at.'
            using errcode = '23514';
    end if;

    if new.read_at is not null and new.read_at < new.created_at then
        raise exception 'read_at cannot precede created_at.'
            using errcode = '23514';
    end if;

    if new.acknowledged_at is not null and new.acknowledged_at < new.created_at then
        raise exception 'acknowledged_at cannot precede created_at.'
            using errcode = '23514';
    end if;

    if new.dismissed_at is not null and new.dismissed_at < new.created_at then
        raise exception 'dismissed_at cannot precede created_at.'
            using errcode = '23514';
    end if;

    if new.failed_at is not null and new.failed_at < new.created_at then
        raise exception 'failed_at cannot precede created_at.'
            using errcode = '23514';
    end if;

    return new;
end;
$$;

drop trigger if exists trg_notifications__validate
on public.notifications;

create trigger trg_notifications__validate
before insert or update on public.notifications
for each row execute function private.validate_notification();

create unique index if not exists ux_notifications__rule_dedupe
    on public.notifications(notification_rule_id, dedupe_key);

create index if not exists ix_notification_rules__active_source
    on public.notification_rules(source_type, action_type, urgency_filter)
    where status = 'active';

create index if not exists ix_notification_rules__active_channel
    on public.notification_rules(channel)
    where status = 'active';

create index if not exists ix_notifications__pending_schedule
    on public.notifications(scheduled_for)
    where status in ('pending', 'scheduled');

create index if not exists ix_notifications__rule_status
    on public.notifications(notification_rule_id, status, scheduled_for desc);

create index if not exists ix_notifications__source_object
    on public.notifications(source_object_id, created_at desc)
    where source_object_id is not null;

create index if not exists ix_notifications__unread
    on public.notifications(scheduled_for desc)
    where status in ('delivered', 'read');

create index if not exists ix_notifications__failed
    on public.notifications(failed_at desc)
    where status = 'failed';

alter table public.notification_rules enable row level security;
alter table public.notifications enable row level security;

create policy notification_rules_owner_all
on public.notification_rules
for all to authenticated
using (private.is_object_owner(id))
with check (private.is_object_owner(id));

create policy notifications_owner_all
on public.notifications
for all to authenticated
using (private.is_object_owner(notification_rule_id))
with check (
    private.is_object_owner(notification_rule_id)
    and (
        source_object_id is null
        or private.is_object_owner(source_object_id)
    )
    and (
        parent_object_id is null
        or private.is_object_owner(parent_object_id)
    )
);

revoke all on public.notification_rules from anon;
revoke all on public.notifications from anon;

grant select, insert, update, delete
on public.notification_rules
to authenticated;

grant select, insert, update, delete
on public.notifications
to authenticated;

commit;
