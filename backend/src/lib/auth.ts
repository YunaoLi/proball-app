import { createRemoteJWKSet, jwtVerify } from "jose";
import { logger } from "./logger";
import { jsonError as httpJsonError } from "./http";

const issuer = process.env.NEON_AUTH_ISSUER;
const jwksUrl = process.env.NEON_AUTH_JWKS_URL;

let cachedJwks: ReturnType<typeof createRemoteJWKSet> | null = null;

function getJwks() {
  if (!jwksUrl) throw new Error("NEON_AUTH_JWKS_URL is not set");
  if (!cachedJwks) cachedJwks = createRemoteJWKSet(new URL(jwksUrl));
  return cachedJwks;
}

/**
 * Extracts the Bearer token from Authorization header.
 * Returns null if header is missing or not Bearer.
 */
export function getBearerToken(req: Request): string | null {
  const auth = req.headers.get("Authorization");
  if (!auth || !auth.startsWith("Bearer ")) return null;
  return auth.slice(7).trim() || null;
}

/**
 * Verifies the request's JWT via JWKS and returns the userId (sub claim).
 * Throws on missing/invalid token or misconfiguration.
 */
export async function verifyJwtAndGetUserId(req: Request): Promise<string> {
  const token = getBearerToken(req);
  if (!token) {
    logger.warn("Auth failure: missing or invalid Authorization header");
    throw new AuthError("missing_token", "Missing or invalid Authorization header");
  }

  if (!issuer) throw new Error("NEON_AUTH_ISSUER is not set");

  try {
    const jwks = getJwks();
    const { payload } = await jwtVerify(token, jwks, {
      issuer,
      typ: "JWT",
    });
    const sub = payload.sub;
    if (typeof sub !== "string" || !sub) {
      logger.warn("Auth failure: JWT missing sub claim");
      throw new AuthError("invalid_claims", "JWT missing sub claim");
    }
    return sub;
  } catch (e) {
    if (e instanceof AuthError) throw e;
    logger.warn("Auth failure: token verification failed", String(e));
    throw new AuthError("invalid_token", "Token verification failed");
  }
}

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
 * Verifies JWT and returns userId, or a 401/500 Response. Use in protected routes.
 */
export async function requireAuth(req: Request): Promise<{ userId: string } | Response> {
  try {
    const userId = await verifyJwtAndGetUserId(req);
    return { userId };
  } catch (e) {
    if (e instanceof AuthError) return httpJsonError(401, e.code, e.message);
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
