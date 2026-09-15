import Link from "next/link";
import { CreateApplicationForm } from "@/components/applications/create-application-form";
export default function NewApplicationPage(){
 return <><Link className="text-link" href="/applications">← Applications</Link>
  <h1 className="page-title spaced-title">New application</h1>
  <p className="muted">Create an application record linked to an existing opportunity.</p>
  <CreateApplicationForm/>
 </>;
}
