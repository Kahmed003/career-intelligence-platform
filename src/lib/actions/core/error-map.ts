import { RepositoryError } from "@/lib/data/errors/repository-error";
import { WorkflowPartialFailureError } from "@/lib/application/errors/workflow-error";
import type { ActionResult } from "./action-result";

export function mapActionError(error: unknown): ActionResult<never> {
  if (error instanceof WorkflowPartialFailureError)
    return { ok:false,error:{code:"WORKFLOW_PARTIAL_FAILURE",message:"The primary change succeeded, but a secondary workflow step failed. Refresh before retrying."}};
  if (error instanceof RepositoryError) {
    if (error.code==="23505") return {ok:false,error:{code:"CONFLICT",message:"A conflicting record already exists."}};
    if (error.code==="23503") return {ok:false,error:{code:"NOT_FOUND",message:"A referenced record does not exist."}};
    if (error.code==="42501") return {ok:false,error:{code:"FORBIDDEN",message:"You do not have access to this record."}};
    return {ok:false,error:{code:"DATABASE_ERROR",message:"The database rejected the operation."}};
  }
  return {ok:false,error:{code:"INTERNAL_ERROR",message:"The operation could not be completed."}};
}
