import { createHash, randomBytes } from "node:crypto";

const REFRESH_EXPIRES_DAYS = parseInt(
  process.env.REFRESH_EXPIRES_DAYS ?? "30",
  10
);

/**
 * Generate a cryptographically secure refresh token.
 * Use 48 bytes base64url for ~64 chars; never store plaintext in DB.
 */
export function generateRefreshToken(): string {
  return randomBytes(48).toString("base64url");
}

/**
 * Hash a token for storage. Only hash ever stored in DB.
 * Uses SHA-256 hex digest.
 */
export function hashToken(token: string): string {
  return createHash("sha256").update(token, "utf8").digest("hex");
}

/**
 * Compute refresh token expiry (e.g. now + 30 days).
 * Configurable via REFRESH_EXPIRES_DAYS env.
 */
export function getRefreshExpiry(): Date {
  const days = Number.isFinite(REFRESH_EXPIRES_DAYS) && REFRESH_EXPIRES_DAYS > 0
    ? REFRESH_EXPIRES_DAYS
    : 30;
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d;
}

/**
 * Extract client IP from headers (X-Forwarded-For, X-Real-IP).
 * App Router uses standard Request.
 */
export function getIpAddress(req: Request): string | null {
  const forwarded = req.headers.get("x-forwarded-for");
  if (forwarded) {
    const first = forwarded.split(",")[0]?.trim();
    if (first) return first;
  }
  const realIp = req.headers.get("x-real-ip");
  if (realIp) return realIp.trim();
  return null;
}

/**
 * Extract User-Agent from headers.
 */
export function getUserAgent(req: Request): string | null {
  const ua = req.headers.get("user-agent");
  return ua?.trim() ?? null;
}
