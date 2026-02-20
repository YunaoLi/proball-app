import { requireVerifiedJWT } from "@/lib/auth";
import { jsonError, jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";
import { getTodayStats } from "@/lib/stats/service";

const isDev = process.env.NODE_ENV !== "production";

export async function GET(req: Request) {
  const authed = await requireVerifiedJWT(req);
  if (authed instanceof Response) return authed;

  try {
    const stats = await getTodayStats(authed.userId);
    if (isDev) logger.info("stats/today", { userId: authed.userId, ...stats });
    return jsonSuccess(stats);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error("stats/today error", msg);
    return jsonError(500, "internal_error", "Internal server error");
  }
}
