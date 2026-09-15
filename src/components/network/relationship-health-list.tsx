import Link from "next/link";
export function RelationshipHealthList({rows}:{rows:any[]}){
 if(!rows.length)return <section className="card empty">No relationships need attention.</section>;
 return <section className="card"><h2 className="section-title">Follow-up queue</h2>
  <div className="stack">{rows.map((r,i)=><Link className="network-row" href={`/network/people/${r.person_id}`} key={r.person_id??i}>
   <div><strong>{r.person_name??r.title??"Contact"}</strong><div className="muted">{r.organization_name??r.job_title??"—"}</div></div>
   <div className="network-row-meta"><span className="badge">{r.relationship_health??"review"}</span><strong>{r.relationship_score??"—"}</strong></div>
  </Link>)}</div>
 </section>;
}
