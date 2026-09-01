
/*
Migration ID: 20260721014100
Purpose: Prevent soft-deleted Organizations from appearing in pipeline application summaries.
Dependencies: 20260721014000_create_notes_search_interface.sql
*/
begin;

create or replace view public.pipeline_application_summary
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
    case when org_obj.id is not null then org.id else null end as organization_id,
    case when org_obj.id is not null then org.legal_name else null end as organization_name,
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
left join public.objects org_obj
  on org_obj.id = org.id
 and org_obj.object_type = 'organization'
 and org_obj.owner_user_id = app_obj.owner_user_id
 and org_obj.deleted_at is null
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
      and ia.status in ('planned','scheduled','in_progress')
    order by least(
        coalesce(ia.scheduled_start_at,'infinity'::timestamptz),
        coalesce(ia.deadline_at,'infinity'::timestamptz)
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

revoke all on public.pipeline_application_summary from anon;
grant select on public.pipeline_application_summary to authenticated;

commit;
