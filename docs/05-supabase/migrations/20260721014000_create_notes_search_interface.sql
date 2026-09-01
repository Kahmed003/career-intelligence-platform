
/*
Migration ID: 20260721014000
Purpose: Provide canonical note search including public.objects.title.
Dependencies: 20260721013900_harden_notification_lifecycle.sql
*/
begin;

drop view if exists public.notes_knowledge_search;

create view public.notes_knowledge_search
with (security_invoker = true)
as
select
    o.owner_user_id,
    n.id,
    o.title,
    n.note_type,
    n.summary,
    n.content,
    n.source_type,
    n.source_name,
    n.source_url,
    n.source_occurred_at,
    n.captured_at,
    n.confidence_score,
    n.is_pinned,
    n.is_archived,
    to_tsvector(
        'english',
        coalesce(o.title,'') || ' ' ||
        coalesce(n.summary,'') || ' ' ||
        coalesce(n.source_name,'') || ' ' ||
        n.content
    ) as search_vector
from public.notes_knowledge n
join public.objects o
  on o.id = n.id
 and o.deleted_at is null;

comment on view public.notes_knowledge_search is
'Owner-scoped searchable Notes view combining canonical object title with note text and provenance fields.';

create or replace function public.search_notes_knowledge(
    p_query text,
    p_limit integer default 50
)
returns table (
    id uuid,
    title text,
    note_type text,
    summary text,
    content text,
    source_name text,
    captured_at timestamptz,
    rank real
)
language sql
stable
security invoker
set search_path = pg_catalog, public
as $$
    select
        s.id,
        s.title,
        s.note_type,
        s.summary,
        s.content,
        s.source_name,
        s.captured_at,
        ts_rank_cd(s.search_vector, websearch_to_tsquery('english', p_query)) as rank
    from public.notes_knowledge_search s
    where length(btrim(p_query)) > 0
      and s.search_vector @@ websearch_to_tsquery('english', p_query)
    order by rank desc, s.captured_at desc
    limit greatest(1, least(coalesce(p_limit,50), 200));
$$;

revoke all on public.notes_knowledge_search from anon;
grant select on public.notes_knowledge_search to authenticated;

revoke all on function public.search_notes_knowledge(text, integer) from public, anon;
grant execute on function public.search_notes_knowledge(text, integer) to authenticated;

commit;
