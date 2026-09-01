
/*
Migration ID: 20260721013500
Purpose: Enforce Opportunity/Organization consistency for interactions.
Dependencies: 20260721013400_harden_documents_and_attachments.sql
*/
begin;

create or replace function private.validate_interaction_communication_object()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_type text;
    v_owner uuid;
    v_linked_owner uuid;
    v_application_opportunity uuid;
    v_application_org uuid;
    v_opportunity_org uuid;
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

    if v_type <> 'interaction' then
        raise exception 'Object % must have object_type interaction.', new.id
            using errcode = '23514';
    end if;

    if new.person_id is not null then
        select owner_user_id into v_linked_owner
        from public.objects
        where id = new.person_id
          and object_type = 'person'
          and deleted_at is null;

        if not found then
            raise exception 'Person % does not exist or is deleted.', new.person_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Interaction and person must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.opportunity_id is not null then
        select o.owner_user_id, op.organization_id
          into v_linked_owner, v_opportunity_org
          from public.objects o
          join public.opportunities op on op.id = o.id
         where op.id = new.opportunity_id
           and o.deleted_at is null;

        if not found then
            raise exception 'Opportunity % does not exist or is deleted.', new.opportunity_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Interaction and opportunity must have the same owner.'
                using errcode = '42501';
        end if;

        if new.organization_id is null and v_opportunity_org is not null then
            new.organization_id := v_opportunity_org;
        elsif new.organization_id is not null
          and v_opportunity_org is not null
          and new.organization_id <> v_opportunity_org then
            raise exception 'Interaction organization must match opportunity organization.'
                using errcode = '23514';
        end if;
    end if;

    if new.organization_id is not null then
        select owner_user_id into v_linked_owner
        from public.objects
        where id = new.organization_id
          and object_type = 'organization'
          and deleted_at is null;

        if not found then
            raise exception 'Organization % does not exist or is deleted.', new.organization_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Interaction and organization must have the same owner.'
                using errcode = '42501';
        end if;
    end if;

    if new.application_id is not null then
        select o.owner_user_id, a.opportunity_id, a.organization_id
          into v_linked_owner, v_application_opportunity, v_application_org
          from public.objects o
          join public.applications a on a.id = o.id
         where a.id = new.application_id
           and o.deleted_at is null;

        if not found then
            raise exception 'Application % does not exist or is deleted.', new.application_id
                using errcode = '23503';
        end if;

        if v_linked_owner <> v_owner then
            raise exception 'Interaction and application must have the same owner.'
                using errcode = '42501';
        end if;

        if new.opportunity_id is not null
           and v_application_opportunity <> new.opportunity_id then
            raise exception 'Interaction opportunity must match application opportunity.'
                using errcode = '23514';
        end if;

        if new.organization_id is not null
           and v_application_org is not null
           and v_application_org <> new.organization_id then
            raise exception 'Interaction organization must match application organization.'
                using errcode = '23514';
        end if;

        if new.opportunity_id is null then
            new.opportunity_id := v_application_opportunity;
        end if;

        if new.organization_id is null and v_application_org is not null then
            new.organization_id := v_application_org;
        end if;
    end if;

    if new.subject is not null then new.subject := nullif(btrim(new.subject), ''); end if;
    if new.summary is not null then new.summary := nullif(btrim(new.summary), ''); end if;
    if new.channel_detail is not null then new.channel_detail := nullif(btrim(new.channel_detail), ''); end if;
    if new.external_message_id is not null then new.external_message_id := nullif(btrim(new.external_message_id), ''); end if;
    if new.source_system is not null then new.source_system := nullif(lower(btrim(new.source_system)), ''); end if;

    return new;
end;
$$;

commit;
