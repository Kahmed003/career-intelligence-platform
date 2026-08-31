
/*
Migration: 20260721011200_create_notes_and_knowledge.sql
Purpose: Create reusable Notes and Knowledge domain.
*/
begin;

create table if not exists public.notes_knowledge (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    note_type text not null default 'general'
        check (
            note_type in (
                'general',
                'company_research',
                'person_research',
                'networking',
                'meeting',
                'interview_prep',
                'application',
                'market_research',
                'technical',
                'academic',
                'reflection',
                'strategy',
                'idea',
                'other'
            )
        ),

    content text not null
        check (length(btrim(content)) > 0),

    summary text
        check (
            summary is null
            or length(btrim(summary)) > 0
        ),

    source_type text not null default 'user'
        check (
            source_type in (
                'user',
                'conversation',
                'meeting',
                'email',
                'website',
                'document',
                'article',
                'research',
                'system',
                'other'
            )
        ),

    source_name text
        check (
            source_name is null
            or length(btrim(source_name)) > 0
        ),

    source_url text
        check (
            source_url is null
            or source_url ~* '^https?://'
        ),

    source_occurred_at timestamptz,
    captured_at timestamptz not null default statement_timestamp(),

    confidence_score numeric(5,4)
        check (
            confidence_score is null
            or confidence_score between 0 and 1
        ),

    is_pinned boolean not null default false,
    is_archived boolean not null default false,

    metadata jsonb not null default '{}'::jsonb
        check (jsonb_typeof(metadata) = 'object'),

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp()
);

comment on table public.notes_knowledge is
'Reusable notes, research, reflections, meeting context, and knowledge records linked through the relationship graph.';

drop trigger if exists trg_notes_knowledge__set_updated_at
on public.notes_knowledge;

create trigger trg_notes_knowledge__set_updated_at
before update on public.notes_knowledge
for each row
execute function private.set_updated_at();

create or replace function private.validate_note_knowledge_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
begin
    select object_type
      into v_type
      from public.objects
     where id = new.id
       and deleted_at is null;

    if not found then
        raise exception 'Canonical object % does not exist or is deleted.', new.id
            using errcode = '23503';
    end if;

    if v_type <> 'note' then
        raise exception 'Object % must have object_type note.', new.id
            using errcode = '23514';
    end if;

    new.content := btrim(new.content);

    if new.summary is not null then
        new.summary := btrim(new.summary);
    end if;

    if new.source_name is not null then
        new.source_name := btrim(new.source_name);
    end if;

    return new;
end;
$$;

drop trigger if exists trg_notes_knowledge__validate
on public.notes_knowledge;

create trigger trg_notes_knowledge__validate
before insert or update
on public.notes_knowledge
for each row
execute function private.validate_note_knowledge_object();

create index if not exists ix_notes_knowledge__type
    on public.notes_knowledge(note_type);

create index if not exists ix_notes_knowledge__captured
    on public.notes_knowledge(captured_at desc);

create index if not exists ix_notes_knowledge__source_occurred
    on public.notes_knowledge(source_occurred_at desc)
    where source_occurred_at is not null;

create index if not exists ix_notes_knowledge__pinned
    on public.notes_knowledge(captured_at desc)
    where is_pinned = true
      and is_archived = false;

create index if not exists ix_notes_knowledge__active
    on public.notes_knowledge(note_type, captured_at desc)
    where is_archived = false;

create index if not exists ix_notes_knowledge__source_name_trgm
    on public.notes_knowledge
    using gin (source_name extensions.gin_trgm_ops)
    where source_name is not null;

create index if not exists ix_notes_knowledge__fts
    on public.notes_knowledge
    using gin (
        to_tsvector(
            'english',
            coalesce(summary, '') || ' ' ||
            coalesce(source_name, '') || ' ' ||
            content
        )
    );

alter table public.notes_knowledge enable row level security;

create policy notes_knowledge_select_owner
on public.notes_knowledge
for select to authenticated
using (private.is_object_owner(id));

create policy notes_knowledge_insert_owner
on public.notes_knowledge
for insert to authenticated
with check (private.is_object_owner(id));

create policy notes_knowledge_update_owner
on public.notes_knowledge
for update to authenticated
using (private.is_object_owner(id))
with check (private.is_object_owner(id));

create policy notes_knowledge_delete_owner
on public.notes_knowledge
for delete to authenticated
using (private.is_object_owner(id));

revoke all on table public.notes_knowledge from anon;
grant select, insert, update, delete
on table public.notes_knowledge
to authenticated;

commit;
