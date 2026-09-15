"use client";
import { useActionState } from "react";
import { createApplicationAction } from "@/lib/actions/applications.actions";

const initialState:any=null;

export function CreateApplicationForm(){
 const [state,action,pending]=useActionState(async(_:any,formData:FormData)=>{
  const input={
   title:String(formData.get("title")??""),
   opportunity_id:String(formData.get("opportunity_id")??""),
   organization_id:String(formData.get("organization_id")??"")||null,
   priority:Number(formData.get("priority")??3),
  };
  return createApplicationAction(input);
 },initialState);

 return <form action={action} className="card form-grid">
  <label className="field"><span>Application title</span><input name="title" required /></label>
  <label className="field"><span>Opportunity ID</span><input name="opportunity_id" required placeholder="UUID" /></label>
  <label className="field"><span>Organization ID</span><input name="organization_id" placeholder="Optional UUID" /></label>
  <label className="field"><span>Priority</span><select name="priority" defaultValue="3">{[1,2,3,4,5].map(x=><option key={x}>{x}</option>)}</select></label>
  {state && !state.ok?<div className="form-error">{state.error.message}</div>:null}
  {state?.ok?<div className="form-success">Application created.</div>:null}
  <button className="primary fit-button" disabled={pending}>{pending?"Creating…":"Create application"}</button>
 </form>;
}
