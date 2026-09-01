
begin;

create or replace function private.validate_application_material_role()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_object_type text;
    v_document_type text;
    v_content_type text;
    v_resume_ready boolean;
    v_cover_ready boolean;
begin
    select object_type into v_object_type
    from public.objects
    where id = new.object_id
      and deleted_at is null;

    if not found then
        raise exception 'Material object % is unavailable.', new.object_id
            using errcode='23503';
    end if;

    if v_object_type = 'document' then
        select document_type into v_document_type
        from public.documents
        where id = new.object_id;

        if new.material_role='resume' and v_document_type <> 'resume' then
            raise exception 'Resume role requires document_type resume.' using errcode='23514';
        elsif new.material_role='cover_letter' and v_document_type <> 'cover_letter' then
            raise exception 'Cover-letter role requires document_type cover_letter.' using errcode='23514';
        elsif new.material_role='transcript' and v_document_type <> 'transcript' then
            raise exception 'Transcript role requires document_type transcript.' using errcode='23514';
        elsif new.material_role='writing_sample' and v_document_type <> 'writing_sample' then
            raise exception 'Writing-sample role requires document_type writing_sample.' using errcode='23514';
        elsif new.material_role='portfolio' and v_document_type <> 'portfolio' then
            raise exception 'Portfolio role requires document_type portfolio.' using errcode='23514';
        elsif new.material_role='certificate' and v_document_type <> 'certificate' then
            raise exception 'Certificate role requires document_type certificate.' using errcode='23514';
        elsif new.material_role='reference' and v_document_type <> 'reference' then
            raise exception 'Reference role requires document_type reference.' using errcode='23514';
        end if;

    elsif v_object_type = 'resume_content' then
        select content_type,is_resume_ready,is_cover_letter_ready
          into v_content_type,v_resume_ready,v_cover_ready
        from public.resume_content
        where id = new.object_id;

        if new.material_role='resume' and v_resume_ready <> true then
            raise exception 'Structured resume material must be resume-ready.' using errcode='23514';
        elsif new.material_role='cover_letter' and v_cover_ready <> true then
            raise exception 'Structured cover-letter material must be cover-letter-ready.' using errcode='23514';
        elsif new.material_role='application_response' and v_content_type <> 'application_response' then
            raise exception 'Application-response role requires matching content type.' using errcode='23514';
        elsif new.material_role in ('transcript','writing_sample','portfolio','certificate','reference') then
            raise exception 'Material role % requires a governed Document object.', new.material_role
                using errcode='23514';
        end if;
    else
        raise exception 'Material item must reference document or resume_content.'
            using errcode='23514';
    end if;

    return new;
end;
$$;

drop trigger if exists trg_application_material_items__validate_role
on public.application_material_items;

create trigger trg_application_material_items__validate_role
before insert or update of object_id,material_role
on public.application_material_items
for each row execute function private.validate_application_material_role();

commit;
