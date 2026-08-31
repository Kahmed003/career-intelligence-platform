
/*
Migration: 20260721011400_create_interactions_and_communications.sql
Purpose: Create networking, recruiting, mentorship, and communication history.
*/
begin;

create table if not exists public.interactions_communications (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    interaction_type text not null
        check (
            interaction_type in (
                'email',
                'linkedin_message',
                'phone_call',
                'video_call',
                'coffee_chat',
                'in_person_meeting',
                'informational_interview',
                'recruiter_conversation',
                'mentor_meeting',
                'conference_conversation',
                'career_fair',
                'follow_up',
                'other'
            )
        ),

    direction text not null default 'mutual'
        check (
            direction in (
                'outbound',
                'inbound',
                'mutual'
            )
        ),

    status text not null default 'planned'
        check (
            status in (
                'planned',
                'sent',
                'delivered',
                'completed',
                'cancelled',
                'no_response',
                'rescheduled'
            )
        ),

    person_id uuid
        references public.people(id)
        on update restrict
        on delete set null,

    organization_id uuid
        references public.organizations(id)
        on update restrict
        on delete set null,

    application_id uuid
        references public.applications(id)
        on update restrict
        on delete set null,

    opportunity_id uuid
        references public.opportunities(id)
        on update restrict
        on delete set null,

    occurred_at timestamptz,
    scheduled_for timestamptz,

    duration_minutes integer
        check (
            duration_minutes is null
            or duration_minutes >= 0
        ),

    subject text
        check (
            subject is null
            or length(btrim(subject)) > 0
        ),

    summary text
        check (
            summary is null
            or length(btrim(summary)) > 0
        ),

    channel_detail text
        check (
            channel_detail is null
            or length(btrim(channel_detail)) > 0
        ),

    outcome text not null default 'none'
        check (
            outcome in (
                'none',
                'awaiting_response',
                'responded',
                'connected',
                'meeting_scheduled',
                'referral_offered',
                'referral_received',
                'application_guidance',
                'relationship_advanced',
                'no_response',
                'closed',
                'other'
            )
        ),

    follow_up_required boolean not null default false,
    follow_up_at timestamptz,
    response_received_at timestamptz,

    external_message_id text
        check (
            external_message_id is null
            or length(btrim(external_message_id)) > 0
        ),

    source_system text
        check (
            source_system is null
            or length(btrim(source_system)) > 0
        ),

    metadata jsonb not null default '{}'::jsonb
        check (jsonb_typeof(metadata) = 'object'),

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_interactions_communications__follow_up_flag
        check (
            follow_up_at is null
            or follow_up_required = true
        ),

    constraint ck_interactions_communications__completed_time
        check (
            status <> 'completed'
            or occurred_at is not null
        ),

    constraint ck_interactions_communications__response_time
        check (
            response_received_at is null
            or occurred_at is null
            or response_received_at >= occurred_at
        )
);

comment on table public.interactions_communications is
'Networking, recruiting, mentorship, meeting, and communication history for Career OS.';

drop trigger if exists trg_interactions_communications__set_updated_at
on public.interactions_communications;

create trigger trg_interactions_communications__set_updated_at
before update on public.interactions_communications
for each row
execute function private.set_updated_at();

create or replace function private.validate_interaction_communication_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_linked_owner uuid;
    v_application_opportunity uuid;
    v_application_org uuid;
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

    if v_type <> 'interaction' then
        raise exception 'Object % must have object_type interaction.', new.id
            using errcode = '23514';
    end if;

    if new.person_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.person_id
           and object_type = 'person'
           and deleted_at is null;

        if not found then
            raise exception 'Person % does not exist or is deleted.', new.person_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Interaction and person must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.organization_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.organization_id
           and object_type = 'organization'
           and deleted_at is null;

        if not found then
            raise exception 'Organization % does not exist or is deleted.', new.organization_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Interaction and organization must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.opportunity_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.opportunity_id
           and object_type = 'opportunity'
           and deleted_at is null;

        if not found then
            raise exception 'Opportunity % does not exist or is deleted.', new.opportunity_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Interaction and opportunity must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.application_id is not null then
        select o.owner_user_id, a.opportunity_id, a.organization_id
          into v_linked_owner, v_application_opportunity, v_application_org
          from public.objects o
          join public.applications a on a.id = o.id
         where a.id = new.application_id
           and o.deleted_at is null;

        if not found then
            raise exception 'Application % does not exist or is deleted.', new.application_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Interaction and application must have the same owner.'
                using errcode = '42501';
        end if;

        if new.opportunity_id is not null
           and v_application_opportunity <> new.opportunity_id then
            raise exception 'Interaction opportunity must match application opportunity.'
                using errcode = '23514';
        end if;

        if new.organization_id is not null
           and v_application_org is not null
           and v_application_org <> new.organization_id then
            raise exception 'Interaction organization must match application organization.'
                using errcode = '23514';
        end if;

        if new.opportunity_id is null then
            new.opportunity_id := v_application_opportunity;
        end if;

        if new.organization_id is null and v_application_org is not null then
            new.organization_id := v_application_org;
        end if;
    end if;

    if new.subject is not null then
        new.subject := btrim(new.subject);
    end if;

    if new.summary is not null then
        new.summary := btrim(new.summary);
    end if;

    if new.channel_detail is not null then
        new.channel_detail := btrim(new.channel_detail);
    end if;

    if new.external_message_id is not null then
        new.external_message_id := btrim(new.external_message_id);
    end if;

    if new.source_system is not null then
        new.source_system := lower(btrim(new.source_system));
    end if;

    return new;
end;
$$;

drop trigger if exists trg_interactions_communications__validate
on public.interactions_communications;

create trigger trg_interactions_communications__validate
before insert or update
on public.interactions_communications
for each row
execute function private.validate_interaction_communication_object();

create index if not exists ix_interactions_communications__person_time
    on public.interactions_communications(person_id, coalesce(occurred_at, scheduled_for) desc)
    where person_id is not null;

create index if not exists ix_interactions_communications__organization_time
    on public.interactions_communications(organization_id, coalesce(occurred_at, scheduled_for) desc)
    where organization_id is not null;

create index if not exists ix_interactions_communications__application
    on public.interactions_communications(application_id, created_at desc)
    where application_id is not null;

create index if not exists ix_interactions_communications__opportunity
    on public.interactions_communications(opportunity_id, created_at desc)
    where opportunity_id is not null;

create index if not exists ix_interactions_communications__scheduled
    on public.interactions_communications(scheduled_for)
    where scheduled_for is not null
      and status in ('planned', 'rescheduled');

create index if not exists ix_interactions_communications__follow_up
    on public.interactions_communications(follow_up_at)
    where follow_up_required = true
      and follow_up_at is not null
      and status not in ('cancelled');

create index if not exists ix_interactions_communications__awaiting_response
    on public.interactions_communications(occurred_at desc)
    where direction = 'outbound'
      and outcome = 'awaiting_response'
      and response_received_at is null;

create index if not exists ix_interactions_communications__source_message
    on public.interactions_communications(source_system, external_message_id)
    where source_system is not null
      and external_message_id is not null;

create index if not exists ix_interactions_communications__type_status
    on public.interactions_communications(interaction_type, status);

alter table public.interactions_communications enable row level security;

create policy interactions_communications_select_owner
on public.interactions_communications
for select to authenticated
using (private.is_object_owner(id));

create policy interactions_communications_insert_owner
on public.interactions_communications
for insert to authenticated
with check (
    private.is_object_owner(id)
    and (person_id is null or private.is_object_owner(person_id))
    and (organization_id is null or private.is_object_owner(organization_id))
    and (application_id is null or private.is_object_owner(application_id))
    and (opportunity_id is null or private.is_object_owner(opportunity_id))
);

create policy interactions_communications_update_owner
on public.interactions_communications
for update to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and (person_id is null or private.is_object_owner(person_id))
    and (organization_id is null or private.is_object_owner(organization_id))
    and (application_id is null or private.is_object_owner(application_id))
    and (opportunity_id is null or private.is_object_owner(opportunity_id))
);

create policy interactions_communications_delete_owner
on public.interactions_communications
for delete to authenticated
using (private.is_object_owner(id));

revoke all on table public.interactions_communications from anon;

grant select, insert, update, delete
on table public.interactions_communications
to authenticated;

commit;
