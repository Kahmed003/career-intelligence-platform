
begin;

insert into public.relationship_types
(code, display_name, description, directionality, source_object_types, target_object_types)
values
('supported_by','Supported By','Source is substantiated by evidence, knowledge, or a document.','directed',
 array['application','opportunity','project','resume_content','goal_milestone','skill'],
 array['evidence_achievement','note','document']),
('produced','Produced','Source produced the target artifact or evidence.','directed',
 array['project','experience','education','career_campaign'],
 array['evidence_achievement','document','resume_content']),
('verified_by','Verified By','Evidence or claim is verified by a person, organization, or document.','directed',
 array['evidence_achievement','resume_content','skill'],
 array['person','organization','document']),
('issued_by','Issued By','Evidence, credential, or offer was issued by an organization.','directed',
 array['evidence_achievement','opportunity','offer'],
 array['organization']),
('attached_to','Attached To','Document is attached to another Career OS object.','directed',
 array['document'],
 array['application','opportunity','offer','project','experience','education','evidence_achievement','resume_profile','material_set','career_campaign']),
('variant_of','Variant Of','Structured content is a tailored or derived variant of another content object.','directed',
 array['resume_content'], array['resume_content']),
('scheduled_for','Scheduled For','Calendar event is scheduled for or derived from another Career OS object.','directed',
 array['calendar_event'],
 array['application','opportunity','interview_assessment','offer','task','project','interaction','career_campaign']),
('member_of','Member Of','Source object participates in a Career Campaign.','directed',
 array['opportunity','application','person','organization','task','interaction','saved_search','project'],
 array['career_campaign'])
on conflict (code) do update
set display_name = excluded.display_name,
    description = excluded.description,
    directionality = excluded.directionality,
    source_object_types = excluded.source_object_types,
    target_object_types = excluded.target_object_types,
    is_active = true,
    updated_at = statement_timestamp();

commit;
