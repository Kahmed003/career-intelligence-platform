"use client";
import { useActionState } from "react";
import { transitionApplicationStatusAction } from "@/lib/actions/applications.actions";

const statuses=["preparing","submitted","assessment","interviewing","offer","accepted","rejected","withdrawn","closed"];

export function StatusTransitionForm({id,currentStatus}:{id:string;currentStatus?:string|null}){
 const [state,action,pending]=useActionState(async(_:any,formData:FormData)=>{
  return transitionApplicationStatusAction({id,status:String(formData.get("status")??"")});
 },null as any);

 return <form action={action} className="stack">
  <label className="field"><span>Application status</span>
   <select name="status" defaultValue={currentStatus ?? "preparing"}>
    {statuses.map(status=><option key={status} value={status}>{status.replaceAll("_"," ")}</option>)}
   </select>
  </label>
  {state && !state.ok?<div className="form-error">{state.error.message}</div>:null}
  <button className="secondary-button" disabled={pending}>{pending?"Updating…":"Update status"}</button>
 </form>;
}
