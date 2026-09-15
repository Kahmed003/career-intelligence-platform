import Link from "next/link";
export function OrganizationPeople({rows}:{rows:any[]}){
 return <section className="card"><h2 className="section-title">People</h2>
  {!rows.length?<p className="muted">No contacts linked to this organization.</p>:<div className="stack">{rows.map((p,i)=>
   <Link className="network-row" href={`/network/people/${p.id}`} key={p.id??i}><div><strong>{p.preferred_name??[p.first_name,p.last_name].filter(Boolean).join(" ")??"Contact"}</strong><div className="muted">{p.job_title??"—"}</div></div><span className="badge">{p.relationship_stage??"uncontacted"}</span></Link>)}</div>}
 </section>;
}
