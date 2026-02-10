/**
 * Environment variables used by the app.
 * Do NOT commit secrets; use .env.local or deployment env.
 *
 * Required:
 * - BETTER_AUTH_SECRET  – Secret for Better Auth (min 32 chars; e.g. openssl rand -base64 32)
 * - DATABASE_URL        – PostgreSQL connection string
 *
 * Auth / JWT:
 * - BETTER_AUTH_URL     – Base URL of the app (e.g. http://localhost:3001 or https://your-app.vercel.app)
 * - JWT_ISSUER         – JWT "iss" claim (default: proball-app)
 * - JWT_AUDIENCE       – JWT "aud" claim (default: proball-mobile)
 * - JWT_EXPIRES_IN     – Access token lifetime, e.g. 15m, 1h (default: 15m)
 * - JWT_SIGNING_ALG    – Algorithm for signing (default: RS256; JWKS at GET /api/auth/jwks)
 */
export const env = {
  BETTER_AUTH_SECRET: process.env.BETTER_AUTH_SECRET,
  BETTER_AUTH_URL: process.env.BETTER_AUTH_URL,
  DATABASE_URL: process.env.DATABASE_URL,
  JWT_ISSUER: process.env.JWT_ISSUER ?? "proball-app",
  JWT_AUDIENCE: process.env.JWT_AUDIENCE ?? "proball-mobile",
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN ?? "15m",
  JWT_SIGNING_ALG: process.env.JWT_SIGNING_ALG ?? "RS256",
} as const;
