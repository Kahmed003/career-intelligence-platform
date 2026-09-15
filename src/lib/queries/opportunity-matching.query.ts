import {BaseQueryService} from "./core/base-query.service";
export class OpportunityMatchingQueryService extends BaseQueryService {
 async ranked(limit=50){
  const {data,error}=await this.db.from("opportunity_match_scores").select("*").order("match_score",{ascending:false}).limit(limit);
  if(error)this.fail(error,"query opportunity match scores");return data;
 }
 async evaluations(opportunityId:string){
  const {data,error}=await this.db.from("opportunity_preference_evaluations").select("*").eq("opportunity_id",opportunityId);
  if(error)this.fail(error,"query opportunity preference evaluations");return data;
 }
}
