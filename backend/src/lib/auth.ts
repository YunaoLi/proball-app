import { betterAuth } from "better-auth";
import { bearer, jwt } from "better-auth/plugins";
import * as jose from "jose";
import { getPool } from "./db";
import { jsonError as httpJsonError } from "./http";
import { logger } from "./logger";

const JWT_ISSUER = process.env.JWT_ISSUER ?? "proball-app";
const JWT_AUDIENCE = process.env.JWT_AUDIENCE ?? "proball-mobile";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN ?? "15m";
const BASE_URL =
  process.env.BETTER_AUTH_URL ||
  (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : "http://localhost:3001");

/**
 * Better Auth instance: sign-up, sign-in, session (cookies), JWT/Bearer for mobile.
 * Mount handler at GET/POST /api/auth/[...all].
 * JWT plugin: issuer, audience, expiresIn; JWKS at GET /api/auth/jwks.
 */
export const auth = betterAuth({
  database: getPool(),
  basePath: "/api/auth",
  secret: process.env.BETTER_AUTH_SECRET,
  baseURL: BASE_URL,
  emailAndPassword: {
    enabled: true,
  },
  plugins: [
    jwt({
      jwt: {
        issuer: JWT_ISSUER,
        audience: JWT_AUDIENCE,
        expirationTime: JWT_EXPIRES_IN,
      },
      jwks: { keyPairConfig: { alg: "RS256" } },
    }),
    bearer(),
  ],
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
 * @deprecated Prefer requireJWT for Bearer token auth. Kept for backward compatibility.
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

/** JWKS URL for JWT verification (same origin as auth). */
function getJwksUrl(): string {
  return `${BASE_URL}/api/auth/jwks`;
}

/**
 * Validates Authorization: Bearer <token>, verifies JWT (signature, issuer, audience, exp/iat),
 * returns { userId } from payload.sub. Use in protected API routes.
 */
export async function requireJWT(req: Request): Promise<{ userId: string } | Response> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return httpJsonError(401, "unauthorized", "Missing bearer token");
  }
  const token = authHeader.slice(7).trim();
  if (!token) {
    return httpJsonError(401, "unauthorized", "Missing bearer token");
  }

  try {
    const jwksUrl = getJwksUrl();
    const JWKS = jose.createRemoteJWKSet(new URL(jwksUrl));
    const { payload } = await jose.jwtVerify(token, JWKS, {
      issuer: JWT_ISSUER,
      audience: JWT_AUDIENCE,
      requiredClaims: ["exp", "iat", "sub"],
    });
    const sub = payload.sub;
    if (!sub || typeof sub !== "string") {
      logger.warn("Auth failure: JWT missing sub");
      return httpJsonError(401, "unauthorized", "Invalid token");
    }
    return { userId: sub };
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.warn("Auth failure: JWT verify error", msg);
    return httpJsonError(401, "unauthorized", "Invalid or expired token");
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
