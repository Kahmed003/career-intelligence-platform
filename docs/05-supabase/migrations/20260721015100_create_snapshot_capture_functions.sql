begin;
create or replace function private.capture_daily_analytics_snapshot(p_snapshot_date date default current_date)
returns uuid language plpgsql security definer set search_path=pg_catalog,public as $$
declare
 v_owner uuid; v_run_id uuid;
 v_campaign_rows integer:=0; v_relationship_rows integer:=0; v_pipeline_rows integer:=0;
begin
 v_owner:=private.current_user_id();
 if v_owner is null then raise exception 'Authenticated user required.' using errcode='42501'; end if;

 insert into public.analytics_snapshot_runs(owner_user_id,snapshot_date,snapshot_kind,status)
 values(v_owner,p_snapshot_date,'daily','running') returning id into v_run_id;

 insert into public.campaign_performance_snapshots(
  snapshot_run_id,owner_user_id,snapshot_date,campaign_id,campaign_status,
  application_count,submitted_application_count,interview_assessment_count,
  completed_interview_assessment_count,offer_count,accepted_offer_count,
  networking_interaction_count,completed_networking_interaction_count,
  upcoming_deadline_count,overdue_deadline_count,application_target_progress,
  networking_target_progress,interview_target_progress,application_to_interview_conversion,
  interview_to_offer_conversion,application_to_offer_conversion,offer_acceptance_rate,
  campaign_health,source_payload)
 select v_run_id,v_owner,p_snapshot_date,c.campaign_id,c.campaign_status,
  c.application_count,c.submitted_application_count,c.interview_assessment_count,
  c.completed_interview_assessment_count,c.offer_count,c.accepted_offer_count,
  c.networking_interaction_count,c.completed_networking_interaction_count,
  c.upcoming_deadline_count,c.overdue_deadline_count,c.application_target_progress,
  c.networking_target_progress,c.interview_target_progress,c.application_to_interview_conversion,
  c.interview_to_offer_conversion,c.application_to_offer_conversion,c.offer_acceptance_rate,
  c.campaign_health,to_jsonb(c)
 from public.campaign_performance_summary c where c.owner_user_id=v_owner;
 get diagnostics v_campaign_rows=row_count;

 insert into public.relationship_health_snapshots(
  snapshot_run_id,owner_user_id,snapshot_date,person_id,relationship_stage,
  interaction_count,outbound_count,inbound_count,meeting_count,response_count,response_rate,
  days_since_last_interaction,overdue_follow_up_count,open_follow_up_count,
  relationship_score,relationship_health,relationship_flags,source_payload)
 select v_run_id,v_owner,p_snapshot_date,r.person_id,r.relationship_stage,
  r.interaction_count,r.outbound_count,r.inbound_count,r.meeting_count,r.response_count,
  r.response_rate,r.days_since_last_interaction,r.overdue_follow_up_count,
  r.open_follow_up_count,r.relationship_score,r.relationship_health,
  r.relationship_flags,to_jsonb(r)
 from public.person_relationship_health r where r.owner_user_id=v_owner;
 get diagnostics v_relationship_rows=row_count;

 insert into public.pipeline_health_snapshots(
  snapshot_run_id,owner_user_id,snapshot_date,total_application_count,
  submitted_application_count,applications_with_interview,applications_with_offer,
  upcoming_event_count,upcoming_application_deadline_count,upcoming_offer_decision_count,
  average_fit_score,source_payload)
 select v_run_id,v_owner,p_snapshot_date,count(*)::integer,
  count(*) filter(where p.submitted_at is not null or p.application_status in
   ('submitted','assessment','interviewing','offer','accepted','rejected','withdrawn','closed'))::integer,
  count(*) filter(where p.interview_assessment_count>0)::integer,
  count(*) filter(where p.offer_id is not null)::integer,
  count(*) filter(where p.next_event_at>=statement_timestamp()
                    or p.next_event_deadline_at>=statement_timestamp())::integer,
  count(*) filter(where p.application_deadline_at>=statement_timestamp())::integer,
  count(*) filter(where p.offer_decision_deadline_at>=statement_timestamp())::integer,
  round(avg(p.fit_score)::numeric,4),
  jsonb_build_object('application_status_counts',coalesce((
   select jsonb_object_agg(s.application_status,s.status_count)
   from (select p2.application_status,count(*)::integer status_count
         from public.pipeline_application_summary p2
         where p2.owner_user_id=v_owner group by p2.application_status) s
  ),'{}'::jsonb))
 from public.pipeline_application_summary p where p.owner_user_id=v_owner;
 get diagnostics v_pipeline_rows=row_count;

 update public.analytics_snapshot_runs set status='completed',completed_at=statement_timestamp(),
  campaign_rows=v_campaign_rows,relationship_rows=v_relationship_rows,pipeline_rows=v_pipeline_rows
 where id=v_run_id;
 return v_run_id;
exception when others then
 if v_run_id is not null then
  update public.analytics_snapshot_runs set status='failed',completed_at=statement_timestamp(),
   error_message=sqlerrm,campaign_rows=v_campaign_rows,
   relationship_rows=v_relationship_rows,pipeline_rows=v_pipeline_rows
  where id=v_run_id;
 end if;
 raise;
end; $$;
revoke all on function private.capture_daily_analytics_snapshot(date) from public;
revoke all on function private.capture_daily_analytics_snapshot(date) from anon;
grant execute on function private.capture_daily_analytics_snapshot(date) to authenticated;
commit;