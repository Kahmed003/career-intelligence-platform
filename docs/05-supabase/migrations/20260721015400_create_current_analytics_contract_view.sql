/*
Migration: 20260721015400_create_current_analytics_contract_view.sql
Purpose: Expose one current definition per metric to application/query layers.
*/
begin;

create or replace view public.current_analytics_metric_definitions
with (security_invoker = true)
as
select
 metric_key,
 version,
 description,
 source_relation,
 known_limitations,
 effective_at
from public.analytics_metric_definitions
where is_current = true;

revoke all on public.current_analytics_metric_definitions from anon;
grant select on public.current_analytics_metric_definitions to authenticated;

comment on view public.current_analytics_metric_definitions is
'Current versioned metric contracts. known_limitations must be honored by reporting consumers.';

commit;
