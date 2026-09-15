import Link from "next/link";
export default function NotFound(){return <section className="card"><h1>Application not found</h1><p className="muted">The record does not exist or is not available to this account.</p><Link className="text-link" href="/applications">Return to applications</Link></section>;}
