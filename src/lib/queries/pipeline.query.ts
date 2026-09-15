import {BaseQueryService} from "./core/base-query.service";
export class PipelineQueryService extends BaseQueryService {
 async applications(limit=100){
  const {data,error}=await this.db.from("pipeline_application_summary").select("*").limit(limit);
  if(error)this.fail(error,"query pipeline application summary"); return data;
 }
 async application(id:string){
  const {data,error}=await this.db.from("pipeline_application_summary").select("*").eq("application_id",id).maybeSingle();
  if(error)this.fail(error,"query pipeline application"); return data;
 }
}
