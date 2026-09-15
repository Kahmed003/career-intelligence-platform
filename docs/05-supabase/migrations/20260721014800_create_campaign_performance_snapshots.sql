begin;
create table if not exists public.campaign_performance_snapshots (
 id uuid primary key default extensions.gen_random_uuid(),
 snapshot_run_id uuid not null references public.analytics_snapshot_runs(id) on delete cascade,
 owner_user_id uuid not null references public.profiles(id) on delete cascade,
 snapshot_date date not null,
 campaign_id uuid not null references public.career_campaigns(id) on delete restrict,
 campaign_status text not null,
 application_count integer not null, submitted_application_count integer not null,
 interview_assessment_count integer not null, completed_interview_assessment_count integer not null,
 offer_count integer not null, accepted_offer_count integer not null,
 networking_interaction_count integer not null, completed_networking_interaction_count integer not null,
 upcoming_deadline_count integer not null, overdue_deadline_count integer not null,
 application_target_progress numeric, networking_target_progress numeric, interview_target_progress numeric,
 application_to_interview_conversion numeric, interview_to_offer_conversion numeric,
 application_to_offer_conversion numeric, offer_acceptance_rate numeric,
 campaign_health text not null,
 source_payload jsonb not null check(jsonb_typeof(source_payload)='object'),
 captured_at timestamptz not null default statement_timestamp(),
 unique(snapshot_run_id,campaign_id)
);
create index if not exists ix_campaign_performance_snapshots__trend
 on public.campaign_performance_snapshots(owner_user_id,campaign_id,snapshot_date desc);
alter table public.campaign_performance_snapshots enable row level security;
drop policy if exists campaign_performance_snapshots_owner_select on public.campaign_performance_snapshots;
create policy campaign_performance_snapshots_owner_select on public.campaign_performance_snapshots
 for select to authenticated using(owner_user_id=private.current_user_id());
revoke all on public.campaign_performance_snapshots from anon;
revoke insert,update,delete on public.campaign_performance_snapshots from authenticated;
grant select on public.campaign_performance_snapshots to authenticated;
commit;