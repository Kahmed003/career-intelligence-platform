import type { PostgrestError } from "@supabase/supabase-js";

export class RepositoryError extends Error {
  constructor(
    message: string,
    public readonly code?: string,
    public readonly details?: string,
    public readonly hint?: string,
    options?: ErrorOptions,
  ) {
    super(message, options);
    this.name = "RepositoryError";
  }

  static from(error: PostgrestError, operation: string) {
    return new RepositoryError(
      `${operation}: ${error.message}`,
      error.code,
      error.details,
      error.hint,
      { cause: error },
    );
  }
}
