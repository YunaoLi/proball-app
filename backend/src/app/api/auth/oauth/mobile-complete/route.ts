import { auth } from "@/lib/auth";
import { query } from "@/lib/db";
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
 * GET /api/auth/oauth/mobile-complete
 * Mobile OAuth handoff: reads session from cookies (set during OAuth callback),
 * ensures user is verified (Google users are marked in hook), returns JWT.
 * Used by Flutter after OAuth completes in webview.
 */
export async function GET(req: Request) {
  try {
    const session = await auth.api.getSession({ headers: req.headers });
    if (!session?.user?.id) {
      logger.warn("oauth/mobile-complete: no session");
      return jsonError(401, "unauthorized", "Not authenticated");
    }

    const userId = session.user.id;

    // Ensure Google users are verified (hook may have run; also handle existing users)
    const accountRes = await query<{ providerId: string }>(
      `SELECT "providerId" FROM account WHERE "userId" = $1`,
      [userId]
    );
    const hasGoogle = accountRes.rows.some((r) => r.providerId === "google");
    if (hasGoogle) {
      await query(
        `UPDATE "user" SET "emailVerified" = true, "updatedAt" = now() WHERE id = $1`,
        [userId]
      );
    }

    const verifiedRes = await query<{ emailVerified: boolean }>(
      `SELECT "emailVerified" FROM "user" WHERE id = $1`,
      [userId]
    );
    if (verifiedRes.rows.length > 0 && verifiedRes.rows[0].emailVerified === false) {
      return jsonError(403, "email_not_verified", "Please verify your email.");
    }

    const setCookie = req.headers.get("cookie") ?? "";
    const tokenUrl = `${BASE_URL}/api/auth/token`;
    const tokenReq = new Request(tokenUrl, {
      method: "GET",
      headers: { Cookie: setCookie },
    });
    const tokenRes = await auth.handler(tokenReq);
    if (!tokenRes.ok) {
      logger.warn("oauth/mobile-complete: get token failed", tokenRes.status);
      return jsonError(500, "internal_error", "Could not issue token");
    }

    let tokenData: { token?: string };
    try {
      tokenData = (await tokenRes.json()) as { token?: string };
    } catch {
      return jsonError(500, "internal_error", "Invalid token response");
    }

    const accessToken = tokenData?.token;
    if (!accessToken || typeof accessToken !== "string") {
      return jsonError(500, "internal_error", "Could not issue token");
    }

    const expiresInSec = expiresInToSeconds(JWT_EXPIRES_IN);
    const expiresAtMs = Date.now() + expiresInSec * 1000;

    let refreshToken: string | undefined;
    const sessionCookieMatch = setCookie.match(/better-auth\.session_token=([^;]+)/i);
    if (sessionCookieMatch?.[1]) {
      refreshToken = sessionCookieMatch[1].trim();
    }

    return jsonSuccess({
      accessToken,
      refreshToken: refreshToken ?? undefined,
      tokenType: "Bearer",
      expiresInSec,
      expiresAtMs,
      user: {
        id: session.user.id,
        email: session.user.email ?? "",
        name: session.user.name ?? null,
      },
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error("oauth/mobile-complete: error", msg);
    return jsonError(500, "internal_error", "Internal server error");
  }
}
