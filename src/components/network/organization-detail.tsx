export function OrganizationDetail({organization}:{organization:any}){
 return <section className="card"><h2 className="section-title">Organization</h2><dl className="detail-list">
  <div><dt>Name</dt><dd>{organization.legal_name??organization.title??"—"}</dd></div>
  <div><dt>Type</dt><dd>{organization.organization_type??"—"}</dd></div>
  <div><dt>Industry</dt><dd>{organization.industry??"—"}</dd></div>
  <div><dt>Domain</dt><dd>{organization.primary_domain??"—"}</dd></div>
  <div><dt>Location</dt><dd>{[organization.city,organization.region,organization.country_code].filter(Boolean).join(", ")||"—"}</dd></div>
  <div><dt>Employees</dt><dd>{organization.employee_count??"—"}</dd></div>
 </dl></section>;
}
