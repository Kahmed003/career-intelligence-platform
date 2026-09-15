import type { Database } from "@/lib/supabase/database.types";

export type TableName = keyof Database["public"]["Tables"];
export type Row<T extends TableName> = Database["public"]["Tables"][T]["Row"];
export type Insert<T extends TableName> = Database["public"]["Tables"][T]["Insert"];
export type Update<T extends TableName> = Database["public"]["Tables"][T]["Update"];

export type ObjectRow = Row<"objects">;
export type ProjectRow = Row<"projects">;
export type TaskRow = Row<"tasks">;
export type OrganizationRow = Row<"organizations">;
export type PersonRow = Row<"people">;
export type OpportunityRow = Row<"opportunities">;
export type ApplicationRow = Row<"applications">;

export type ProjectRecord = ObjectRow & { project: ProjectRow };
export type TaskRecord = ObjectRow & { task: TaskRow };
export type OrganizationRecord = ObjectRow & { organization: OrganizationRow };
export type PersonRecord = ObjectRow & { person: PersonRow };
export type OpportunityRecord = ObjectRow & { opportunity: OpportunityRow };
export type ApplicationRecord = ObjectRow & { application: ApplicationRow };
