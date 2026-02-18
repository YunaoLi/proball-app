/**
 * Sign an access JWT for a user (e.g. after validating a refresh token).
 * Uses the same JWKS and issuer/audience as Better Auth so tokens work with requireJWT.
 */
import { SignJWT, importJWK } from "jose";
import { symmetricDecrypt } from "better-auth/crypto";
import { query } from "@/lib/db";

const JWT_ISSUER = process.env.JWT_ISSUER ?? "proball-app";
const JWT_AUDIENCE = process.env.JWT_AUDIENCE ?? "proball-mobile";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN ?? "15m";

/** Parse "15m" -> seconds for exp claim. */
function parseExpiration(s: string): number {
  const match = s.trim().match(/^(\d+)\s*(s|m|h|d)?$/i);
  if (!match) return 900;
  const n = parseInt(match[1], 10);
  const unit = (match[2] ?? "m").toLowerCase();
  if (unit === "s") return n;
  if (unit === "m") return n * 60;
  if (unit === "h") return n * 3600;
  if (unit === "d") return n * 86400;
  return n * 60;
}

export async function signAccessTokenForUser(userId: string): Promise<string> {
  const secret = process.env.BETTER_AUTH_SECRET;
  if (!secret) throw new Error("BETTER_AUTH_SECRET is not set");

  const res = await query<{ id: string; privateKey: string; publicKey: string }>(
    `SELECT id, "privateKey", "publicKey" FROM jwks ORDER BY "createdAt" DESC LIMIT 1`
  );
  if (res.rows.length === 0) {
    throw new Error("No JWKS key found");
  }
  const key = res.rows[0];

  let privateWebKey: string;
  try {
    const encrypted = JSON.parse(key.privateKey) as string;
    privateWebKey = await symmetricDecrypt({ key: secret, data: encrypted });
  } catch {
    privateWebKey = key.privateKey;
  }

  const jwk = JSON.parse(privateWebKey) as Record<string, unknown>;
  const alg = (jwk.alg as string) ?? "RS256";
  const privateKey = await importJWK(jwk, alg);

  const now = Math.floor(Date.now() / 1000);
  const exp = now + parseExpiration(JWT_EXPIRES_IN);

  const jwt = await new SignJWT({})
    .setProtectedHeader({ alg, kid: key.id })
    .setIssuer(JWT_ISSUER)
    .setAudience(JWT_AUDIENCE)
    .setSubject(userId)
    .setIssuedAt(now)
    .setExpirationTime(exp)
    .sign(privateKey);

  return jwt;
}
