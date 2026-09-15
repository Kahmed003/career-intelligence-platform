import Link from "next/link";
import { notFound } from "next/navigation";
import { requireUser } from "@/lib/auth/require-user";
import { PipelineQueryService } from "@/lib/queries";
import { ApplicationDetail } from "@/components/applications/application-detail";

export default async function ApplicationPage({params}:{params:Promise<{id:string}>}){
 const {id}=await params;
 const {db}=await requireUser();
 const row=await new PipelineQueryService(db).application(id);
 if(!row)notFound();
 return <>
  <Link className="text-link" href="/applications">← Applications</Link>
  <div className="page-heading spaced-title"><div><h1 className="page-title">{(row as any).application_title ?? (row as any).opportunity_title ?? "Application"}</h1>
   <p className="muted">{(row as any).organization_name ?? "Career OS application"}</p></div></div>
  <ApplicationDetail row={row}/>
 </>;
}
