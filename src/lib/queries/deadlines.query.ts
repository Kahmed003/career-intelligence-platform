import {BaseQueryService} from "./core/base-query.service";
export class DeadlinesQueryService extends BaseQueryService {
 async list(params:{urgency?:string;limit?:number}={}){
  let q=this.db.from("pipeline_deadline_items").select("*").order("action_at",{ascending:true}).limit(params.limit??100);
  if(params.urgency)q=q.eq("urgency",params.urgency);
  const {data,error}=await q;if(error)this.fail(error,"query pipeline deadlines");return data;
 }
}
