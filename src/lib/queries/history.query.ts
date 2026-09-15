import {BaseQueryService} from "./core/base-query.service";
export class HistoricalAnalyticsQueryService extends BaseQueryService {
 async pipeline(days=90){
  const since=new Date(Date.now()-days*86400000).toISOString().slice(0,10);
  const {data,error}=await this.db.from("pipeline_health_snapshots").select("*").gte("snapshot_date",since).order("snapshot_date");
  if(error)this.fail(error,"query pipeline history");return data;
 }
 async campaign(campaignId:string,days=90){
  const since=new Date(Date.now()-days*86400000).toISOString().slice(0,10);
  const {data,error}=await this.db.from("campaign_performance_snapshots").select("*")
   .eq("campaign_id",campaignId).gte("snapshot_date",since).order("snapshot_date");
  if(error)this.fail(error,"query campaign history");return data;
 }
 async relationship(personId:string,days=90){
  const since=new Date(Date.now()-days*86400000).toISOString().slice(0,10);
  const {data,error}=await this.db.from("relationship_health_snapshots").select("*")
   .eq("person_id",personId).gte("snapshot_date",since).order("snapshot_date");
  if(error)this.fail(error,"query relationship history");return data;
 }
}
