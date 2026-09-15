export function PreferenceEvaluation({rows}:{rows:any[]}){
 if(!rows.length)return <section className="card"><h2 className="section-title">Preference fit</h2><p className="muted">No preference evaluation is available yet.</p></section>;
 return <section className="card"><h2 className="section-title">Preference fit</h2>
  <div className="stack">{rows.map((row,i)=><div className="preference-row" key={row.criterion_id??i}>
   <div><strong>{row.criterion_type??row.criterion_key??"Criterion"}</strong><div className="muted">{row.criterion_value??row.target_value??"—"}</div></div>
   <div className="preference-result"><span className="badge">{row.preference_level??"preference"}</span><strong>{format(row.evaluation_score??row.score)}</strong></div>
  </div>)}</div>
 </section>;
}
function format(v:any){return v==null?"—":String(v)}
