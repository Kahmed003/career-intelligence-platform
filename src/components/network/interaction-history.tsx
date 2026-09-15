export function InteractionHistory({rows}:{rows:any[]}){
 return <section className="card"><h2 className="section-title">Interaction history</h2>
  {!rows.length?<p className="muted">No interactions recorded.</p>:<div className="timeline">{rows.map((x,i)=><article className="timeline-item" key={x.id??i}>
   <div className="timeline-dot"/>
   <div><div className="timeline-heading"><strong>{label(x.interaction_type)}</strong><span className="muted">{date(x.occurred_at??x.scheduled_for)}</span></div>
   <p>{x.summary??x.subject??"Interaction recorded."}</p>
   <div className="chip-row"><span className="badge">{x.direction??"mutual"}</span>{x.outcome?<span className="badge">{label(x.outcome)}</span>:null}</div></div>
  </article>)}</div>}
 </section>;
}
function label(v?:string|null){return (v??"interaction").replaceAll("_"," ")}
function date(v?:string|null){if(!v)return "—";const d=new Date(v);return Number.isNaN(d.valueOf())?"—":d.toLocaleString()}
