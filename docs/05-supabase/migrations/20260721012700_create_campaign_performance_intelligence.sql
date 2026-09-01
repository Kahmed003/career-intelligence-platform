
/*
Migration: 20260721012700_create_campaign_performance_intelligence.sql
Purpose: Create derived recruiting funnel and campaign performance analytics.
*/
begin;

drop view if exists public.campaign_source_performance;
drop view if exists public.campaign_performance_summary;

create view public.campaign_performance_summary
with (security_invoker = true)
as
with campaign_scope as (
    select
        c.id as campaign_id,
        o.owner_user_id,
        o.title as campaign_title,
        c.campaign_type,
        c.status as campaign_status,
        c.start_date,
        c.end_date,
        c.target_application_count,
        c.target_networking_count,
        c.target_interview_count,
        c.preference_profile_id
    from public.career_campaigns c
    join public.objects o
      on o.id = c.id
     and o.deleted_at is null
),
members as (
    select
        m.campaign_id,
        m.object_id,
        obj.object_type,
        m.member_role,
        m.priority,
        m.status as membership_status
    from public.career_campaign_members m
    join public.objects obj
      on obj.id = m.object_id
     and obj.deleted_at is null
),
applications_in_campaign as (
    select distinct
        m.campaign_id,
        a.id as application_id,
        a.opportunity_id,
        a.status,
        a.submitted_at
    from members m
    join public.applications a
      on a.id = m.object_id
    where m.object_type = 'application'
      and m.membership_status <> 'dropped'
),
opportunities_in_campaign as (
    select distinct
        m.campaign_id,
        op.id as opportunity_id
    from members m
    join public.opportunities op
      on op.id = m.object_id
    where m.object_type = 'opportunity'
      and m.membership_status <> 'dropped'

    union

    select
        aic.campaign_id,
        aic.opportunity_id
    from applications_in_campaign aic
),
networking_in_campaign as (
    select distinct
        m.campaign_id,
        ic.id as interaction_id,
        ic.status
    from members m
    join public.interactions_communications ic
      on ic.id = m.object_id
    where m.object_type = 'interaction'
      and m.membership_status <> 'dropped'
),
tasks_in_campaign as (
    select distinct
        m.campaign_id,
        t.id as task_id,
        t.completed_at
    from members m
    join public.tasks t
      on t.id = m.object_id
    where m.object_type = 'task'
      and m.membership_status <> 'dropped'
),
searches_in_campaign as (
    select distinct
        m.campaign_id,
        s.id as saved_search_id,
        s.is_active
    from members m
    join public.saved_searches s
      on s.id = m.object_id
    where m.object_type = 'saved_search'
      and m.membership_status <> 'dropped'
),
interview_stats as (
    select
        aic.campaign_id,
        count(ia.id)::integer as interview_assessment_count,
        count(ia.id) filter (
            where ia.status = 'completed'
        )::integer as completed_interview_assessment_count,
        count(distinct aic.application_id) filter (
            where ia.id is not null
        )::integer as applications_with_interview
    from applications_in_campaign aic
    left join public.interviews_assessments ia
      on ia.application_id = aic.application_id
    group by aic.campaign_id
),
offer_stats as (
    select
        aic.campaign_id,
        count(ofr.id)::integer as offer_count,
        count(ofr.id) filter (
            where ofr.status = 'accepted'
               or ofr.decision = 'accepted'
        )::integer as accepted_offer_count,
        count(distinct aic.application_id) filter (
            where ofr.id is not null
        )::integer as applications_with_offer
    from applications_in_campaign aic
    left join public.offers ofr
      on ofr.application_id = aic.application_id
    group by aic.campaign_id
),
deadline_stats as (
    select
        cs.campaign_id,

        count(distinct pdi.source_object_id) filter (
            where pdi.due_at >= statement_timestamp()
        )::integer as upcoming_deadline_count,

        count(distinct pdi.source_object_id) filter (
            where pdi.due_at < statement_timestamp()
        )::integer as overdue_deadline_count

    from campaign_scope cs
    left join public.pipeline_deadline_items pdi
      on exists (
          select 1
          from members m
          where m.campaign_id = cs.campaign_id
            and m.membership_status <> 'dropped'
            and (
                m.object_id = pdi.source_object_id
                or m.object_id = pdi.parent_object_id
                or m.object_id = pdi.application_id
                or m.object_id = pdi.opportunity_id
            )
      )
    group by cs.campaign_id
),
member_counts as (
    select
        campaign_id,
        count(*) filter (
            where membership_status = 'active'
        )::integer as active_member_count,
        count(*)::integer as total_member_count
    from members
    group by campaign_id
),
application_stats as (
    select
        campaign_id,
        count(*)::integer as application_count,
        count(*) filter (
            where submitted_at is not null
               or status in (
                    'submitted',
                    'assessment',
                    'interviewing',
                    'offer',
                    'accepted',
                    'rejected',
                    'withdrawn',
                    'closed'
               )
        )::integer as submitted_application_count
    from applications_in_campaign
    group by campaign_id
),
opportunity_stats as (
    select
        campaign_id,
        count(*)::integer as opportunity_count
    from opportunities_in_campaign
    group by campaign_id
),
networking_stats as (
    select
        campaign_id,
        count(*)::integer as networking_interaction_count,
        count(*) filter (
            where status = 'completed'
        )::integer as completed_networking_interaction_count
    from networking_in_campaign
    group by campaign_id
),
task_stats as (
    select
        campaign_id,
        count(*)::integer as task_count,
        count(*) filter (
            where completed_at is not null
        )::integer as completed_task_count
    from tasks_in_campaign
    group by campaign_id
),
search_stats as (
    select
        campaign_id,
        count(*)::integer as saved_search_count,
        count(*) filter (
            where is_active = true
        )::integer as active_saved_search_count
    from searches_in_campaign
    group by campaign_id
),
combined as (
    select
        cs.*,

        coalesce(mc.active_member_count, 0) as active_member_count,
        coalesce(mc.total_member_count, 0) as total_member_count,

        coalesce(os.opportunity_count, 0) as opportunity_count,

        coalesce(app.application_count, 0) as application_count,
        coalesce(app.submitted_application_count, 0) as submitted_application_count,

        coalesce(i.interview_assessment_count, 0) as interview_assessment_count,
        coalesce(i.completed_interview_assessment_count, 0) as completed_interview_assessment_count,
        coalesce(i.applications_with_interview, 0) as applications_with_interview,

        coalesce(ofs.offer_count, 0) as offer_count,
        coalesce(ofs.accepted_offer_count, 0) as accepted_offer_count,
        coalesce(ofs.applications_with_offer, 0) as applications_with_offer,

        coalesce(ns.networking_interaction_count, 0) as networking_interaction_count,
        coalesce(ns.completed_networking_interaction_count, 0) as completed_networking_interaction_count,

        coalesce(ts.task_count, 0) as task_count,
        coalesce(ts.completed_task_count, 0) as completed_task_count,

        coalesce(ss.saved_search_count, 0) as saved_search_count,
        coalesce(ss.active_saved_search_count, 0) as active_saved_search_count,

        coalesce(ds.upcoming_deadline_count, 0) as upcoming_deadline_count,
        coalesce(ds.overdue_deadline_count, 0) as overdue_deadline_count

    from campaign_scope cs
    left join member_counts mc on mc.campaign_id = cs.campaign_id
    left join opportunity_stats os on os.campaign_id = cs.campaign_id
    left join application_stats app on app.campaign_id = cs.campaign_id
    left join interview_stats i on i.campaign_id = cs.campaign_id
    left join offer_stats ofs on ofs.campaign_id = cs.campaign_id
    left join networking_stats ns on ns.campaign_id = cs.campaign_id
    left join task_stats ts on ts.campaign_id = cs.campaign_id
    left join search_stats ss on ss.campaign_id = cs.campaign_id
    left join deadline_stats ds on ds.campaign_id = cs.campaign_id
)
select
    c.owner_user_id,
    c.campaign_id,
    c.campaign_title,
    c.campaign_type,
    c.campaign_status,
    c.start_date,
    c.end_date,
    c.preference_profile_id,

    c.target_application_count,
    c.target_networking_count,
    c.target_interview_count,

    c.active_member_count,
    c.total_member_count,
    c.opportunity_count,
    c.application_count,
    c.submitted_application_count,
    c.interview_assessment_count,
    c.completed_interview_assessment_count,
    c.offer_count,
    c.accepted_offer_count,
    c.networking_interaction_count,
    c.completed_networking_interaction_count,
    c.task_count,
    c.completed_task_count,
    c.saved_search_count,
    c.active_saved_search_count,
    c.upcoming_deadline_count,
    c.overdue_deadline_count,

    case
        when c.target_application_count is null
          or c.target_application_count = 0
            then null::numeric
        else round(
            least(
                1::numeric,
                c.application_count::numeric / c.target_application_count
            ),
            4
        )
    end as application_target_progress,

    case
        when c.target_networking_count is null
          or c.target_networking_count = 0
            then null::numeric
        else round(
            least(
                1::numeric,
                c.completed_networking_interaction_count::numeric
                / c.target_networking_count
            ),
            4
        )
    end as networking_target_progress,

    case
        when c.target_interview_count is null
          or c.target_interview_count = 0
            then null::numeric
        else round(
            least(
                1::numeric,
                c.completed_interview_assessment_count::numeric
                / c.target_interview_count
            ),
            4
        )
    end as interview_target_progress,

    case
        when c.submitted_application_count = 0
            then null::numeric
        else round(
            c.applications_with_interview::numeric
            / c.submitted_application_count,
            4
        )
    end as application_to_interview_conversion,

    case
        when c.applications_with_interview = 0
            then null::numeric
        else round(
            c.applications_with_offer::numeric
            / c.applications_with_interview,
            4
        )
    end as interview_to_offer_conversion,

    case
        when c.submitted_application_count = 0
            then null::numeric
        else round(
            c.applications_with_offer::numeric
            / c.submitted_application_count,
            4
        )
    end as application_to_offer_conversion,

    case
        when c.offer_count = 0
            then null::numeric
        else round(
            c.accepted_offer_count::numeric / c.offer_count,
            4
        )
    end as offer_acceptance_rate,

    case
        when c.campaign_status = 'completed'
            then 'completed'
        when c.campaign_status in ('paused', 'cancelled', 'archived')
            then 'inactive'
        when c.overdue_deadline_count >= 3
             and c.submitted_application_count = 0
            then 'critical'
        when c.overdue_deadline_count > 0
            then 'at_risk'
        when c.end_date is not null
             and current_date > c.end_date
             and c.campaign_status = 'active'
            then 'at_risk'
        when c.application_count = 0
             and c.networking_interaction_count = 0
            then 'early_stage'
        else 'on_track'
    end::text as campaign_health

from combined c;

comment on view public.campaign_performance_summary is
'Derived campaign-level recruiting funnel, target progress, deadline pressure, and operational health metrics.';

create view public.campaign_source_performance
with (security_invoker = true)
as
with campaign_opportunities as (
    select distinct
        m.campaign_id,
        op.id as opportunity_id
    from public.career_campaign_members m
    join public.objects obj
      on obj.id = m.object_id
     and obj.deleted_at is null
    join public.opportunities op
      on op.id = m.object_id
    where obj.object_type = 'opportunity'
      and m.status <> 'dropped'

    union

    select distinct
        m.campaign_id,
        a.opportunity_id
    from public.career_campaign_members m
    join public.objects obj
      on obj.id = m.object_id
     and obj.deleted_at is null
    join public.applications a
      on a.id = m.object_id
    where obj.object_type = 'application'
      and m.status <> 'dropped'
),
promotions as (
    select
        co.campaign_id,
        d.discovery_source_id,
        d.id as discovered_id,
        d.promoted_opportunity_id
    from campaign_opportunities co
    join public.discovered_opportunities d
      on d.promoted_opportunity_id = co.opportunity_id
),
apps as (
    select distinct
        co.campaign_id,
        co.opportunity_id,
        a.id as application_id,
        a.submitted_at,
        a.status
    from campaign_opportunities co
    join public.applications a
      on a.opportunity_id = co.opportunity_id
),
app_downstream as (
    select
        a.campaign_id,
        a.application_id,

        exists (
            select 1
            from public.interviews_assessments ia
            where ia.application_id = a.application_id
        ) as has_interview,

        exists (
            select 1
            from public.offers ofr
            where ofr.application_id = a.application_id
        ) as has_offer

    from apps a
)
select
    c.id as campaign_id,
    co.owner_user_id,

    ds.id as discovery_source_id,
    ds.name as discovery_source_name,
    ds.source_type,

    count(distinct p.discovered_id)::integer as discovered_record_count,
    count(distinct p.promoted_opportunity_id)::integer as promoted_opportunity_count,

    count(distinct a.application_id)::integer as application_count,

    count(distinct a.application_id) filter (
        where a.submitted_at is not null
           or a.status in (
                'submitted',
                'assessment',
                'interviewing',
                'offer',
                'accepted',
                'rejected',
                'withdrawn',
                'closed'
           )
    )::integer as submitted_application_count,

    count(distinct ad.application_id) filter (
        where ad.has_interview = true
    )::integer as applications_with_interview,

    count(distinct ad.application_id) filter (
        where ad.has_offer = true
    )::integer as applications_with_offer,

    case
        when count(distinct p.discovered_id) = 0
            then null::numeric
        else round(
            count(distinct p.promoted_opportunity_id)::numeric
            / count(distinct p.discovered_id),
            4
        )
    end as source_to_opportunity_conversion,

    case
        when count(distinct p.promoted_opportunity_id) = 0
            then null::numeric
        else round(
            count(distinct a.application_id)::numeric
            / count(distinct p.promoted_opportunity_id),
            4
        )
    end as source_to_application_conversion,

    case
        when count(distinct a.application_id) filter (
            where a.submitted_at is not null
               or a.status in (
                    'submitted',
                    'assessment',
                    'interviewing',
                    'offer',
                    'accepted',
                    'rejected',
                    'withdrawn',
                    'closed'
               )
        ) = 0
            then null::numeric
        else round(
            count(distinct ad.application_id) filter (
                where ad.has_offer = true
            )::numeric
            /
            count(distinct a.application_id) filter (
                where a.submitted_at is not null
                   or a.status in (
                        'submitted',
                        'assessment',
                        'interviewing',
                        'offer',
                        'accepted',
                        'rejected',
                        'withdrawn',
                        'closed'
                   )
            ),
            4
        )
    end as application_to_offer_conversion

from public.career_campaigns c
join public.objects co
  on co.id = c.id
 and co.deleted_at is null

join promotions p
  on p.campaign_id = c.id

join public.discovery_sources ds
  on ds.id = p.discovery_source_id

left join apps a
  on a.campaign_id = c.id
 and a.opportunity_id = p.promoted_opportunity_id

left join app_downstream ad
  on ad.campaign_id = c.id
 and ad.application_id = a.application_id

group by
    c.id,
    co.owner_user_id,
    ds.id,
    ds.name,
    ds.source_type;

comment on view public.campaign_source_performance is
'Derived campaign-level effectiveness metrics for opportunity discovery sources and downstream recruiting outcomes.';

revoke all on public.campaign_performance_summary from anon;
revoke all on public.campaign_source_performance from anon;

grant select on public.campaign_performance_summary to authenticated;
grant select on public.campaign_source_performance to authenticated;

commit;
