/*
Migration ID: 20260721000500
Purpose: Create the governed relationship graph.
*/
begin;

create table if not exists public.relationship_types (
    code text constraint pk_relationship_types primary key,
    display_name text not null,
    description text not null,
    directionality public.relationship_directionality not null,
    source_object_types text[] not null,
    target_object_types text[] not null,
    allows_self_reference boolean not null default false,
    allows_duplicates boolean not null default false,
    is_active boolean not null default true,
    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),
    constraint ck_relationship_types__code__format
        check (code ~ '^[a-z][a-z0-9_]*$'),
    constraint ck_relationship_types__source_types__not_empty
        check (cardinality(source_object_types) > 0),
    constraint ck_relationship_types__target_types__not_empty
        check (cardinality(target_object_types) > 0)
);

drop trigger if exists trg_relationship_types__set_updated_at
on public.relationship_types;

create trigger trg_relationship_types__set_updated_at
before update on public.relationship_types
for each row execute function private.set_updated_at();

insert into public.relationship_types
(code, display_name, description, directionality, source_object_types, target_object_types)
values
('contains','Contains','Source contains target.','directed',array['project','organization','knowledge'],array['task','project','knowledge','evidence']),
('belongs_to','Belongs To','Source belongs to target.','directed',array['task','project','knowledge','evidence'],array['project','organization','knowledge']),
('associated_with','Associated With','General symmetric association.','undirected',
 array['project','task','person','organization','opportunity','application','knowledge','evidence','recommendation'],
 array['project','task','person','organization','opportunity','application','knowledge','evidence','recommendation']),
('supports','Supports','Source supports target.','directed',array['evidence','knowledge','recommendation'],array['application','opportunity','project','recommendation']),
('introduced_by','Introduced By','Source was introduced by target person.','directed',array['person','opportunity','organization'],array['person']),
('works_at','Works At','Person works at organization.','directed',array['person'],array['organization']),
('applied_to','Applied To','Application targets opportunity.','directed',array['application'],array['opportunity']),
('derived_from','Derived From','Source derives from target.','directed',array['knowledge','evidence','recommendation','application'],array['knowledge','evidence','opportunity','project']),
('related_to','Related To','General symmetric relation.','undirected',
 array['project','task','person','organization','opportunity','application','knowledge','evidence','recommendation'],
 array['project','task','person','organization','opportunity','application','knowledge','evidence','recommendation'])
on conflict (code) do nothing;

create table if not exists public.object_relationships (
    id uuid constraint pk_object_relationships primary key
        default extensions.gen_random_uuid(),
    owner_user_id uuid not null
        constraint fk_object_relationships__owner__profiles
        references public.profiles(id) on delete restrict,
    relationship_type_code text not null
        constraint fk_object_relationships__type__relationship_types
        references public.relationship_types(code) on delete restrict,
    source_object_id uuid not null
        constraint fk_object_relationships__source__objects
        references public.objects(id) on delete restrict,
    target_object_id uuid not null
        constraint fk_object_relationships__target__objects
        references public.objects(id) on delete restrict,
    valid_from timestamptz,
    valid_to timestamptz,
    confidence numeric(5,4),
    source_system text,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),
    deleted_at timestamptz,
    constraint ck_object_relationships__valid_range
        check (valid_to is null or valid_from is null or valid_to >= valid_from),
    constraint ck_object_relationships__confidence
        check (confidence is null or confidence between 0 and 1),
    constraint ck_object_relationships__metadata_object
        check (jsonb_typeof(metadata) = 'object')
);

create or replace function private.validate_object_relationship()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type public.relationship_types%rowtype;
    v_source_type text;
    v_source_owner uuid;
    v_target_type text;
    v_target_owner uuid;
    v_swap uuid;
begin
    select * into v_type
    from public.relationship_types
    where code = new.relationship_type_code and is_active;

    if not found then
        raise exception 'Inactive or missing relationship type.';
    end if;

    select object_type, owner_user_id
    into v_source_type, v_source_owner
    from public.objects
    where id = new.source_object_id and deleted_at is null;

    select object_type, owner_user_id
    into v_target_type, v_target_owner
    from public.objects
    where id = new.target_object_id and deleted_at is null;

    if v_source_owner <> new.owner_user_id
       or v_target_owner <> new.owner_user_id then
        raise exception 'Owner must own both endpoints.';
    end if;

    if not (v_source_type = any(v_type.source_object_types))
       or not (v_target_type = any(v_type.target_object_types)) then
        raise exception 'Endpoint object types are not allowed.';
    end if;

    if new.source_object_id = new.target_object_id
       and not v_type.allows_self_reference then
        raise exception 'Self-reference is not allowed.';
    end if;

    if v_type.directionality = 'undirected'
       and new.source_object_id > new.target_object_id then
        v_swap := new.source_object_id;
        new.source_object_id := new.target_object_id;
        new.target_object_id := v_swap;
    end if;

    if not v_type.allows_duplicates and exists (
        select 1 from public.object_relationships r
        where r.owner_user_id = new.owner_user_id
          and r.relationship_type_code = new.relationship_type_code
          and r.source_object_id = new.source_object_id
          and r.target_object_id = new.target_object_id
          and r.deleted_at is null
          and r.id <> new.id
    ) then
        raise exception 'Equivalent relationship already exists.';
    end if;

    return new;
end;
$$;

drop trigger if exists trg_object_relationships__validate
on public.object_relationships;

create trigger trg_object_relationships__validate
before insert or update on public.object_relationships
for each row execute function private.validate_object_relationship();

drop trigger if exists trg_object_relationships__set_updated_at
on public.object_relationships;

create trigger trg_object_relationships__set_updated_at
before update on public.object_relationships
for each row execute function private.set_updated_at();

create index if not exists ix_object_relationships__source
on public.object_relationships(source_object_id, relationship_type_code)
where deleted_at is null;

create index if not exists ix_object_relationships__target
on public.object_relationships(target_object_id, relationship_type_code)
where deleted_at is null;

create index if not exists ix_object_relationships__owner
on public.object_relationships(owner_user_id, created_at desc)
where deleted_at is null;

alter table public.relationship_types enable row level security;
alter table public.object_relationships enable row level security;

create policy relationship_types_select_authenticated
on public.relationship_types for select to authenticated
using (is_active = true);

create policy object_relationships_select_own
on public.object_relationships for select to authenticated
using (owner_user_id = auth.uid());

create policy object_relationships_insert_own
on public.object_relationships for insert to authenticated
with check (owner_user_id = auth.uid());

create policy object_relationships_update_own
on public.object_relationships for update to authenticated
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

create policy object_relationships_delete_own
on public.object_relationships for delete to authenticated
using (owner_user_id = auth.uid());

revoke all on public.relationship_types from anon;
revoke all on public.object_relationships from anon;
grant select on public.relationship_types to authenticated;
grant select, insert, update, delete on public.object_relationships to authenticated;

commit;
