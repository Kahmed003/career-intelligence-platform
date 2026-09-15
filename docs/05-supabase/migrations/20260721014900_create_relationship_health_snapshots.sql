begin;
create table if not exists public.relationship_health_snapshots (
 id uuid primary key default extensions.gen_random_uuid(),
 snapshot_run_id uuid not null references public.analytics_snapshot_runs(id) on delete cascade,
 owner_user_id uuid not null references public.profiles(id) on delete cascade,
 snapshot_date date not null,
 person_id uuid not null references public.people(id) on delete restrict,
 relationship_stage text not null,
 interaction_count integer not null, outbound_count integer not null, inbound_count integer not null,
 meeting_count integer not null, response_count integer not null, response_rate numeric,
 days_since_last_interaction integer, overdue_follow_up_count integer not null,
 open_follow_up_count integer not null, relationship_score integer not null,
 relationship_health text not null,
 relationship_flags jsonb not null default '{}'::jsonb check(jsonb_typeof(relationship_flags)='object'),
 source_payload jsonb not null check(jsonb_typeof(source_payload)='object'),
 captured_at timestamptz not null default statement_timestamp(),
 unique(snapshot_run_id,person_id)
);
create index if not exists ix_relationship_health_snapshots__trend
 on public.relationship_health_snapshots(owner_user_id,person_id,snapshot_date desc);
alter table public.relationship_health_snapshots enable row level security;
drop policy if exists relationship_health_snapshots_owner_select on public.relationship_health_snapshots;
create policy relationship_health_snapshots_owner_select on public.relationship_health_snapshots
 for select to authenticated using(owner_user_id=private.current_user_id());
revoke all on public.relationship_health_snapshots from anon;
revoke insert,update,delete on public.relationship_health_snapshots from authenticated;
grant select on public.relationship_health_snapshots to authenticated;
commit;