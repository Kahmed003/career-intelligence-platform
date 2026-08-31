
/*
Migration: 20260721012500_create_relationship_intelligence.sql
Purpose: Create derived relationship-health and warm-introduction intelligence.
*/
begin;

drop view if exists public.relationship_warm_intro_candidates;
drop view if exists public.person_relationship_health;

create view public.person_relationship_health
with (security_invoker = true)
as
with interaction_stats as (
    select
        p.id as person_id,

        count(ic.id)::integer as interaction_count,

        count(ic.id) filter (
            where ic.direction = 'outbound'
        )::integer as outbound_count,

        count(ic.id) filter (
            where ic.direction = 'inbound'
        )::integer as inbound_count,

        count(ic.id) filter (
            where ic.interaction_type in (
                'video_call',
                'coffee_chat',
                'in_person_meeting',
                'informational_interview',
                'recruiter_conversation',
                'mentor_meeting',
                'conference_conversation'
            )
              and ic.status = 'completed'
        )::integer as meeting_count,

        count(ic.id) filter (
            where ic.response_received_at is not null
               or ic.outcome in (
                    'responded',
                    'connected',
                    'meeting_scheduled',
                    'referral_offered',
                    'referral_received',
                    'application_guidance',
                    'relationship_advanced'
               )
        )::integer as response_count,

        count(ic.id) filter (
            where ic.follow_up_required = true
              and ic.follow_up_at < statement_timestamp()
              and ic.status <> 'cancelled'
        )::integer as overdue_follow_up_count,

        count(ic.id) filter (
            where ic.follow_up_required = true
              and ic.follow_up_at >= statement_timestamp()
              and ic.status <> 'cancelled'
        )::integer as open_follow_up_count,

        max(
            coalesce(
                ic.occurred_at,
                ic.response_received_at,
                ic.scheduled_for,
                ic.created_at
            )
        ) as last_interaction_at,

        (
            array_agg(
                nullif(btrim(ic.summary), '')
                order by coalesce(
                    ic.occurred_at,
                    ic.response_received_at,
                    ic.scheduled_for,
                    ic.created_at
                ) desc
            )
        )[1] as latest_interaction_summary,

        bool_or(
            ic.interaction_type = 'recruiter_conversation'
        ) as has_recruiter_contact,

        bool_or(
            ic.outcome in ('referral_offered', 'referral_received')
        ) as has_referral_signal,

        bool_or(
            ic.response_received_at >= statement_timestamp() - interval '30 days'
        ) as has_recent_response

    from public.people p
    left join public.interactions_communications ic
      on ic.person_id = p.id
    left join public.objects io
      on io.id = ic.id
     and io.deleted_at is null
    group by p.id
),
base as (
    select
        o.owner_user_id,
        p.id as person_id,
        o.title as person_name,
        p.organization_id,
        org.legal_name as organization_name,
        p.relationship_stage,
        p.last_contacted_at,
        p.next_follow_up_at,

        coalesce(s.interaction_count, 0) as interaction_count,
        coalesce(s.outbound_count, 0) as outbound_count,
        coalesce(s.inbound_count, 0) as inbound_count,
        coalesce(s.meeting_count, 0) as meeting_count,
        coalesce(s.response_count, 0) as response_count,
        coalesce(s.overdue_follow_up_count, 0) as overdue_follow_up_count,
        coalesce(s.open_follow_up_count, 0) as open_follow_up_count,

        coalesce(
            s.last_interaction_at,
            p.last_contacted_at
        ) as last_interaction_at,

        s.latest_interaction_summary,
        coalesce(s.has_recruiter_contact, false) as has_recruiter_contact,
        coalesce(s.has_referral_signal, false) as has_referral_signal,
        coalesce(s.has_recent_response, false) as has_recent_response

    from public.people p
    join public.objects o
      on o.id = p.id
     and o.deleted_at is null

    left join public.organizations org
      on org.id = p.organization_id

    left join interaction_stats s
      on s.person_id = p.id
),
scored as (
    select
        b.*,

        case
            when b.last_interaction_at is null then null
            else floor(
                extract(
                    epoch from (
                        statement_timestamp() - b.last_interaction_at
                    )
                ) / 86400
            )::integer
        end as days_since_last_interaction,

        case
            when b.outbound_count = 0 then null::numeric
            else round(
                least(
                    1::numeric,
                    b.response_count::numeric / nullif(b.outbound_count, 0)
                ),
                4
            )
        end as response_rate,

        (
            /* Recency: max 35 */
            case
                when b.last_interaction_at >= statement_timestamp() - interval '14 days' then 35
                when b.last_interaction_at >= statement_timestamp() - interval '30 days' then 30
                when b.last_interaction_at >= statement_timestamp() - interval '60 days' then 22
                when b.last_interaction_at >= statement_timestamp() - interval '120 days' then 12
                when b.last_interaction_at is not null then 5
                else 0
            end

            /* Volume: max 20 */
            + least(b.interaction_count * 4, 20)

            /* Inbound engagement: max 15 */
            + least(b.response_count * 5, 15)

            /* Meetings: max 15 */
            + least(b.meeting_count * 5, 15)

            /* Stage: max 15 */
            + case b.relationship_stage
                when 'active_relationship' then 15
                when 'connected' then 10
                when 'outreach_sent' then 5
                when 'dormant' then 2
                else 0
              end

            /* Penalty for overdue follow-up */
            - least(b.overdue_follow_up_count * 10, 30)
        )::integer as raw_relationship_score

    from base b
)
select
    s.owner_user_id,
    s.person_id,
    s.person_name,
    s.organization_id,
    s.organization_name,
    s.relationship_stage,
    s.last_contacted_at,
    s.next_follow_up_at,
    s.interaction_count,
    s.outbound_count,
    s.inbound_count,
    s.meeting_count,
    s.response_count,
    s.response_rate,
    s.days_since_last_interaction,
    s.overdue_follow_up_count,
    s.open_follow_up_count,

    greatest(
        0,
        least(100, s.raw_relationship_score)
    ) as relationship_score,

    case
        when s.interaction_count = 0
             and s.relationship_stage in ('uncontacted', 'outreach_sent')
            then 'unengaged'

        when s.overdue_follow_up_count > 0
             or (
                s.days_since_last_interaction is not null
                and s.days_since_last_interaction > 120
             )
            then 'stale'

        when greatest(0, least(100, s.raw_relationship_score)) >= 75
            then 'strong'

        when greatest(0, least(100, s.raw_relationship_score)) >= 50
            then 'healthy'

        else 'needs_attention'
    end::text as relationship_health,

    jsonb_strip_nulls(
        jsonb_build_object(
            'follow_up_overdue',
                case when s.overdue_follow_up_count > 0 then true else null end,
            'follow_up_due_soon',
                case
                    when s.next_follow_up_at is not null
                     and s.next_follow_up_at >= statement_timestamp()
                     and s.next_follow_up_at <= statement_timestamp() + interval '7 days'
                    then true
                    else null
                end,
            'stale_contact',
                case
                    when s.days_since_last_interaction is not null
                     and s.days_since_last_interaction > 120
                    then true
                    else null
                end,
            'no_interaction_history',
                case when s.interaction_count = 0 then true else null end,
            'active_relationship',
                case
                    when s.relationship_stage = 'active_relationship'
                    then true
                    else null
                end,
            'recruiter_contact',
                case when s.has_recruiter_contact then true else null end,
            'referral_signal',
                case when s.has_referral_signal then true else null end,
            'recent_response',
                case when s.has_recent_response then true else null end
        )
    ) as relationship_flags,

    s.latest_interaction_summary

from scored s;

comment on view public.person_relationship_health is
'Derived operational relationship-health metrics for People using interaction recency, engagement, follow-up state, and relationship stage.';

create view public.relationship_warm_intro_candidates
with (security_invoker = true)
as
select distinct
    src.owner_user_id,

    src.id as source_person_id,
    src.title as source_person_name,

    r.relationship_type,

    case
        when target.object_type = 'person'
            then target.id
        else null
    end as target_person_id,

    case
        when target.object_type = 'person'
            then target.title
        else null
    end as target_person_name,

    case
        when target.object_type = 'organization'
            then target.id
        else null
    end as target_organization_id,

    case
        when target.object_type = 'organization'
            then org.legal_name
        else null
    end as target_organization_name,

    r.confidence_score,
    r.created_at as relationship_recorded_at,
    r.metadata as relationship_metadata

from public.object_relationships r

join public.objects src
  on src.id = r.source_object_id
 and src.object_type = 'person'
 and src.deleted_at is null

join public.objects target
  on target.id = r.target_object_id
 and target.deleted_at is null
 and target.owner_user_id = src.owner_user_id

left join public.organizations org
  on org.id = target.id
 and target.object_type = 'organization'

where r.relationship_type in (
    'introduced_by',
    'works_at',
    'associated_with',
    'related_to'
)
  and target.object_type in ('person', 'organization');

comment on view public.relationship_warm_intro_candidates is
'Explicit graph-based relationship paths that may represent warm-introduction opportunities; does not infer availability or willingness.';

revoke all on public.person_relationship_health from anon;
revoke all on public.relationship_warm_intro_candidates from anon;

grant select on public.person_relationship_health to authenticated;
grant select on public.relationship_warm_intro_candidates to authenticated;

commit;
