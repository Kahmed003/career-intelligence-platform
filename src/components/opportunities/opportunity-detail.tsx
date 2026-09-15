import {MatchScore} from "./match-score";
import {PreferenceEvaluation} from "./preference-evaluation";
import {StartApplicationForm} from "./start-application-form";

export function OpportunityDetail({opportunity,match,evaluations}:{opportunity:any;match?:any;evaluations:any[]}){
 return <div className="grid grid-2">
  <section className="card">
   <div className="opportunity-card-top"><div><h2 className="section-title">Opportunity</h2><p className="muted">{opportunity.organization_name??"Organization"}</p></div><MatchScore score={match?.match_score}/></div>
   <dl className="detail-list">
    <div><dt>Type</dt><dd>{opportunity.opportunity_type??"—"}</dd></div>
    <div><dt>Status</dt><dd>{opportunity.status??"—"}</dd></div>
    <div><dt>Location</dt><dd>{opportunity.location_text??"—"}</dd></div>
    <div><dt>Work mode</dt><dd>{opportunity.work_mode??"—"}</dd></div>
    <div><dt>Employment</dt><dd>{opportunity.employment_type??"—"}</dd></div>
    <div><dt>Deadline</dt><dd>{date(opportunity.application_deadline_at)}</dd></div>
    <div><dt>Visa sponsorship</dt><dd>{opportunity.visa_sponsorship??"—"}</dd></div>
    <div><dt>Fit score</dt><dd>{opportunity.fit_score??match?.match_score??"—"}</dd></div>
   </dl>
  </section>
  <StartApplicationForm opportunity={opportunity}/>
  <PreferenceEvaluation rows={evaluations}/>
  <section className="card"><h2 className="section-title">Notes</h2><p>{opportunity.notes??opportunity.description??"No notes have been added."}</p></section>
 </div>;
}
function date(v?:string|null){if(!v)return "—";const d=new Date(v);return Number.isNaN(d.valueOf())?"—":d.toLocaleDateString();}
