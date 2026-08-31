
/*
Migration: 20260721012200_create_saved_searches_and_discovery_sources.sql
Purpose: Create opportunity discovery sources, saved searches, runs, and staging records.
*/
begin;

create table if not exists public.discovery_sources (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    source_type text not null
        check (
            source_type in (
                'company_careers',
                'job_board',
                'university_portal',
                'professional_network',
                'newsletter',
                'recruiter',
                'conference',
                'fellowship_portal',
                'search_engine',
                'api',
                'manual',
                'other'
            )
        ),

    name text not null
        check (length(btrim(name)) > 0),

    base_url text
        check (
            base_url is null
            or base_url ~* '^https?://'
        ),

    organization_id uuid
        references public.organizations(id)
        on update restrict
        on delete set null,

    is_active boolean not null default true,

    trust_level text not null default 'unknown'
        check (
            trust_level in ('high', 'medium', 'low', 'unknown')
        ),

    notes text,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp()
);

create table if not exists public.saved_searches (
    id uuid primary key
        references public.objects(id)
        on update restrict
        on delete restrict,

    discovery_source_id uuid
        references public.discovery_sources(id)
        on update restrict
        on delete set null,

    preference_profile_id uuid
        references public.career_preference_profiles(id)
        on update restrict
        on delete set null,

    name text not null
        check (length(btrim(name)) > 0),

    query_text text,

    filters jsonb not null default '{}'::jsonb
        check (jsonb_typeof(filters) = 'object'),

    schedule_hint text,
    is_active boolean not null default true,

    last_run_at timestamptz,
    next_run_at timestamptz,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp()
);

create table if not exists public.discovery_runs (
    id uuid primary key default gen_random_uuid(),

    saved_search_id uuid
        references public.saved_searches(id)
        on update restrict
        on delete set null,

    discovery_source_id uuid not null
        references public.discovery_sources(id)
        on update restrict
        on delete restrict,

    started_at timestamptz not null default statement_timestamp(),
    completed_at timestamptz,

    status text not null default 'queued'
        check (
            status in (
                'queued',
                'running',
                'completed',
                'partial',
                'failed',
                'cancelled'
            )
        ),

    records_seen integer not null default 0 check (records_seen >= 0),
    records_created integer not null default 0 check (records_created >= 0),
    records_updated integer not null default 0 check (records_updated >= 0),
    records_skipped integer not null default 0 check (records_skipped >= 0),

    error_message text,

    metadata jsonb not null default '{}'::jsonb
        check (jsonb_typeof(metadata) = 'object'),

    constraint ck_discovery_runs__time_order
        check (
            completed_at is null
            or completed_at >= started_at
        ),

    constraint ck_discovery_runs__terminal_completion
        check (
            status not in ('completed', 'partial', 'failed', 'cancelled')
            or completed_at is not null
        )
);

create table if not exists public.discovered_opportunities (
    id uuid primary key default gen_random_uuid(),

    discovery_source_id uuid not null
        references public.discovery_sources(id)
        on update restrict
        on delete restrict,

    discovery_run_id uuid
        references public.discovery_runs(id)
        on update restrict
        on delete set null,

    saved_search_id uuid
        references public.saved_searches(id)
        on update restrict
        on delete set null,

    external_id text,
    external_url text
        check (
            external_url is null
            or external_url ~* '^https?://'
        ),

    dedupe_key text,

    raw_title text not null
        check (length(btrim(raw_title)) > 0),

    raw_organization_name text,
    raw_location text,
    raw_description text,

    raw_payload jsonb not null default '{}'::jsonb
        check (jsonb_typeof(raw_payload) = 'object'),

    published_at timestamptz,
    discovered_at timestamptz not null default statement_timestamp(),

    ingestion_status text not null default 'new'
        check (
            ingestion_status in (
                'new',
                'reviewing',
                'promoted',
                'duplicate',
                'ignored',
                'invalid'
            )
        ),

    promoted_opportunity_id uuid
        references public.opportunities(id)
        on update restrict
        on delete set null,

    created_at timestamptz not null default statement_timestamp(),
    updated_at timestamptz not null default statement_timestamp(),

    constraint ck_discovered_opportunities__promoted_reference
        check (
            ingestion_status <> 'promoted'
            or promoted_opportunity_id is not null
        )
);

comment on table public.discovery_sources is
'Governed external and manual sources from which opportunities are discovered.';

comment on table public.saved_searches is
'Reusable opportunity discovery queries and filter definitions.';

comment on table public.discovery_runs is
'Execution history for saved searches and source scans.';

comment on table public.discovered_opportunities is
'Staging records preserving raw opportunity discovery provenance before canonical promotion.';

drop trigger if exists trg_discovery_sources__set_updated_at
on public.discovery_sources;

create trigger trg_discovery_sources__set_updated_at
before update on public.discovery_sources
for each row execute function private.set_updated_at();

drop trigger if exists trg_saved_searches__set_updated_at
on public.saved_searches;

create trigger trg_saved_searches__set_updated_at
before update on public.saved_searches
for each row execute function private.set_updated_at();

drop trigger if exists trg_discovered_opportunities__set_updated_at
on public.discovered_opportunities;

create trigger trg_discovered_opportunities__set_updated_at
before update on public.discovered_opportunities
for each row execute function private.set_updated_at();

create or replace function private.validate_discovery_source()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_linked_owner uuid;
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

    if v_type <> 'discovery_source' then
        raise exception 'Object % must have object_type discovery_source.', new.id
            using errcode = '23514';
    end if;

    if new.organization_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.organization_id
           and object_type = 'organization'
           and deleted_at is null;

        if not found then
            raise exception 'Organization % does not exist or is deleted.',
                new.organization_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Discovery source and organization must share owner.'
                using errcode = '42501';
        end if;
    end if;

    new.name := btrim(new.name);

    if new.base_url is not null then
        new.base_url := btrim(new.base_url);
    end if;

    return new;
end;
$$;

drop trigger if exists trg_discovery_sources__validate
on public.discovery_sources;

create trigger trg_discovery_sources__validate
before insert or update on public.discovery_sources
for each row execute function private.validate_discovery_source();

create or replace function private.validate_saved_search()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_linked_owner uuid;
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

    if v_type <> 'saved_search' then
        raise exception 'Object % must have object_type saved_search.', new.id
            using errcode = '23514';
    end if;

    if new.discovery_source_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.discovery_source_id
           and object_type = 'discovery_source'
           and deleted_at is null;

        if not found then
            raise exception 'Discovery source % does not exist or is deleted.',
                new.discovery_source_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Saved search and discovery source must share owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.preference_profile_id is not null then
        select owner_user_id
          into v_linked_owner
          from public.objects
         where id = new.preference_profile_id
           and object_type = 'career_preference_profile'
           and deleted_at is null;

        if not found then
            raise exception 'Preference profile % does not exist or is deleted.',
                new.preference_profile_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Saved search and preference profile must share owner.'
                using errcode = '42501';
        end if;
    end if;

    new.name := btrim(new.name);

    if new.query_text is not null then
        new.query_text := btrim(new.query_text);
        if new.query_text = '' then new.query_text := null; end if;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_saved_searches__validate
on public.saved_searches;

create trigger trg_saved_searches__validate
before insert or update on public.saved_searches
for each row execute function private.validate_saved_search();

create or replace function private.validate_discovery_run()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_source_owner uuid;
    v_search_owner uuid;
    v_search_source uuid;
begin
    select owner_user_id
      into v_source_owner
      from public.objects
     where id = new.discovery_source_id
       and object_type = 'discovery_source'
       and deleted_at is null;

    if not found then
        raise exception 'Discovery source % does not exist or is deleted.',
            new.discovery_source_id
            using errcode = '23503';
    end if;

    if new.saved_search_id is not null then
        select o.owner_user_id, s.discovery_source_id
          into v_search_owner, v_search_source
          from public.objects o
          join public.saved_searches s on s.id = o.id
         where s.id = new.saved_search_id
           and o.deleted_at is null;

        if not found then
            raise exception 'Saved search % does not exist or is deleted.',
                new.saved_search_id
                using errcode = '23503';
        end if;

        if v_search_owner <> v_source_owner then
            raise exception 'Discovery run source and saved search must share owner.'
                using errcode = '42501';
        end if;

        if v_search_source is not null
           and v_search_source <> new.discovery_source_id then
            raise exception 'Discovery run source must match saved search source.'
                using errcode = '23514';
        end if;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_discovery_runs__validate
on public.discovery_runs;

create trigger trg_discovery_runs__validate
before insert or update on public.discovery_runs
for each row execute function private.validate_discovery_run();

create or replace function private.validate_discovered_opportunity()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_owner uuid;
    v_run_source uuid;
    v_search_owner uuid;
    v_promoted_owner uuid;
begin
    select owner_user_id
      into v_owner
      from public.objects
     where id = new.discovery_source_id
       and object_type = 'discovery_source'
       and deleted_at is null;

    if not found then
        raise exception 'Discovery source % does not exist or is deleted.',
            new.discovery_source_id
            using errcode = '23503';
    end if;

    if new.discovery_run_id is not null then
        select discovery_source_id
          into v_run_source
          from public.discovery_runs
         where id = new.discovery_run_id;

        if not found then
            raise exception 'Discovery run % does not exist.',
                new.discovery_run_id
                using errcode = '23503';
        end if;

        if v_run_source <> new.discovery_source_id then
            raise exception 'Discovered opportunity source must match discovery run source.'
                using errcode = '23514';
        end if;
    end if;

    if new.saved_search_id is not null then
        select o.owner_user_id
          into v_search_owner
          from public.objects o
          join public.saved_searches s on s.id = o.id
         where s.id = new.saved_search_id
           and o.deleted_at is null;

        if not found then
            raise exception 'Saved search % does not exist or is deleted.',
                new.saved_search_id
                using errcode = '23503';
        end if;

        if v_search_owner <> v_owner then
            raise exception 'Discovered opportunity and saved search must share owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.promoted_opportunity_id is not null then
        select owner_user_id
          into v_promoted_owner
          from public.objects
         where id = new.promoted_opportunity_id
           and object_type = 'opportunity'
           and deleted_at is null;

        if not found then
            raise exception 'Promoted opportunity % does not exist or is deleted.',
                new.promoted_opportunity_id
                using errcode = '23503';
        end if;

        if v_promoted_owner <> v_owner then
            raise exception 'Promoted opportunity must share discovery owner.'
                using errcode = '42501';
        end if;
    end if;

    new.raw_title := btrim(new.raw_title);

    if new.external_id is not null then
        new.external_id := btrim(new.external_id);
        if new.external_id = '' then new.external_id := null; end if;
    end if;

    if new.dedupe_key is not null then
        new.dedupe_key := btrim(new.dedupe_key);
        if new.dedupe_key = '' then new.dedupe_key := null; end if;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_discovered_opportunities__validate
on public.discovered_opportunities;

create trigger trg_discovered_opportunities__validate
before insert or update on public.discovered_opportunities
for each row execute function private.validate_discovered_opportunity();

create unique index if not exists ux_discovered_opportunities__source_external
    on public.discovered_opportunities(discovery_source_id, external_id)
    where external_id is not null;

create unique index if not exists ux_discovered_opportunities__source_dedupe
    on public.discovered_opportunities(discovery_source_id, dedupe_key)
    where dedupe_key is not null;

create index if not exists ix_discovery_sources__active_type
    on public.discovery_sources(source_type, trust_level)
    where is_active = true;

create index if not exists ix_saved_searches__active_next_run
    on public.saved_searches(next_run_at)
    where is_active = true;

create index if not exists ix_saved_searches__preference_profile
    on public.saved_searches(preference_profile_id)
    where preference_profile_id is not null;

create index if not exists ix_discovery_runs__source_started
    on public.discovery_runs(discovery_source_id, started_at desc);

create index if not exists ix_discovery_runs__search_started
    on public.discovery_runs(saved_search_id, started_at desc)
    where saved_search_id is not null;

create index if not exists ix_discovered_opportunities__status_time
    on public.discovered_opportunities(ingestion_status, discovered_at desc);

create index if not exists ix_discovered_opportunities__run
    on public.discovered_opportunities(discovery_run_id)
    where discovery_run_id is not null;

create index if not exists ix_discovered_opportunities__promoted
    on public.discovered_opportunities(promoted_opportunity_id)
    where promoted_opportunity_id is not null;

alter table public.discovery_sources enable row level security;
alter table public.saved_searches enable row level security;
alter table public.discovery_runs enable row level security;
alter table public.discovered_opportunities enable row level security;

create policy discovery_sources_owner_all
on public.discovery_sources
for all to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and (organization_id is null or private.is_object_owner(organization_id))
);

create policy saved_searches_owner_all
on public.saved_searches
for all to authenticated
using (private.is_object_owner(id))
with check (
    private.is_object_owner(id)
    and (discovery_source_id is null or private.is_object_owner(discovery_source_id))
    and (preference_profile_id is null or private.is_object_owner(preference_profile_id))
);

create policy discovery_runs_owner_all
on public.discovery_runs
for all to authenticated
using (private.is_object_owner(discovery_source_id))
with check (
    private.is_object_owner(discovery_source_id)
    and (saved_search_id is null or private.is_object_owner(saved_search_id))
);

create policy discovered_opportunities_owner_all
on public.discovered_opportunities
for all to authenticated
using (private.is_object_owner(discovery_source_id))
with check (
    private.is_object_owner(discovery_source_id)
    and (saved_search_id is null or private.is_object_owner(saved_search_id))
    and (promoted_opportunity_id is null or private.is_object_owner(promoted_opportunity_id))
);

revoke all on public.discovery_sources from anon;
revoke all on public.saved_searches from anon;
revoke all on public.discovery_runs from anon;
revoke all on public.discovered_opportunities from anon;

grant select, insert, update, delete on public.discovery_sources to authenticated;
grant select, insert, update, delete on public.saved_searches to authenticated;
grant select, insert, update, delete on public.discovery_runs to authenticated;
grant select, insert, update, delete on public.discovered_opportunities to authenticated;

commit;
