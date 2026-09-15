/*
Migration: 20260721015200_create_analytics_metric_contracts.sql
Purpose: Version analytics definitions so historical snapshots can identify metric semantics.
*/
begin;

create table if not exists public.analytics_metric_definitions (
    metric_key text not null,
    version integer not null check (version > 0),
    description text not null,
    source_relation text not null,
    is_current boolean not null default false,
    known_limitations text,
    effective_at timestamptz not null default statement_timestamp(),
    retired_at timestamptz,
    created_at timestamptz not null default statement_timestamp(),
    primary key (metric_key, version),
    check (retired_at is null or retired_at >= effective_at)
);

create unique index if not exists uq_analytics_metric_definitions__current
on public.analytics_metric_definitions(metric_key)
where is_current = true;

insert into public.analytics_metric_definitions
(metric_key, version, description, source_relation, is_current, known_limitations)
values
(
 'campaign_performance',
 1,
 'Campaign performance metric contract inherited from the original campaign intelligence view.',
 'public.campaign_performance_summary',
 true,
 'Pending consolidation: verify soft-deleted interview/assessment and offer exclusion and deadline row counting before authoritative historical reporting.'
),
(
 'pipeline_health',
 1,
 'Pipeline health snapshot metric contract.',
 'public.pipeline_application_summary',
 true,
 null
),
(
 'relationship_health',
 1,
 'Relationship health snapshot metric contract.',
 'public.person_relationship_health',
 true,
 null
)
on conflict (metric_key, version) do nothing;

alter table public.analytics_metric_definitions enable row level security;

drop policy if exists analytics_metric_definitions_authenticated_read on public.analytics_metric_definitions;
create policy analytics_metric_definitions_authenticated_read
on public.analytics_metric_definitions for select
to authenticated
using (true);

revoke all on public.analytics_metric_definitions from anon;
grant select on public.analytics_metric_definitions to authenticated;

commit;
