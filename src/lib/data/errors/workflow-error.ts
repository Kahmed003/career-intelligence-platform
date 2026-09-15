export class WorkflowPartialFailureError extends Error {
  constructor(
    message: string,
    public readonly completedOperation: string,
    public readonly failedOperation: string,
    options?: ErrorOptions,
  ) {
    super(message, options);
    this.name = "WorkflowPartialFailureError";
  }
}
