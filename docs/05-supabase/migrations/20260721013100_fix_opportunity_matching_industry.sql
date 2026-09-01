
/*
Migration ID: 20260721013100
Purpose: Correct opportunity industry matching to use the linked Organization industry.
Dependencies: 20260721013000_harden_task_hierarchy.sql
*/
begin;

drop view if exists public.opportunity_match_scores;
drop view if exists public.opportunity_preference_evaluations;

create view public.opportunity_preference_evaluations
with (security_invoker = true)
as
select
    p.id as preference_profile_id,
    p.profile_name,
    p.status as preference_profile_status,
    po.owner_user_id,
    op.id as opportunity_id,
    oo.title as opportunity_title,
    op.organization_id,
    org.legal_name as organization_name,
    c.criterion_type,
    c.criterion_value,
    c.preference_level,
    c.weight,
    c.is_exclusion,
    eval.match_state,
    case
        when eval.match_state = 'matched' then true
        when eval.match_state = 'not_matched' then false
        else null
    end as matched,
    case
        when eval.match_state = 'not_evaluable' then null::numeric
        when c.preference_level = 'neutral' then 0::numeric
        when c.preference_level = 'avoid' and eval.match_state = 'matched' then -c.weight
        when c.preference_level in ('must_have','strong_preference','preference')
             and eval.match_state = 'matched' then c.weight
        else 0::numeric
    end as weighted_contribution,
    eval.explanation
from public.career_preference_profiles p
join public.objects po
  on po.id = p.id and po.deleted_at is null
join public.career_preference_criteria c
  on c.preference_profile_id = p.id
cross join public.opportunities op
join public.objects oo
  on oo.id = op.id
 and oo.deleted_at is null
 and oo.owner_user_id = po.owner_user_id
left join public.organizations org
  on org.id = op.organization_id
left join public.objects org_object
  on org_object.id = org.id
 and org_object.owner_user_id = po.owner_user_id
 and org_object.deleted_at is null
cross join lateral (
    select
        case c.criterion_type
            when 'industry' then case
                when org_object.id is null or org.industry is null then 'not_evaluable'
                when lower(btrim(org.industry)) = lower(btrim(c.criterion_value)) then 'matched'
                else 'not_matched' end
            when 'location' then case
                when op.location_text is null then 'not_evaluable'
                when lower(op.location_text) like '%' || lower(btrim(c.criterion_value)) || '%' then 'matched'
                else 'not_matched' end
            when 'country' then case
                when op.country_code is null then 'not_evaluable'
                when lower(op.country_code) = lower(btrim(c.criterion_value)) then 'matched'
                else 'not_matched' end
            when 'work_mode' then case
                when op.work_mode is null then 'not_evaluable'
                when lower(op.work_mode) = lower(btrim(c.criterion_value)) then 'matched'
                else 'not_matched' end
            when 'employment_type' then case
                when op.employment_type is null then 'not_evaluable'
                when lower(op.employment_type) = lower(btrim(c.criterion_value)) then 'matched'
                else 'not_matched' end
            when 'opportunity_type' then case
                when op.opportunity_type is null then 'not_evaluable'
                when lower(op.opportunity_type) = lower(btrim(c.criterion_value)) then 'matched'
                else 'not_matched' end
            when 'organization' then case
                when op.organization_id is null then 'not_evaluable'
                when c.criterion_value ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
                     and op.organization_id::text = lower(c.criterion_value) then 'matched'
                when org_object.id is not null
                     and org.legal_name is not null
                     and lower(btrim(org.legal_name)) = lower(btrim(c.criterion_value)) then 'matched'
                else 'not_matched' end
            when 'sponsorship' then case
                when op.visa_sponsorship is null then 'not_evaluable'
                when lower(op.visa_sponsorship) = lower(btrim(c.criterion_value)) then 'matched'
                else 'not_matched' end
            else 'not_evaluable'
        end::text as match_state,
        case c.criterion_type
            when 'industry' then format(
                'Organization industry is %s; criterion is %s.',
                coalesce(org.industry,'unknown'), c.criterion_value)
            when 'location' then format(
                'Opportunity location is %s; criterion is %s.',
                coalesce(op.location_text,'unknown'), c.criterion_value)
            when 'country' then format(
                'Opportunity country is %s; criterion is %s.',
                coalesce(op.country_code,'unknown'), c.criterion_value)
            when 'work_mode' then format(
                'Opportunity work mode is %s; criterion is %s.',
                coalesce(op.work_mode,'unknown'), c.criterion_value)
            when 'employment_type' then format(
                'Opportunity employment type is %s; criterion is %s.',
                coalesce(op.employment_type,'unknown'), c.criterion_value)
            when 'opportunity_type' then format(
                'Opportunity type is %s; criterion is %s.',
                coalesce(op.opportunity_type,'unknown'), c.criterion_value)
            when 'organization' then format(
                'Opportunity organization is %s; criterion is %s.',
                coalesce(org.legal_name,op.organization_id::text,'unknown'), c.criterion_value)
            when 'sponsorship' then format(
                'Opportunity sponsorship policy is %s; criterion is %s.',
                coalesce(op.visa_sponsorship,'unknown'), c.criterion_value)
            else format(
                'Criterion type %s is not yet evaluable from structured opportunity fields.',
                c.criterion_type)
        end::text as explanation
) eval
where p.status = 'active';

create view public.opportunity_match_scores
with (security_invoker = true)
as
with base as (
    select
        p.id as preference_profile_id,
        p.profile_name,
        po.owner_user_id,
        op.id as opportunity_id,
        oo.title as opportunity_title,
        op.organization_id,
        org.legal_name as organization_name,
        op.opportunity_type,
        op.status as opportunity_status,
        op.application_deadline_at,
        op.priority as opportunity_priority,
        op.fit_score as manual_fit_score,
        p.minimum_compensation,
        p.preferred_compensation,
        p.compensation_currency as profile_currency,
        p.compensation_period as profile_compensation_period,
        p.requires_sponsorship,
        op.compensation_min,
        op.compensation_max,
        op.compensation_currency as opportunity_currency,
        op.compensation_period as opportunity_compensation_period,
        op.visa_sponsorship,
        comp.compensation_status,
        sponsor.sponsorship_status
    from public.career_preference_profiles p
    join public.objects po on po.id=p.id and po.deleted_at is null
    cross join public.opportunities op
    join public.objects oo
      on oo.id=op.id and oo.deleted_at is null and oo.owner_user_id=po.owner_user_id
    left join public.organizations org on org.id=op.organization_id
    cross join lateral (
        select case
            when p.minimum_compensation is null then 'not_requested'
            when op.compensation_min is null and op.compensation_max is null then 'unknown'
            when p.compensation_currency is null or op.compensation_currency is null then 'unknown'
            when upper(p.compensation_currency) <> upper(op.compensation_currency) then 'unknown'
            when p.compensation_period is not null and op.compensation_period is not null
                 and p.compensation_period <> op.compensation_period then 'unknown'
            when coalesce(op.compensation_max,op.compensation_min) < p.minimum_compensation
                 then 'below_minimum'
            else 'compatible'
        end::text as compensation_status
    ) comp
    cross join lateral (
        select case
            when coalesce(p.requires_sponsorship,false)=false then 'not_required'
            when op.visa_sponsorship='yes' then 'compatible'
            when op.visa_sponsorship='no' then 'incompatible'
            when op.visa_sponsorship='case_by_case' then 'case_by_case'
            else 'unknown'
        end::text as sponsorship_status
    ) sponsor
    where p.status='active'
),
agg as (
    select
        e.preference_profile_id,
        e.opportunity_id,
        count(*) filter(where e.match_state<>'not_evaluable')::integer as evaluable_criteria_count,
        count(*) filter(where e.match_state='matched')::integer as matched_criteria_count,
        count(*) filter(where e.preference_level='must_have' and e.match_state='not_matched')::integer
            as must_have_failure_count,
        count(*) filter(where e.is_exclusion=true and e.match_state='matched')::integer as exclusion_count,
        sum(case when e.match_state='not_evaluable' or e.preference_level='neutral'
                 then 0 else e.weight end)::numeric as total_evaluable_weight,
        sum(coalesce(e.weighted_contribution,0))::numeric as net_weighted_contribution,
        jsonb_agg(jsonb_build_object(
            'type',e.criterion_type,'value',e.criterion_value,'weight',e.weight,
            'preference_level',e.preference_level,'exclusion',e.is_exclusion,
            'match_state',e.match_state,'explanation',e.explanation)
            order by e.weight desc,e.criterion_type,e.criterion_value) as criterion_explanations
    from public.opportunity_preference_evaluations e
    group by e.preference_profile_id,e.opportunity_id
)
select
    b.owner_user_id,b.preference_profile_id,b.profile_name,b.opportunity_id,
    b.opportunity_title,b.organization_id,b.organization_name,b.opportunity_type,
    b.opportunity_status,b.application_deadline_at,b.opportunity_priority,b.manual_fit_score,
    coalesce(a.evaluable_criteria_count,0) as evaluable_criteria_count,
    coalesce(a.matched_criteria_count,0) as matched_criteria_count,
    coalesce(a.must_have_failure_count,0) as must_have_failure_count,
    coalesce(a.exclusion_count,0) as exclusion_count,
    case when coalesce(a.total_evaluable_weight,0)<=0 then null::numeric
         else round(greatest(0::numeric,least(100::numeric,
             greatest(coalesce(a.net_weighted_contribution,0),0)/a.total_evaluable_weight*100)),2)
    end as weighted_match_score,
    b.compensation_status,b.sponsorship_status,
    case
        when coalesce(a.exclusion_count,0)>0 then 'excluded'
        when coalesce(a.must_have_failure_count,0)>0 then 'disqualified'
        when b.sponsorship_status='incompatible' then 'sponsorship_conflict'
        when b.compensation_status='below_minimum' then 'compensation_conflict'
        when coalesce(a.total_evaluable_weight,0)<=0 then 'insufficient_data'
        when greatest(coalesce(a.net_weighted_contribution,0),0)/a.total_evaluable_weight*100>=75
             then 'strong_match'
        when greatest(coalesce(a.net_weighted_contribution,0),0)/a.total_evaluable_weight*100>=50
             then 'possible_match'
        else 'weak_match'
    end::text as recommendation_status,
    jsonb_build_object(
        'criterion_evaluations',coalesce(a.criterion_explanations,'[]'::jsonb),
        'compensation',jsonb_build_object(
            'status',b.compensation_status,'profile_minimum',b.minimum_compensation,
            'profile_preferred',b.preferred_compensation,'profile_currency',b.profile_currency,
            'profile_period',b.profile_compensation_period,'opportunity_minimum',b.compensation_min,
            'opportunity_maximum',b.compensation_max,'opportunity_currency',b.opportunity_currency,
            'opportunity_period',b.opportunity_compensation_period),
        'sponsorship',jsonb_build_object(
            'status',b.sponsorship_status,'requires_sponsorship',b.requires_sponsorship,
            'opportunity_policy',b.visa_sponsorship)
    ) as explanation
from base b
left join agg a
  on a.preference_profile_id=b.preference_profile_id and a.opportunity_id=b.opportunity_id;

revoke all on public.opportunity_preference_evaluations from anon;
revoke all on public.opportunity_match_scores from anon;
grant select on public.opportunity_preference_evaluations to authenticated;
grant select on public.opportunity_match_scores to authenticated;

commit;
