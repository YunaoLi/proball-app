/**
 * Consistent JSON response helpers for API routes.
 */

export type JsonErrorBody = {
  ok: false;
  code: string;
  message: string;
  details?: unknown;
};

export function jsonError(
  status: number,
  code: string,
  message: string,
  details?: unknown
): Response {
  const body: JsonErrorBody = { ok: false, code, message };
  if (details !== undefined) body.details = details;
  return Response.json(body, { status });
}

export function jsonSuccess<T extends Record<string, unknown>>(data: T, status = 200): Response {
  return Response.json({ ...data, ok: true }, { status });
}

/** Placeholder for unimplemented endpoints: 501 with error shape { error: { code, message } }. */
export function jsonNotImplemented(message = "Not implemented"): Response {
  return Response.json(
    { error: { code: "NOT_IMPLEMENTED", message } },
    { status: 501 }
  );
}
