import {z} from "zod";

export const interactionTypeSchema=z.enum([
 "email","linkedin_message","phone_call","video_call","coffee_chat","in_person_meeting",
 "informational_interview","recruiter_conversation","mentor_meeting","conference_conversation",
 "career_fair","follow_up","other"
]);

export const interactionDirectionSchema=z.enum(["outbound","inbound","mutual"]);
export const interactionStatusSchema=z.enum(["planned","sent","delivered","completed","cancelled","no_response","rescheduled"]);

const optionalUuid=z.union([z.string().uuid(),z.literal(""),z.null()]).optional().transform(v=>v||null);
const optionalText=z.union([z.string(),z.literal(""),z.null()]).optional().transform(v=>v||null);

export const createInteractionSchema=z.object({
 title:z.string().trim().min(1).max(250),
 interaction_type:interactionTypeSchema,
 direction:interactionDirectionSchema.default("mutual"),
 status:interactionStatusSchema.default("completed"),
 person_id:optionalUuid,
 organization_id:optionalUuid,
 application_id:optionalUuid,
 opportunity_id:optionalUuid,
 occurred_at:optionalText,
 scheduled_for:optionalText,
 subject:optionalText,
 summary:optionalText,
 outcome:optionalText,
 follow_up_required:z.boolean().default(false),
 follow_up_at:optionalText
}).refine(v=>v.person_id||v.organization_id||v.application_id||v.opportunity_id,{
 message:"An interaction must be linked to at least one Career OS record.",
 path:["person_id"]
});
