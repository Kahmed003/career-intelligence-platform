/*
Migration: 20260721015300_create_snapshot_execution_attempts.sql
Purpose: Persist observable snapshot execution attempts without changing existing snapshot tables.
*/
begin;

create table if not exists public.analytics_snapshot_execution_attempts (
    id uuid primary key default gen_random_uuid(),
    owner_user_id uuid not null references auth.users(id) on delete cascade,
    snapshot_date date not null,
    status text not null default 'started'
      check (status in ('started','succeeded','failed')),
    started_at timestamptz not null default statement_timestamp(),
    finished_at timestamptz,
    error_code text,
    error_message text,
    metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata)='object'),
    check (
      (status='started' and finished_at is null)
      or (status in ('succeeded','failed') and finished_at is not null)
    ),
    check (
      status <> 'failed'
      or error_message is not null
    )
);

create index if not exists ix_snapshot_execution_attempts__owner_date
on public.analytics_snapshot_execution_attempts(owner_user_id, snapshot_date desc, started_at desc);

alter table public.analytics_snapshot_execution_attempts enable row level security;

drop policy if exists snapshot_execution_attempts_owner_select on public.analytics_snapshot_execution_attempts;
create policy snapshot_execution_attempts_owner_select
on public.analytics_snapshot_execution_attempts for select
to authenticated
using (owner_user_id = auth.uid());

drop policy if exists snapshot_execution_attempts_owner_insert on public.analytics_snapshot_execution_attempts;
create policy snapshot_execution_attempts_owner_insert
on public.analytics_snapshot_execution_attempts for insert
to authenticated
with check (owner_user_id = auth.uid());

drop policy if exists snapshot_execution_attempts_owner_update on public.analytics_snapshot_execution_attempts;
create policy snapshot_execution_attempts_owner_update
on public.analytics_snapshot_execution_attempts for update
to authenticated
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

revoke all on public.analytics_snapshot_execution_attempts from anon;
grant select, insert, update on public.analytics_snapshot_execution_attempts to authenticated;

commit;
