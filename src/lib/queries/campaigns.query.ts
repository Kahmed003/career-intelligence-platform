import {BaseQueryService} from "./core/base-query.service";
export class CampaignsQueryService extends BaseQueryService {
 async performance(limit=50){
  const {data,error}=await this.db.from("campaign_performance_summary").select("*").limit(limit);
  if(error)this.fail(error,"query campaign performance");return data;
 }
 async deadlinePressure(campaignId?:string){
  let q=this.db.from("campaign_deadline_pressure").select("*");
  if(campaignId)q=q.eq("campaign_id",campaignId);
  const {data,error}=await q;if(error)this.fail(error,"query campaign deadline pressure");return data;
 }
 async sourcePerformance(limit=100){
  const {data,error}=await this.db.from("campaign_source_performance_active").select("*").limit(limit);
  if(error)this.fail(error,"query active campaign source performance");return data;
 }
}
