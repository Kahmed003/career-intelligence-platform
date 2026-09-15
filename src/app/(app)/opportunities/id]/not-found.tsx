import Link from "next/link";
export default function NotFound(){return <section className="card"><h1>Opportunity not found</h1><p className="muted">This opportunity does not exist or is not available to this account.</p><Link className="text-link" href="/opportunities">Return to opportunities</Link></section>;}
