
/*
Migration: 20260721010900_create_goals_and_milestones.sql
Purpose: Create strategic Goals and Milestones planning domain.
*/
begin;

create table if not exists public.goals_milestones (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    item_kind text not null
        check (item_kind in ('goal', 'milestone')),

    parent_goal_id uuid
        references public.goals_milestones(id)
        on update restrict
        on delete set null,

    project_id uuid
        references public.projects(id)
        on update restrict
        on delete set null,

    status text not null default 'planned'
        check (
            status in (
                'planned',
                'active',
                'at_risk',
                'blocked',
                'completed',
                'cancelled',
                'archived'
            )
        ),

    priority smallint not null default 3
        check (priority between 1 and 5),

    target_date date,
    completed_at timestamptz,

    progress_percent numeric(5,2) not null default 0
        check (progress_percent between 0 and 100),

    metric_name text
        check (
            metric_name is null
            or length(btrim(metric_name)) > 0
        ),

    metric_target numeric(18,4)
        check (
            metric_target is null
            or metric_target >= 0
        ),

    metric_current numeric(18,4)
        check (
            metric_current is null
            or metric_current >= 0
        ),

    metric_unit text
        check (
            metric_unit is null
            or length(btrim(metric_unit)) > 0
        ),

    description text,
    notes text,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_goals_milestones__no_self_parent
        check (parent_goal_id is null or parent_goal_id <> id),

    constraint ck_goals_milestones__completed_timestamp
        check (
            status <> 'completed'
            or completed_at is not null
        ),

    constraint ck_goals_milestones__completed_progress
        check (
            status = 'completed'
            or progress_percent < 100
        ),

    constraint ck_goals_milestones__metric_name_required
        check (
            (metric_target is null and metric_current is null)
            or metric_name is not null
        )
);

comment on table public.goals_milestones is
'Strategic goals and measurable milestones linked to projects and career planning.';

drop trigger if exists trg_goals_milestones__set_updated_at
on public.goals_milestones;

create trigger trg_goals_milestones__set_updated_at
before update on public.goals_milestones
for each row
execute function private.set_updated_at();

create or replace function private.validate_goal_milestone_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_parent_owner uuid;
    v_parent_kind text;
    v_project_owner uuid;
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

    if v_type <> 'goal_milestone' then
        raise exception 'Object % must have object_type goal_milestone.', new.id
            using errcode = '23514';
    end if;

    if new.parent_goal_id is not null then
        select o.owner_user_id, gm.item_kind
          into v_parent_owner, v_parent_kind
          from public.objects o
          join public.goals_milestones gm
            on gm.id = o.id
         where gm.id = new.parent_goal_id
           and o.deleted_at is null;

        if not found then
            raise exception 'Parent goal % does not exist or is deleted.', new.parent_goal_id
                using errcode = '23503';
        end if;

        if v_parent_kind <> 'goal' then
            raise exception 'Parent % must have item_kind goal.', new.parent_goal_id
                using errcode = '23514';
        end if;

        if v_parent_owner <> v_owner then
            raise exception 'Parent goal and item must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.project_id is not null then
        select o.owner_user_id
          into v_project_owner
          from public.objects o
          join public.projects p
            on p.id = o.id
         where p.id = new.project_id
           and o.deleted_at is null;

        if not found then
            raise exception 'Project % does not exist or is deleted.', new.project_id
                using errcode = '23503';
        end if;

        if v_project_owner <> v_owner then
            raise exception 'Project and goal/milestone must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.item_kind = 'goal' and new.parent_goal_id is not null then
        raise exception 'Goals cannot currently be nested beneath another goal.'
            using errcode = '23514';
    end if;

    if new.metric_name is not null then
        new.metric_name := btrim(new.metric_name);
    end if;

    if new.metric_unit is not null then
        new.metric_unit := btrim(new.metric_unit);
    end if;

    return new;
end;
$$;

drop trigger if exists trg_goals_milestones__validate
on public.goals_milestones;

create trigger trg_goals_milestones__validate
before insert or update
on public.goals_milestones
for each row
execute function private.validate_goal_milestone_object();

create index if not exists ix_goals_milestones__parent_goal
    on public.goals_milestones(parent_goal_id)
    where parent_goal_id is not null;

create index if not exists ix_goals_milestones__project
    on public.goals_milestones(project_id)
    where project_id is not null;

create index if not exists ix_goals_milestones__status_priority
    on public.goals_milestones(status, priority);

create index if not exists ix_goals_milestones__target_date
    on public.goals_milestones(target_date)
    where target_date is not null
      and status not in ('completed', 'cancelled', 'archived');

create index if not exists ix_goals_milestones__kind_status
    on public.goals_milestones(item_kind, status);

alter table public.goals_milestones enable row level security;

create policy goals_milestones_select_owner
on public.goals_milestones
for select to authenticated
using (private.is_object_owner(id));

create policy goals_milestones_insert_owner
on public.goals_milestones
for insert to authenticated
with check (
    private.is_object_owner(id)
    and (
        parent_goal_id is null
        or private.is_object_owner(parent_goal_id)
    )
    and (
        project_id is null
        or private.is_object_owner(project_id)
    )
);

create policy goals_milestones_update_owner
on public.goals_milestones
for update to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and (
        parent_goal_id is null
        or private.is_object_owner(parent_goal_id)
    )
    and (
        project_id is null
        or private.is_object_owner(project_id)
    )
);

create policy goals_milestones_delete_owner
on public.goals_milestones
for delete to authenticated
using (private.is_object_owner(id));

revoke all on table public.goals_milestones from anon;
grant select, insert, update, delete
on table public.goals_milestones
to authenticated;

commit;
