import {
  generateRefreshToken,
  getIpAddress,
  getRefreshExpiry,
  getUserAgent,
  hashToken,
} from "@/lib/auth/refreshToken";
import { signAccessTokenForUser } from "@/lib/auth/signAccessToken";
import { query } from "@/lib/db";
import { jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";
import { randomUUID } from "crypto";

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

function refreshInvalid(): Response {
  return Response.json({ error: "REFRESH_INVALID" }, { status: 401 });
}

/**
 * Parse refresh token from Authorization: Bearer (preferred) or JSON body.
 */
async function parseRefreshToken(req: Request): Promise<string | null> {
  const authHeader = req.headers.get("Authorization");
  if (authHeader?.startsWith("Bearer ")) {
    const token = authHeader.slice(7).trim();
    if (token) return token;
  }
  try {
    const body = (await req.json()) as { refreshToken?: string };
    const token = typeof body?.refreshToken === "string" ? body.refreshToken.trim() : "";
    return token || null;
  } catch {
    return null;
  }
}

/**
 * POST /api/auth/refresh
 * Authorization: Bearer <refreshToken> (preferred) or body: { refreshToken: string }
 * Rotates refresh token: revokes old session, creates new session, returns new access + refresh.
 */
export async function POST(req: Request) {
  const refreshToken = await parseRefreshToken(req);
  if (!refreshToken) {
    return refreshInvalid();
  }

  const hash = hashToken(refreshToken);

  const validSessionRes = await query<{ id: string; userId: string }>(
    `SELECT id, "userId" FROM session
     WHERE token = $1 AND "expiresAt" > now() AND "revokedAt" IS NULL`,
    [hash]
  );

  if (validSessionRes.rows.length === 0) {
    const revokedSessionRes = await query<{ userId: string }>(
      `SELECT "userId" FROM session WHERE token = $1 AND "revokedAt" IS NOT NULL`,
      [hash]
    );
    if (revokedSessionRes.rows.length > 0) {
      const userId = revokedSessionRes.rows[0].userId;
      logger.warn("auth/refresh: reuse detected, revoking all sessions for user", {
        userId: userId.slice(0, 8) + "***",
      });
      await query(`UPDATE session SET "revokedAt" = now() WHERE "userId" = $1`, [userId]);
    }
    return refreshInvalid();
  }

  const oldSession = validSessionRes.rows[0];
  const { id: oldSessionId, userId } = oldSession;

  const newRefreshToken = generateRefreshToken();
  const newHash = hashToken(newRefreshToken);
  const refreshExpiresAt = getRefreshExpiry();
  const now = new Date();
  const newSessionId = randomUUID();

  try {
    await query(
      `INSERT INTO session (id, "userId", token, "expiresAt", "createdAt", "updatedAt", "ipAddress", "userAgent", "lastUsedAt")
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
      [
        newSessionId,
        userId,
        newHash,
        refreshExpiresAt,
        now,
        now,
        getIpAddress(req) ?? null,
        getUserAgent(req) ?? null,
        now,
      ]
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error("auth/refresh: failed to create new session", msg);
    return Response.json({ error: "REFRESH_INVALID" }, { status: 500 });
  }

  await query(
    `UPDATE session SET "revokedAt" = $1, "replacedBySessionId" = $2, "lastUsedAt" = $1 WHERE id = $3`,
    [now, newSessionId, oldSessionId]
  );

  let accessToken: string;
  try {
    accessToken = await signAccessTokenForUser(userId);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error("auth/refresh: failed to sign access token", msg);
    return Response.json({ error: "REFRESH_INVALID" }, { status: 500 });
  }

  const expiresInSec = expiresInToSeconds(JWT_EXPIRES_IN);

  return jsonSuccess({
    accessToken,
    refreshToken: newRefreshToken,
    expiresInSec,
  });
}
