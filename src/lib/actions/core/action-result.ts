export type ActionErrorCode =
  | "VALIDATION_ERROR" | "UNAUTHENTICATED" | "FORBIDDEN" | "NOT_FOUND"
  | "CONFLICT" | "DATABASE_ERROR" | "WORKFLOW_PARTIAL_FAILURE" | "INTERNAL_ERROR";

export type ActionResult<T = undefined> =
  | { ok: true; data: T }
  | { ok: false; error: { code: ActionErrorCode; message: string; fieldErrors?: Record<string,string[]> } };
