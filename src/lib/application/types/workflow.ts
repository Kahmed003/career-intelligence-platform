export type ActivityActorType = "user" | "system" | "ai" | "integration";

export type ActivitySourceType =
  | "web"
  | "mobile"
  | "api"
  | "system"
  | "integration"
  | "ai";

export interface WorkflowContext {
  actorType?: ActivityActorType;
  sourceType?: ActivitySourceType;
  correlationId?: string;
  causationId?: string;
  metadata?: Record<string, unknown>;
}
