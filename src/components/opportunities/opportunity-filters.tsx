"use client";
import {useMemo,useState} from "react";
import {OpportunityList} from "./opportunity-list";

export function OpportunityBrowser({rows}:{rows:any[]}){
 const [query,setQuery]=useState("");
 const [type,setType]=useState("");
 const types=useMemo(()=>Array.from(new Set(rows.map(x=>x.opportunity_type).filter(Boolean))).sort(),[rows]);
 const filtered=rows.filter(row=>{
  const hay=[row.opportunity_title,row.title,row.organization_name,row.location_text].filter(Boolean).join(" ").toLowerCase();
  return (!query||hay.includes(query.toLowerCase()))&&(!type||row.opportunity_type===type);
 });
 return <>
  <div className="card opportunity-filters">
   <label className="field"><span>Search</span><input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Role, company, location…" /></label>
   <label className="field"><span>Opportunity type</span><select value={type} onChange={e=>setType(e.target.value)}><option value="">All types</option>{types.map(x=><option key={x} value={x}>{String(x).replaceAll("_"," ")}</option>)}</select></label>
   <div className="filter-count">{filtered.length} result{filtered.length===1?"":"s"}</div>
  </div>
  <OpportunityList rows={filtered}/>
 </>;
}
