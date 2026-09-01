
/*
Migration ID: 20260721013800
Purpose: Add explicit duplicate provenance and stricter discovery run/search consistency.
Dependencies: 20260721013700_fix_relationship_intelligence.sql
*/
begin;

alter table public.discovered_opportunities
    add column if not exists duplicate_of_record_id uuid
        references public.discovered_opportunities(id)
        on update restrict
        on delete set null;

alter table public.discovered_opportunities
    drop constraint if exists ck_discovered_opportunities__duplicate_reference;

alter table public.discovered_opportunities
    add constraint ck_discovered_opportunities__duplicate_reference
    check (
        (ingestion_status = 'duplicate' and duplicate_of_record_id is not null)
        or
        (ingestion_status <> 'duplicate' and duplicate_of_record_id is null)
    );

alter table public.discovered_opportunities
    drop constraint if exists ck_discovered_opportunities__no_self_duplicate;

alter table public.discovered_opportunities
    add constraint ck_discovered_opportunities__no_self_duplicate
    check (
        duplicate_of_record_id is null
        or duplicate_of_record_id <> id
    );

create or replace function private.validate_discovery_provenance()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_run_source uuid;
    v_run_search uuid;
    v_search_source uuid;
    v_duplicate_source uuid;
begin
    if new.discovery_run_id is not null then
        select discovery_source_id, saved_search_id
          into v_run_source, v_run_search
          from public.discovery_runs
         where id = new.discovery_run_id;

        if not found then
            raise exception 'Discovery run % does not exist.', new.discovery_run_id
                using errcode = '23503';
        end if;

        if v_run_source <> new.discovery_source_id then
            raise exception 'Discovered record source must match discovery run source.'
                using errcode = '23514';
        end if;

        if new.saved_search_id is not null
           and v_run_search is not null
           and new.saved_search_id <> v_run_search then
            raise exception 'Discovered record saved search must match discovery run saved search.'
                using errcode = '23514';
        end if;
    end if;

    if new.saved_search_id is not null then
        select discovery_source_id
          into v_search_source
          from public.saved_searches
         where id = new.saved_search_id;

        if not found then
            raise exception 'Saved search % does not exist.', new.saved_search_id
                using errcode = '23503';
        end if;

        if v_search_source is not null
           and v_search_source <> new.discovery_source_id then
            raise exception 'Discovered record source must match saved search source.'
                using errcode = '23514';
        end if;
    end if;

    if new.duplicate_of_record_id is not null then
        select discovery_source_id
          into v_duplicate_source
          from public.discovered_opportunities
         where id = new.duplicate_of_record_id;

        if not found then
            raise exception 'Duplicate target record % does not exist.',
                new.duplicate_of_record_id using errcode = '23503';
        end if;

        if v_duplicate_source <> new.discovery_source_id then
            raise exception 'Duplicate records must belong to the same discovery source.'
                using errcode = '23514';
        end if;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_discovered_opportunities__validate_provenance
on public.discovered_opportunities;

create trigger trg_discovered_opportunities__validate_provenance
before insert or update
on public.discovered_opportunities
for each row execute function private.validate_discovery_provenance();

create index if not exists ix_discovered_opportunities__duplicate_of
on public.discovered_opportunities(duplicate_of_record_id)
where duplicate_of_record_id is not null;

commit;
