begin;
create table if not exists public.pipeline_health_snapshots (
 id uuid primary key default extensions.gen_random_uuid(),
 snapshot_run_id uuid not null references public.analytics_snapshot_runs(id) on delete cascade,
 owner_user_id uuid not null references public.profiles(id) on delete cascade,
 snapshot_date date not null,
 total_application_count integer not null, submitted_application_count integer not null,
 applications_with_interview integer not null, applications_with_offer integer not null,
 upcoming_event_count integer not null, upcoming_application_deadline_count integer not null,
 upcoming_offer_decision_count integer not null, average_fit_score numeric,
 source_payload jsonb not null check(jsonb_typeof(source_payload)='object'),
 captured_at timestamptz not null default statement_timestamp(),
 unique(snapshot_run_id,owner_user_id)
);
create index if not exists ix_pipeline_health_snapshots__trend
 on public.pipeline_health_snapshots(owner_user_id,snapshot_date desc);
alter table public.pipeline_health_snapshots enable row level security;
drop policy if exists pipeline_health_snapshots_owner_select on public.pipeline_health_snapshots;
create policy pipeline_health_snapshots_owner_select on public.pipeline_health_snapshots
 for select to authenticated using(owner_user_id=private.current_user_id());
revoke all on public.pipeline_health_snapshots from anon;
revoke insert,update,delete on public.pipeline_health_snapshots from authenticated;
grant select on public.pipeline_health_snapshots to authenticated;
commit;