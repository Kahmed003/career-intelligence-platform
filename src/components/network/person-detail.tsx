export function PersonDetail({person}:{person:any}){
 return <section className="card"><h2 className="section-title">Contact</h2><dl className="detail-list">
  <div><dt>Name</dt><dd>{person.preferred_name??[person.first_name,person.last_name].filter(Boolean).join(" ")||person.title||"—"}</dd></div>
  <div><dt>Title</dt><dd>{person.job_title??"—"}</dd></div>
  <div><dt>Department</dt><dd>{person.department??"—"}</dd></div>
  <div><dt>Email</dt><dd>{person.email??"—"}</dd></div>
  <div><dt>Phone</dt><dd>{person.phone??"—"}</dd></div>
  <div><dt>Relationship stage</dt><dd>{person.relationship_stage??"—"}</dd></div>
  <div><dt>Last contacted</dt><dd>{date(person.last_contacted_at)}</dd></div>
  <div><dt>Next follow-up</dt><dd>{date(person.next_follow_up_at)}</dd></div>
 </dl></section>;
}
function date(v?:string|null){if(!v)return "—";const d=new Date(v);return Number.isNaN(d.valueOf())?"—":d.toLocaleDateString()}
