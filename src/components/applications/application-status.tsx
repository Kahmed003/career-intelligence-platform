const terminal = new Set(["accepted","rejected","withdrawn","closed"]);
export function ApplicationStatus({ status }: { status?: string | null }) {
  const value=status ?? "unknown";
  return <span className="badge" data-terminal={terminal.has(value) ? "true" : "false"}>{value.replaceAll("_"," ")}</span>;
}
