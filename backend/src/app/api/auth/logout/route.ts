import { hashToken } from "@/lib/auth/refreshToken";
import { query } from "@/lib/db";

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
 * POST /api/auth/logout
 * Authorization: Bearer <refreshToken> (preferred) or body: { refreshToken: string }
 * Revokes the refresh session by setting revokedAt=now.
 */
export async function POST(req: Request) {
  const refreshToken = await parseRefreshToken(req);
  if (refreshToken) {
    const hash = hashToken(refreshToken);
    await query(
      `UPDATE session SET "revokedAt" = now() WHERE token = $1 AND "revokedAt" IS NULL`,
      [hash]
    );
  }
  return new Response(null, { status: 204 });
}
