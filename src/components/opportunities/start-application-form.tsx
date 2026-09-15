"use client";
import {useActionState} from "react";
import {useRouter} from "next/navigation";
import {createApplicationAction} from "@/lib/actions/applications.actions";

export function StartApplicationForm({opportunity}:{opportunity:any}){
 const router=useRouter();
 const [state,action,pending]=useActionState(async(_:any)=>{
  return createApplicationAction({
   title:opportunity.title??opportunity.opportunity_title??"Application",
   opportunity_id:opportunity.id??opportunity.opportunity_id,
   organization_id:opportunity.organization_id??null,
   priority:3
  });
 },null as any);

 return <section className="card">
  <h2 className="section-title">Application</h2>
  <p className="muted">Create a Career OS application linked to this opportunity.</p>
  <form action={action}>
   {state&&!state.ok?<div className="form-error">{state.error.message}</div>:null}
   {state?.ok?<div className="form-success">Application created. Open Applications to continue tracking it.</div>:null}
   <button className="primary" disabled={pending}>{pending?"Creating…":"Start application"}</button>
  </form>
  {state?.ok?<button className="secondary-button opp-secondary" onClick={()=>router.push("/applications")}>Go to applications</button>:null}
 </section>;
}
