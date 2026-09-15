import Link from "next/link";
import { requireUser } from "@/lib/auth/require-user";
import { PipelineQueryService } from "@/lib/queries";
import { ApplicationPipeline } from "@/components/applications/application-pipeline";
import { ApplicationList } from "@/components/applications/application-list";

export default async function ApplicationsPage(){
 const {db}=await requireUser();
 const rows=(await new PipelineQueryService(db).applications(200)) ?? [];
 return <>
  <div className="page-heading"><div><h1 className="page-title">Applications</h1><p className="muted">Track applications from preparation through final outcome.</p></div>
   <Link className="button-link" href="/applications/new">New application</Link>
  </div>
  <h2 className="section-label">Active pipeline</h2>
  <ApplicationPipeline rows={rows as any[]}/>
  <h2 className="section-label">All applications</h2>
  <ApplicationList rows={rows as any[]}/>
 </>;
}
