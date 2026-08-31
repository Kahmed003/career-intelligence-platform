
/*
Migration: 20260721010700_create_interviews_and_assessments.sql
Purpose: Create discrete recruiting-process events for applications.
*/
begin;

create table if not exists public.interviews_assessments (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    application_id uuid not null
        references public.applications(id)
        on update restrict
        on delete restrict,

    event_kind text not null
        check (event_kind in ('interview', 'assessment')),

    round_number smallint
        check (round_number is null or round_number > 0),

    stage_name text
        check (stage_name is null or length(btrim(stage_name)) > 0),

    interview_type text
        check (
            interview_type is null
            or interview_type in (
                'recruiter_screen',
                'behavioral',
                'technical',
                'case',
                'quantitative',
                'hiring_manager',
                'panel',
                'superday',
                'final_round',
                'informational',
                'other'
            )
        ),

    assessment_type text
        check (
            assessment_type is null
            or assessment_type in (
                'coding',
                'quantitative',
                'take_home',
                'written',
                'case',
                'personality',
                'situational_judgment',
                'video',
                'other'
            )
        ),

    status text not null default 'planned'
        check (
            status in (
                'planned',
                'scheduled',
                'in_progress',
                'completed',
                'cancelled',
                'missed'
            )
        ),

    scheduled_start_at timestamptz,
    scheduled_end_at timestamptz,
    deadline_at timestamptz,
    completed_at timestamptz,

    location_text text
        check (
            location_text is null
            or length(btrim(location_text)) > 0
        ),

    meeting_url text
        check (
            meeting_url is null
            or meeting_url ~* '^https?://'
        ),

    primary_interviewer_person_id uuid
        references public.people(id)
        on update restrict
        on delete set null,

    score numeric(10, 2)
        check (score is null or score >= 0),

    score_max numeric(10, 2)
        check (score_max is null or score_max > 0),

    result text not null default 'pending'
        check (
            result in (
                'pending',
                'passed',
                'failed',
                'advanced',
                'rejected',
                'completed_no_score',
                'unknown'
            )
        ),

    preparation_notes text,
    feedback_notes text,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_interviews_assessments__schedule_order
        check (
            scheduled_start_at is null
            or scheduled_end_at is null
            or scheduled_end_at >= scheduled_start_at
        ),

    constraint ck_interviews_assessments__completed_timestamp
        check (
            status <> 'completed'
            or completed_at is not null
        ),

    constraint ck_interviews_assessments__score_range
        check (
            score is null
            or score_max is null
            or score <= score_max
        ),

    constraint ck_interviews_assessments__kind_fields
        check (
            (event_kind = 'interview' and assessment_type is null)
            or
            (event_kind = 'assessment' and interview_type is null)
        )
);

comment on table public.interviews_assessments is
'Interview and assessment events attached to applications.';

drop trigger if exists trg_interviews_assessments__set_updated_at
on public.interviews_assessments;

create trigger trg_interviews_assessments__set_updated_at
before update on public.interviews_assessments
for each row
execute function private.set_updated_at();

create or replace function private.validate_interview_assessment_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_application_owner uuid;
    v_person_owner uuid;
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

    if v_type <> 'interview_assessment' then
        raise exception 'Object % must have object_type interview_assessment.', new.id
            using errcode = '23514';
    end if;

    select o.owner_user_id
      into v_application_owner
      from public.objects o
      join public.applications a on a.id = o.id
     where a.id = new.application_id
       and o.deleted_at is null;

    if not found then
        raise exception 'Application % does not exist or is deleted.', new.application_id
            using errcode = '23503';
    end if;

    if v_application_owner <> v_owner then
        raise exception 'Application and process event must have the same owner.'
            using errcode = '42501';
    end if;

    if new.primary_interviewer_person_id is not null then
        select owner_user_id
          into v_person_owner
          from public.objects
         where id = new.primary_interviewer_person_id
           and object_type = 'person'
           and deleted_at is null;

        if not found then
            raise exception 'Interviewer person % does not exist or is deleted.',
                new.primary_interviewer_person_id
                using errcode = '23503';
        end if;

        if v_person_owner <> v_owner then
            raise exception 'Interviewer and process event must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.stage_name is not null then
        new.stage_name := btrim(new.stage_name);
    end if;

    if new.location_text is not null then
        new.location_text := btrim(new.location_text);
    end if;

    return new;
end;
$$;

drop trigger if exists trg_interviews_assessments__validate
on public.interviews_assessments;

create trigger trg_interviews_assessments__validate
before insert or update
on public.interviews_assessments
for each row
execute function private.validate_interview_assessment_object();

create index if not exists ix_interviews_assessments__application_round
    on public.interviews_assessments(application_id, round_number, scheduled_start_at);

create index if not exists ix_interviews_assessments__scheduled_start
    on public.interviews_assessments(scheduled_start_at)
    where scheduled_start_at is not null
      and status in ('planned', 'scheduled');

create index if not exists ix_interviews_assessments__deadline
    on public.interviews_assessments(deadline_at)
    where deadline_at is not null
      and status not in ('completed', 'cancelled', 'missed');

create index if not exists ix_interviews_assessments__status_result
    on public.interviews_assessments(status, result);

create index if not exists ix_interviews_assessments__interviewer
    on public.interviews_assessments(primary_interviewer_person_id)
    where primary_interviewer_person_id is not null;

alter table public.interviews_assessments enable row level security;

create policy interviews_assessments_select_owner
on public.interviews_assessments
for select to authenticated
using (private.is_object_owner(id));

create policy interviews_assessments_insert_owner
on public.interviews_assessments
for insert to authenticated
with check (
    private.is_object_owner(id)
    and private.is_object_owner(application_id)
    and (
        primary_interviewer_person_id is null
        or private.is_object_owner(primary_interviewer_person_id)
    )
);

create policy interviews_assessments_update_owner
on public.interviews_assessments
for update to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and private.is_object_owner(application_id)
    and (
        primary_interviewer_person_id is null
        or private.is_object_owner(primary_interviewer_person_id)
    )
);

create policy interviews_assessments_delete_owner
on public.interviews_assessments
for delete to authenticated
using (private.is_object_owner(id));

revoke all on table public.interviews_assessments from anon;
grant select, insert, update, delete
on table public.interviews_assessments
to authenticated;

commit;
