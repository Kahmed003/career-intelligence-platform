
/*
Migration: 20260721011700_create_resume_content.sql
Purpose: Create reusable resume content and professional narrative records.
*/
begin;

create table if not exists public.resume_content (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    content_type text not null
        check (
            content_type in (
                'resume_bullet',
                'achievement_statement',
                'professional_summary',
                'project_summary',
                'experience_summary',
                'leadership_story',
                'technical_narrative',
                'career_narrative',
                'short_bio',
                'interview_story',
                'cover_letter_paragraph',
                'application_response',
                'other'
            )
        ),

    content_text text not null
        check (length(btrim(content_text)) > 0),

    content_status text not null default 'draft'
        check (
            content_status in (
                'draft',
                'review',
                'approved',
                'superseded',
                'archived'
            )
        ),

    tone text not null default 'neutral'
        check (
            tone in (
                'neutral',
                'concise',
                'technical',
                'quantitative',
                'executive',
                'consulting',
                'academic',
                'conversational',
                'other'
            )
        ),

    target_function text
        check (
            target_function is null
            or length(btrim(target_function)) > 0
        ),

    target_role_family text
        check (
            target_role_family is null
            or length(btrim(target_role_family)) > 0
        ),

    target_industry text
        check (
            target_industry is null
            or length(btrim(target_industry)) > 0
        ),

    source_object_id uuid
        references public.objects(id)
        on update restrict
        on delete set null,

    evidence_object_id uuid
        references public.evidence_achievements(id)
        on update restrict
        on delete set null,

    word_count integer not null default 0
        check (word_count >= 0),

    character_count integer not null default 0
        check (character_count >= 0),

    impact_score numeric(5,2)
        check (
            impact_score is null
            or impact_score between 0 and 100
        ),

    is_master_version boolean not null default false,
    is_resume_ready boolean not null default false,
    is_cover_letter_ready boolean not null default false,
    is_interview_ready boolean not null default false,

    metadata jsonb not null default '{}'::jsonb
        check (jsonb_typeof(metadata) = 'object'),

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_resume_content__ready_requires_approved
        check (
            (
                is_resume_ready = false
                and is_cover_letter_ready = false
                and is_interview_ready = false
            )
            or content_status = 'approved'
        )
);

comment on table public.resume_content is
'Reusable resume bullets, professional summaries, application responses, and career narratives.';

drop trigger if exists trg_resume_content__set_updated_at
on public.resume_content;

create trigger trg_resume_content__set_updated_at
before update on public.resume_content
for each row
execute function private.set_updated_at();

create or replace function private.validate_resume_content_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_linked_owner uuid;
    v_evidence_type text;
begin
    select object_type, owner_user_id
      into v_type, v_owner
      from public.objects
     where id = new.id
       and deleted_at is null;

    if not found then
        raise exception 'Canonical object % does not exist or is deleted.', new.id
            using errcode = '23503';
    end if;

    if v_type <> 'resume_content' then
        raise exception 'Object % must have object_type resume_content.', new.id
            using errcode = '23514';
    end if;

    new.content_text := btrim(new.content_text);

    new.character_count := char_length(new.content_text);

    new.word_count :=
        case
            when new.content_text = '' then 0
            else cardinality(
                regexp_split_to_array(
                    regexp_replace(new.content_text, '\s+', ' ', 'g'),
                    '\s+'
                )
            )
        end;

    if new.target_function is not null then
        new.target_function := lower(btrim(new.target_function));
    end if;

    if new.target_role_family is not null then
        new.target_role_family := btrim(new.target_role_family);
    end if;

    if new.target_industry is not null then
        new.target_industry := btrim(new.target_industry);
    end if;

    if new.source_object_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.source_object_id
           and deleted_at is null;

        if not found then
            raise exception 'Source object % does not exist or is deleted.',
                new.source_object_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Resume content and source object must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.evidence_object_id is not null then
        select object_type, owner_user_id
          into v_evidence_type, v_linked_owner
          from public.objects
         where id = new.evidence_object_id
           and deleted_at is null;

        if not found then
            raise exception 'Evidence object % does not exist or is deleted.',
                new.evidence_object_id
                using errcode = '23503';
        end if;

        if v_evidence_type <> 'evidence_achievement' then
            raise exception 'Evidence object % must have object_type evidence_achievement.',
                new.evidence_object_id
                using errcode = '23514';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Resume content and evidence must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_resume_content__validate
on public.resume_content;

create trigger trg_resume_content__validate
before insert or update
on public.resume_content
for each row
execute function private.validate_resume_content_object();

create index if not exists ix_resume_content__type_status
    on public.resume_content(content_type, content_status);

create index if not exists ix_resume_content__source
    on public.resume_content(source_object_id, content_type)
    where source_object_id is not null;

create index if not exists ix_resume_content__evidence
    on public.resume_content(evidence_object_id)
    where evidence_object_id is not null;

create index if not exists ix_resume_content__target_function
    on public.resume_content(target_function, content_type)
    where target_function is not null;

create index if not exists ix_resume_content__master
    on public.resume_content(content_type, updated_at desc)
    where is_master_version = true
      and content_status = 'approved';

create index if not exists ix_resume_content__resume_ready
    on public.resume_content(impact_score desc nulls last, updated_at desc)
    where is_resume_ready = true
      and content_status = 'approved';

create index if not exists ix_resume_content__cover_letter_ready
    on public.resume_content(updated_at desc)
    where is_cover_letter_ready = true
      and content_status = 'approved';

create index if not exists ix_resume_content__interview_ready
    on public.resume_content(updated_at desc)
    where is_interview_ready = true
      and content_status = 'approved';

create index if not exists ix_resume_content__impact
    on public.resume_content(impact_score desc)
    where impact_score is not null;

alter table public.resume_content enable row level security;

create policy resume_content_select_owner
on public.resume_content
for select to authenticated
using (private.is_object_owner(id));

create policy resume_content_insert_owner
on public.resume_content
for insert to authenticated
with check (
    private.is_object_owner(id)
    and (
        source_object_id is null
        or private.is_object_owner(source_object_id)
    )
    and (
        evidence_object_id is null
        or private.is_object_owner(evidence_object_id)
    )
);

create policy resume_content_update_owner
on public.resume_content
for update to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and (
        source_object_id is null
        or private.is_object_owner(source_object_id)
    )
    and (
        evidence_object_id is null
        or private.is_object_owner(evidence_object_id)
    )
);

create policy resume_content_delete_owner
on public.resume_content
for delete to authenticated
using (private.is_object_owner(id));

revoke all on table public.resume_content from anon;

grant select, insert, update, delete
on table public.resume_content
to authenticated;

commit;
