import {requireUser} from "@/lib/auth/require-user";
import {OpportunityMatchingQueryService} from "@/lib/queries";
import {OpportunityBrowser} from "@/components/opportunities/opportunity-filters";

export default async function OpportunitiesPage(){
 const {db}=await requireUser();
 const rows=(await new OpportunityMatchingQueryService(db).ranked(200))??[];
 return <><h1 className="page-title">Opportunities</h1>
  <p className="muted">Evaluate roles against your Career OS preference profile and move strong opportunities into the application pipeline.</p>
  <OpportunityBrowser rows={rows as any[]}/>
 </>;
}
