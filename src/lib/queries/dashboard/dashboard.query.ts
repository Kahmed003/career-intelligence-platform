import type {SupabaseClient} from "@supabase/supabase-js";
import type {Database} from "@/lib/supabase/database.types";
import {PipelineQueryService} from "../pipeline.query";
import {DeadlinesQueryService} from "../deadlines.query";
import {OpportunityMatchingQueryService} from "../opportunity-matching.query";
import {RelationshipsQueryService} from "../relationships.query";
import {CampaignsQueryService} from "../campaigns.query";
import {HistoricalAnalyticsQueryService} from "../history.query";
import type {CareerDashboardData} from "./dashboard.types";

export class CareerDashboardQuery {
 constructor(private readonly db:SupabaseClient<Database>){}
 async load():Promise<CareerDashboardData>{
  const pipeline=new PipelineQueryService(this.db);
  const deadlines=new DeadlinesQueryService(this.db);
  const matching=new OpportunityMatchingQueryService(this.db);
  const relationships=new RelationshipsQueryService(this.db);
  const campaigns=new CampaignsQueryService(this.db);
  const history=new HistoricalAnalyticsQueryService(this.db);

  const [pipelineRows,deadlineRows,matches,attention,campaignRows,pipelineHistory]=await Promise.all([
   pipeline.applications(50),deadlines.list({limit:25}),matching.ranked(20),
   relationships.needsAttention(15),campaigns.performance(20),history.pipeline(90)
  ]);
  return {
   generatedAt:new Date().toISOString(),pipeline:pipelineRows??[],deadlines:deadlineRows??[],
   matchedOpportunities:matches??[],relationshipsNeedingAttention:attention??[],
   campaigns:campaignRows??[],pipelineHistory:pipelineHistory??[]
  };
 }
}
