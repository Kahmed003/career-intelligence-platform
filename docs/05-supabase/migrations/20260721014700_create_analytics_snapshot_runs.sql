begin;
create table if not exists public.analytics_snapshot_runs (
 id uuid primary key default extensions.gen_random_uuid(),
 owner_user_id uuid not null references public.profiles(id) on delete cascade,
 snapshot_date date not null,
 snapshot_kind text not null default 'daily' check(snapshot_kind in ('daily','weekly','manual')),
 status text not null default 'running' check(status in ('running','completed','failed')),
 started_at timestamptz not null default statement_timestamp(),
 completed_at timestamptz,
 campaign_rows integer not null default 0 check(campaign_rows>=0),
 relationship_rows integer not null default 0 check(relationship_rows>=0),
 pipeline_rows integer not null default 0 check(pipeline_rows>=0),
 error_message text,
 metadata jsonb not null default '{}'::jsonb check(jsonb_typeof(metadata)='object'),
 constraint ck_snapshot_runs__completion check(
   (status='running' and completed_at is null) or
   (status in ('completed','failed') and completed_at is not null)),
 constraint ck_snapshot_runs__error check(status<>'failed' or error_message is not null)
);
create unique index if not exists ux_analytics_snapshot_runs__active_daily
 on public.analytics_snapshot_runs(owner_user_id,snapshot_date,snapshot_kind)
 where status in ('running','completed');
create index if not exists ix_analytics_snapshot_runs__owner_date
 on public.analytics_snapshot_runs(owner_user_id,snapshot_date desc);
alter table public.analytics_snapshot_runs enable row level security;
drop policy if exists analytics_snapshot_runs_owner_select on public.analytics_snapshot_runs;
create policy analytics_snapshot_runs_owner_select on public.analytics_snapshot_runs
 for select to authenticated using(owner_user_id=private.current_user_id());
revoke all on public.analytics_snapshot_runs from anon;
revoke insert,update,delete on public.analytics_snapshot_runs from authenticated;
grant select on public.analytics_snapshot_runs to authenticated;
commit;