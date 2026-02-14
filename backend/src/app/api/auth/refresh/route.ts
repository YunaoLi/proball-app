import { auth } from "@/lib/auth";
import { jsonError, jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";

const BASE_URL =
  process.env.BETTER_AUTH_URL ||
  (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : "http://localhost:3001");
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN ?? "15m";

function expiresInToSeconds(s: string): number {
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

/**
 * POST /api/auth/refresh
 * Body: { refreshToken: string }
 * Uses the session token to obtain a new JWT from Better Auth.
 */
export async function POST(req: Request) {
  let body: { refreshToken?: string };
  try {
    body = (await req.json()) as { refreshToken?: string };
  } catch {
    return jsonError(400, "invalid_body", "Invalid JSON body");
  }
  const refreshToken = typeof body?.refreshToken === "string" ? body.refreshToken.trim() : "";
  if (!refreshToken) {
    return jsonError(401, "invalid_refresh_token", "Refresh token required");
  }

  const cookie = `better-auth.session_token=${refreshToken}`;
  const tokenUrl = `${BASE_URL}/api/auth/token`;
  const tokenReq = new Request(tokenUrl, {
    method: "GET",
    headers: { Cookie: cookie },
  });
  const tokenRes = await auth.handler(tokenReq);
  if (!tokenRes.ok) {
    logger.warn("auth/refresh: get token failed", tokenRes.status);
    return jsonError(401, "invalid_refresh_token", "Session expired. Please log in again.");
  }
  let tokenData: { token?: string };
  try {
    tokenData = (await tokenRes.json()) as { token?: string };
  } catch {
    return jsonError(500, "internal_error", "Invalid token response");
  }
  const accessToken = tokenData?.token;
  if (!accessToken || typeof accessToken !== "string") {
    return jsonError(401, "invalid_refresh_token", "Could not issue token");
  }

  const setCookie = tokenRes.headers.get("set-cookie");
  let newRefreshToken: string | undefined;
  if (setCookie) {
    const match = setCookie.match(/better-auth\.session_token=([^;]+)/i);
    if (match?.[1]) newRefreshToken = match[1].trim();
  }
  const expiresInSec = expiresInToSeconds(JWT_EXPIRES_IN);
  const expiresAtMs = Date.now() + expiresInSec * 1000;

  return jsonSuccess({
    accessToken,
    refreshToken: newRefreshToken ?? refreshToken,
    tokenType: "Bearer",
    expiresInSec,
    expiresAtMs,
    user: null,
  });
}
