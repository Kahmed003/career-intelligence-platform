
/*
Migration: 20260721011900_create_pipeline_and_deadline_intelligence.sql
Purpose: Create derived owner-scoped pipeline and deadline intelligence views.
*/
begin;

drop view if exists public.pipeline_application_summary;
drop view if exists public.pipeline_deadline_items;

create view public.pipeline_deadline_items
with (security_invoker = true)
as

/* Opportunity application deadlines */
select
    o.owner_user_id,
    'opportunity'::text as source_type,
    op.id as source_object_id,
    null::uuid as parent_object_id,
    o.title,
    op.status as item_status,
    'application_deadline'::text as action_type,
    op.application_deadline_at as due_at,
    op.priority,
    case
        when op.application_deadline_at < current_date then 'overdue'
        when op.application_deadline_at < current_date + interval '1 day' then 'today'
        when op.application_deadline_at < current_date + interval '4 days' then 'next_3_days'
        when op.application_deadline_at < current_date + interval '8 days' then 'next_7_days'
        else 'later'
    end::text as urgency,
    op.organization_id,
    null::uuid as application_id,
    op.id as opportunity_id,
    null::uuid as person_id,
    jsonb_build_object(
        'opportunity_type', op.opportunity_type,
        'work_mode', op.work_mode,
        'fit_score', op.fit_score
    ) as metadata
from public.opportunities op
join public.objects o on o.id = op.id
where o.deleted_at is null
  and op.application_deadline_at is not null
  and op.status in ('discovered', 'researching', 'qualified', 'pursuing')

union all

/* Application next actions */
select
    o.owner_user_id,
    'application'::text,
    a.id,
    a.opportunity_id,
    o.title,
    a.status,
    'application_next_action'::text,
    a.next_action_at,
    a.priority,
    case
        when a.next_action_at < current_date then 'overdue'
        when a.next_action_at < current_date + interval '1 day' then 'today'
        when a.next_action_at < current_date + interval '4 days' then 'next_3_days'
        when a.next_action_at < current_date + interval '8 days' then 'next_7_days'
        else 'later'
    end::text,
    a.organization_id,
    a.id,
    a.opportunity_id,
    coalesce(a.recruiter_person_id, a.referral_person_id),
    jsonb_build_object(
        'application_method', a.application_method,
        'fit_score', a.fit_score,
        'outcome', a.outcome
    )
from public.applications a
join public.objects o on o.id = a.id
where o.deleted_at is null
  and a.next_action_at is not null
  and a.status not in ('accepted', 'rejected', 'withdrawn', 'closed')

union all

/* Scheduled interviews / assessments */
select
    o.owner_user_id,
    ia.event_kind::text,
    ia.id,
    ia.application_id,
    o.title,
    ia.status,
    case
        when ia.event_kind = 'interview' then 'scheduled_interview'
        else 'scheduled_assessment'
    end::text,
    ia.scheduled_start_at,
    null::smallint,
    case
        when ia.scheduled_start_at < current_date then 'overdue'
        when ia.scheduled_start_at < current_date + interval '1 day' then 'today'
        when ia.scheduled_start_at < current_date + interval '4 days' then 'next_3_days'
        when ia.scheduled_start_at < current_date + interval '8 days' then 'next_7_days'
        else 'later'
    end::text,
    a.organization_id,
    ia.application_id,
    a.opportunity_id,
    ia.primary_interviewer_person_id,
    jsonb_build_object(
        'round_number', ia.round_number,
        'stage_name', ia.stage_name,
        'interview_type', ia.interview_type,
        'assessment_type', ia.assessment_type
    )
from public.interviews_assessments ia
join public.objects o on o.id = ia.id
join public.applications a on a.id = ia.application_id
where o.deleted_at is null
  and ia.scheduled_start_at is not null
  and ia.status in ('planned', 'scheduled', 'in_progress')

union all

/* Assessment deadlines that may differ from scheduled start */
select
    o.owner_user_id,
    'assessment'::text,
    ia.id,
    ia.application_id,
    o.title,
    ia.status,
    'assessment_deadline'::text,
    ia.deadline_at,
    null::smallint,
    case
        when ia.deadline_at < current_date then 'overdue'
        when ia.deadline_at < current_date + interval '1 day' then 'today'
        when ia.deadline_at < current_date + interval '4 days' then 'next_3_days'
        when ia.deadline_at < current_date + interval '8 days' then 'next_7_days'
        else 'later'
    end::text,
    a.organization_id,
    ia.application_id,
    a.opportunity_id,
    ia.primary_interviewer_person_id,
    jsonb_build_object(
        'assessment_type', ia.assessment_type,
        'stage_name', ia.stage_name
    )
from public.interviews_assessments ia
join public.objects o on o.id = ia.id
join public.applications a on a.id = ia.application_id
where o.deleted_at is null
  and ia.event_kind = 'assessment'
  and ia.deadline_at is not null
  and ia.status in ('planned', 'scheduled', 'in_progress')

union all

/* Offer decision deadlines */
select
    o.owner_user_id,
    'offer'::text,
    off.id,
    off.application_id,
    o.title,
    off.status,
    'offer_decision'::text,
    off.decision_deadline_at,
    null::smallint,
    case
        when off.decision_deadline_at < current_date then 'overdue'
        when off.decision_deadline_at < current_date + interval '1 day' then 'today'
        when off.decision_deadline_at < current_date + interval '4 days' then 'next_3_days'
        when off.decision_deadline_at < current_date + interval '8 days' then 'next_7_days'
        else 'later'
    end::text,
    off.organization_id,
    off.application_id,
    a.opportunity_id,
    null::uuid,
    jsonb_build_object(
        'negotiation_status', off.negotiation_status,
        'comparison_score', off.comparison_score,
        'decision', off.decision
    )
from public.offers off
join public.objects o on o.id = off.id
join public.applications a on a.id = off.application_id
where o.deleted_at is null
  and off.decision_deadline_at is not null
  and off.status in ('received', 'reviewing', 'negotiating')

union all

/* Networking follow-ups */
select
    o.owner_user_id,
    'interaction'::text,
    ic.id,
    coalesce(ic.application_id, ic.opportunity_id),
    o.title,
    ic.status,
    'networking_follow_up'::text,
    ic.follow_up_at,
    null::smallint,
    case
        when ic.follow_up_at < current_date then 'overdue'
        when ic.follow_up_at < current_date + interval '1 day' then 'today'
        when ic.follow_up_at < current_date + interval '4 days' then 'next_3_days'
        when ic.follow_up_at < current_date + interval '8 days' then 'next_7_days'
        else 'later'
    end::text,
    ic.organization_id,
    ic.application_id,
    ic.opportunity_id,
    ic.person_id,
    jsonb_build_object(
        'interaction_type', ic.interaction_type,
        'direction', ic.direction,
        'outcome', ic.outcome
    )
from public.interactions_communications ic
join public.objects o on o.id = ic.id
where o.deleted_at is null
  and ic.follow_up_required = true
  and ic.follow_up_at is not null
  and ic.status <> 'cancelled'

union all

/* Task deadlines */
select
    o.owner_user_id,
    'task'::text,
    t.id,
    t.project_id,
    o.title,
    case
        when t.completed_at is not null then 'completed'
        else 'open'
    end::text,
    'task_due'::text,
    t.due_date::timestamptz,
    t.priority,
    case
        when t.due_date < current_date then 'overdue'
        when t.due_date = current_date then 'today'
        when t.due_date <= current_date + 3 then 'next_3_days'
        when t.due_date <= current_date + 7 then 'next_7_days'
        else 'later'
    end::text,
    null::uuid,
    null::uuid,
    null::uuid,
    null::uuid,
    jsonb_build_object(
        'project_id', t.project_id,
        'estimated_minutes', t.estimated_minutes
    )
from public.tasks t
join public.objects o on o.id = t.id
where o.deleted_at is null
  and t.due_date is not null
  and t.completed_at is null;

comment on view public.pipeline_deadline_items is
'Normalized owner-scoped operational queue across opportunities, applications, interviews, offers, networking follow-ups, and tasks.';

create view public.pipeline_application_summary
with (security_invoker = true)
as
select
    app_obj.owner_user_id,
    a.id as application_id,
    app_obj.title as application_title,
    a.status as application_status,
    a.priority,
    a.fit_score,
    a.submitted_at,
    a.next_action_at,

    op.id as opportunity_id,
    op_obj.title as opportunity_title,
    op.opportunity_type,
    op.application_deadline_at,

    org.id as organization_id,
    org.legal_name as organization_name,

    next_event.id as next_interview_assessment_id,
    next_event.event_kind as next_event_kind,
    next_event.scheduled_start_at as next_event_at,
    next_event.deadline_at as next_event_deadline_at,

    latest_offer.id as offer_id,
    latest_offer.status as offer_status,
    latest_offer.decision_deadline_at as offer_decision_deadline_at,
    latest_offer.comparison_score as offer_comparison_score,

    (
        select count(*)::integer
        from public.interviews_assessments ia_count
        join public.objects ia_obj on ia_obj.id = ia_count.id
        where ia_count.application_id = a.id
          and ia_obj.deleted_at is null
    ) as interview_assessment_count,

    (
        select count(*)::integer
        from public.interviews_assessments ia_count
        join public.objects ia_obj on ia_obj.id = ia_count.id
        where ia_count.application_id = a.id
          and ia_obj.deleted_at is null
          and ia_count.status = 'completed'
    ) as completed_interview_assessment_count

from public.applications a
join public.objects app_obj
  on app_obj.id = a.id
 and app_obj.deleted_at is null

join public.opportunities op
  on op.id = a.opportunity_id

join public.objects op_obj
  on op_obj.id = op.id
 and op_obj.deleted_at is null

left join public.organizations org
  on org.id = a.organization_id

left join lateral (
    select ia.*
    from public.interviews_assessments ia
    join public.objects io on io.id = ia.id
    where ia.application_id = a.id
      and io.deleted_at is null
      and (
          ia.scheduled_start_at >= statement_timestamp()
          or ia.deadline_at >= statement_timestamp()
      )
      and ia.status in ('planned', 'scheduled', 'in_progress')
    order by
        least(
            coalesce(ia.scheduled_start_at, 'infinity'::timestamptz),
            coalesce(ia.deadline_at, 'infinity'::timestamptz)
        )
    limit 1
) next_event on true

left join lateral (
    select off.*
    from public.offers off
    join public.objects oo on oo.id = off.id
    where off.application_id = a.id
      and oo.deleted_at is null
    order by off.offer_received_at desc, off.created_at desc
    limit 1
) latest_offer on true;

comment on view public.pipeline_application_summary is
'One-row-per-application recruiting pipeline summary with opportunity, organization, next event, and latest offer context.';

revoke all on public.pipeline_deadline_items from anon;
revoke all on public.pipeline_application_summary from anon;

grant select on public.pipeline_deadline_items to authenticated;
grant select on public.pipeline_application_summary to authenticated;

commit;
