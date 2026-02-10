import { betterAuth } from "better-auth";
import { getPool } from "./db";
import { jsonError as httpJsonError } from "./http";
import { logger } from "./logger";

/**
 * Better Auth instance: sign-up, sign-in, session (cookies).
 * Mount handler at GET/POST /api/auth/[...all].
 * Database: same Postgres pool as app (DATABASE_URL + SSL in db.ts).
 */
export const auth = betterAuth({
  database: getPool(), // pg Pool from db.ts (DATABASE_URL, Neon SSL)
  basePath: "/api/auth",
  secret: process.env.BETTER_AUTH_SECRET,
  baseURL:
    process.env.BETTER_AUTH_URL ||
    (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : "http://localhost:3001"),
  emailAndPassword: {
    enabled: true,
  },
});

export class AuthError extends Error {
  constructor(
    public readonly code: string,
    message: string
  ) {
    super(message);
    this.name = "AuthError";
  }
}

/**
 * Verifies session from request (cookies) and returns userId, or a 401/500 Response.
 * Use in protected API routes. Session is from Better Auth (no JWT).
 */
export async function requireAuth(req: Request): Promise<{ userId: string } | Response> {
  try {
    const session = await auth.api.getSession({ headers: req.headers });
    if (!session?.user?.id) {
      logger.warn("Auth failure: no session or user");
      return httpJsonError(401, "unauthorized", "Not authenticated");
    }
    return { userId: session.user.id };
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.warn("Auth failure: getSession error", msg);
    return httpJsonError(500, "internal_error", "Internal server error");
  }
}

/**
 * Builds a JSON error Response. Re-exported for use in route handlers.
 */
export function jsonError(
  status: number,
  code: string,
  message: string,
  details?: unknown
): Response {
  return httpJsonError(status, code, message, details);
}
