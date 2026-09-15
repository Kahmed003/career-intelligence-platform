export function StatCard({ label, value, hint }: { label:string; value:string|number; hint?:string }) {
  return <section className="card">
    <div className="muted">{label}</div>
    <div className="metric">{value}</div>
    {hint ? <small className="muted">{hint}</small> : null}
  </section>;
}
