import Link from "next/link";
import {MatchScore} from "./match-score";

export function OpportunityList({rows}:{rows:any[]}){
 if(!rows.length)return <section className="card empty">No scored opportunities yet.</section>;
 return <div className="opportunity-grid">{rows.map((row,i)=>
  <Link href={`/opportunities/${row.opportunity_id}`} className="card opportunity-card" key={row.opportunity_id??i}>
   <div className="opportunity-card-top">
    <div><h2>{row.opportunity_title??row.title??"Opportunity"}</h2>
    <p className="muted">{row.organization_name??"Organization"}</p></div>
    <MatchScore score={row.match_score}/>
   </div>
   <div className="chip-row">
    {row.opportunity_type?<span className="badge">{row.opportunity_type}</span>:null}
    {row.location_text?<span className="badge">{row.location_text}</span>:null}
    {row.work_mode?<span className="badge">{row.work_mode}</span>:null}
   </div>
   <p className="muted opportunity-summary">{row.description??"Open to review preference fit and details."}</p>
  </Link>
 )}</div>;
}
