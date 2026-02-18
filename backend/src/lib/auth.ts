import { betterAuth } from "better-auth";
import { createAuthMiddleware } from "better-auth/api";
import { bearer, jwt } from "better-auth/plugins";
import * as jose from "jose";
import { getPool, query } from "./db";
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
 * Google OAuth: sign-in at GET /api/auth/sign-in/social?provider=google, callback at /api/auth/callback/google.
 */
export const auth = betterAuth({
  database: getPool(),
  basePath: "/api/auth",
  secret: process.env.BETTER_AUTH_SECRET,
  baseURL: BASE_URL,
  emailAndPassword: {
    enabled: true,
  },
  socialProviders: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID as string,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET as string,
    },
  },
  hooks: {
    after: createAuthMiddleware(async (ctx) => {
      if (ctx.path.includes("callback") && ctx.path.includes("google")) {
        const newSession = ctx.context.newSession;
        if (newSession?.user?.id) {
          try {
            const pool = getPool();
            await pool.query(
              `UPDATE "user" SET "emailVerified" = true, "updatedAt" = now() WHERE id = $1`,
              [newSession.user.id]
            );
            logger.info("auth: marked Google user as verified", {
              userId: newSession.user.id.slice(0, 8) + "***",
            });
          } catch (e) {
            const msg = e instanceof Error ? e.message : String(e);
            logger.error("auth: failed to mark Google user verified", msg);
          }
        }
      }
    }),
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

/** Normalize base URL (no trailing slash). */
function getBaseUrl(): string {
  const base =
    process.env.BETTER_AUTH_URL ||
    (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : "http://localhost:3001");
  return base.replace(/\/$/, "");
}

/** JWKS URL for JWT verification. Uses request origin (avoids env mismatch on Vercel). */
function getJwksUrl(req: Request): string {
  try {
    const url = new URL(req.url);
    return `${url.origin}/api/auth/jwks`;
  } catch {
    return `${getBaseUrl()}/api/auth/jwks`;
  }
}

/** Cached JWKS (avoids repeated fetch / self-request issues on Vercel). */
let cachedJwks: { jwks: jose.JSONWebKeySet; url: string } | null = null;

async function getJwks(jwksUrl: string, fallbackUrl?: string): Promise<jose.JSONWebKeySet> {
  if (cachedJwks?.url === jwksUrl && cachedJwks.jwks.keys?.length) {
    return cachedJwks.jwks;
  }
  if (fallbackUrl && cachedJwks?.url === fallbackUrl && cachedJwks.jwks.keys?.length) {
    return cachedJwks.jwks;
  }
  const tryFetch = async (url: string) => {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`JWKS fetch failed: ${res.status} ${res.statusText}`);
    return (await res.json()) as jose.JSONWebKeySet;
  };
  try {
    const jwks = await tryFetch(jwksUrl);
    cachedJwks = { jwks, url: jwksUrl };
    return jwks;
  } catch (e) {
    if (fallbackUrl && fallbackUrl !== jwksUrl) {
      logger.warn("JWKS fetch from request origin failed, trying env base URL", String(e));
      const jwks = await tryFetch(fallbackUrl);
      cachedJwks = { jwks, url: fallbackUrl };
      return jwks;
    }
    throw e;
  }
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
    const jwksUrl = getJwksUrl(req);
    const fallbackUrl = `${getBaseUrl()}/api/auth/jwks`;
    const jwks = await getJwks(jwksUrl, fallbackUrl);
    const JWKS = jose.createLocalJWKSet(jwks);
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
 * Like requireJWT, but also enforces emailVerified. Use for protected API routes.
 * Returns 403 email_not_verified if user exists but emailVerified is false.
 */
export async function requireVerifiedJWT(req: Request): Promise<{ userId: string } | Response> {
  const authed = await requireJWT(req);
  if (authed instanceof Response) return authed;
  const { userId } = authed;

  try {
    const res = await query<{ emailVerified: boolean }>(
      `SELECT "emailVerified" FROM "user" WHERE id = $1`,
      [userId]
    );
    if (res.rows.length === 0) {
      return httpJsonError(401, "unauthorized", "User not found");
    }
    if (res.rows[0].emailVerified === false) {
      return httpJsonError(403, "email_not_verified", "Please verify your email.");
    }
    return { userId };
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.warn("Auth failure: email verification check error", msg);
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
