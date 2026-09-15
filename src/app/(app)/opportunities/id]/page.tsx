import Link from "next/link";
import {notFound} from "next/navigation";
import {requireUser} from "@/lib/auth/require-user";
import {OpportunityMatchingQueryService} from "@/lib/queries";
import {OpportunitiesRepository} from "@/lib/data/repositories/opportunities.repository";
import {OpportunityDetail} from "@/components/opportunities/opportunity-detail";

export default async function OpportunityPage({params}:{params:Promise<{id:string}>}){
 const {id}=await params;
 const {db}=await requireUser();
 const matching=new OpportunityMatchingQueryService(db);
 const [record,evaluations,matches]=await Promise.all([
  new OpportunitiesRepository(db).getById(id),
  matching.evaluations(id),
  matching.ranked(200)
 ]);
 if(!record)notFound();
 const match=(matches as any[]).find(x=>x.opportunity_id===id);
 const opportunity={...(record as any).opportunity,...((record as any).object??{}),id,organization_name:match?.organization_name};
 return <><Link className="text-link" href="/opportunities">← Opportunities</Link>
  <div className="page-heading spaced-title"><div><h1 className="page-title">{opportunity.title??match?.opportunity_title??"Opportunity"}</h1><p className="muted">{match?.organization_name??"Opportunity evaluation"}</p></div></div>
  <OpportunityDetail opportunity={opportunity} match={match} evaluations={(evaluations??[]) as any[]}/>
 </>;
}
