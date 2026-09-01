
begin;

drop view if exists public.campaign_source_performance_active;

create view public.campaign_source_performance_active
with (security_invoker = true)
as
select csp.*
from public.campaign_source_performance csp
join public.objects campaign_object
  on campaign_object.id = csp.campaign_id
 and campaign_object.object_type = 'career_campaign'
 and campaign_object.deleted_at is null
 and campaign_object.owner_user_id = csp.owner_user_id
join public.objects source_object
  on source_object.id = csp.discovery_source_id
 and source_object.object_type = 'discovery_source'
 and source_object.deleted_at is null
 and source_object.owner_user_id = csp.owner_user_id;

comment on view public.campaign_source_performance_active is
'Lifecycle-hardened Campaign Source Performance requiring active same-owner campaign and discovery-source canonical objects.';

revoke all on public.campaign_source_performance_active from anon;
grant select on public.campaign_source_performance_active to authenticated;

commit;
