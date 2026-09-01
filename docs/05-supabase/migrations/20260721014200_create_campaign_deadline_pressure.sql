
/*
Migration ID: 20260721014200
Purpose: Create corrected campaign deadline-pressure intelligence that counts deadline rows.
Dependencies: 20260721014100_harden_pipeline_application_summary.sql
*/
begin;

drop view if exists public.campaign_deadline_pressure;

create view public.campaign_deadline_pressure
with (security_invoker = true)
as
with active_members as (
    select
        m.campaign_id,
        m.object_id
    from public.career_campaign_members m
    join public.objects o
      on o.id = m.object_id
     and o.deleted_at is null
    where m.status <> 'dropped'
),
matched_deadlines as (
    select distinct
        c.id as campaign_id,
        pdi.source_type,
        pdi.source_object_id,
        pdi.parent_object_id,
        pdi.action_type,
        pdi.due_at,
        pdi.urgency
    from public.career_campaigns c
    join public.objects co
      on co.id = c.id
     and co.deleted_at is null
    join public.pipeline_deadline_items pdi
      on exists (
          select 1
          from active_members m
          where m.campaign_id = c.id
            and (
                m.object_id = pdi.source_object_id
                or m.object_id = pdi.parent_object_id
                or m.object_id = pdi.application_id
                or m.object_id = pdi.opportunity_id
            )
      )
)
select
    c.id as campaign_id,
    co.owner_user_id,
    count(md.*)::integer as total_deadline_item_count,
    count(md.*) filter (where md.due_at < statement_timestamp())::integer
        as overdue_deadline_item_count,
    count(md.*) filter (where md.urgency = 'today')::integer as due_today_count,
    count(md.*) filter (where md.urgency = 'next_3_days')::integer as next_3_days_count,
    count(md.*) filter (where md.urgency = 'next_7_days')::integer as next_7_days_count,
    count(md.*) filter (where md.urgency = 'later')::integer as later_count,
    min(md.due_at) filter (where md.due_at >= statement_timestamp()) as next_due_at
from public.career_campaigns c
join public.objects co
  on co.id = c.id
 and co.deleted_at is null
left join matched_deadlines md
  on md.campaign_id = c.id
group by c.id, co.owner_user_id;

comment on view public.campaign_deadline_pressure is
'Campaign deadline pressure counted at normalized deadline-item granularity rather than distinct source-object granularity.';

revoke all on public.campaign_deadline_pressure from anon;
grant select on public.campaign_deadline_pressure to authenticated;

commit;
