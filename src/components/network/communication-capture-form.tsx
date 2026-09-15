"use client";
import {useActionState} from "react";
import {createInteractionAction} from "@/lib/actions/interactions.actions";

export function CommunicationCaptureForm({personId,organizationId}:{personId?:string;organizationId?:string}){
 const [state,action,pending]=useActionState(async(_:any,formData:FormData)=>{
  const type=String(formData.get("interaction_type")??"other");
  return createInteractionAction({
   title:String(formData.get("subject")??"").trim()||`${type.replaceAll("_"," ")} interaction`,
   interaction_type:type,
   direction:String(formData.get("direction")??"mutual"),
   status:String(formData.get("status")??"completed"),
   person_id:personId??null,
   organization_id:organizationId??null,
   occurred_at:String(formData.get("occurred_at")??"")||null,
   subject:String(formData.get("subject")??"")||null,
   summary:String(formData.get("summary")??"")||null,
   outcome:String(formData.get("outcome")??"")||null,
   follow_up_required:formData.get("follow_up_required")==="on",
   follow_up_at:String(formData.get("follow_up_at")??"")||null
  });
 },null as any);

 return <section className="card"><h2 className="section-title">Capture communication</h2>
  <form action={action} className="stack">
   <div className="form-two">
    <label className="field"><span>Type</span><select name="interaction_type" defaultValue="email">
     <option value="email">Email</option><option value="linkedin_message">LinkedIn message</option>
     <option value="phone_call">Phone call</option><option value="video_call">Video call</option>
     <option value="coffee_chat">Coffee chat</option><option value="in_person_meeting">In-person meeting</option>
     <option value="informational_interview">Informational interview</option><option value="recruiter_conversation">Recruiter conversation</option>
     <option value="mentor_meeting">Mentor meeting</option><option value="follow_up">Follow-up</option><option value="other">Other</option>
    </select></label>
    <label className="field"><span>Direction</span><select name="direction" defaultValue="mutual"><option value="outbound">Outbound</option><option value="inbound">Inbound</option><option value="mutual">Mutual</option></select></label>
   </div>
   <label className="field"><span>Subject</span><input name="subject"/></label>
   <label className="field"><span>Summary</span><textarea name="summary" rows={4}/></label>
   <label className="field"><span>Occurred at</span><input name="occurred_at" type="datetime-local"/></label>
   <label className="field checkbox-field"><input name="follow_up_required" type="checkbox"/><span>Follow-up required</span></label>
   <label className="field"><span>Follow-up at</span><input name="follow_up_at" type="datetime-local"/></label>
   {state&&!state.ok?<div className="form-error">{state.error.message}</div>:null}
   {state?.ok?<div className="form-success">Interaction recorded.</div>:null}
   <button className="primary" disabled={pending}>{pending?"Saving…":"Record interaction"}</button>
  </form>
 </section>;
}
