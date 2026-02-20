import { requireVerifiedJWT } from "@/lib/auth";
import { jsonError, jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";
import { getWeeklyStats } from "@/lib/stats/service";

const isDev = process.env.NODE_ENV !== "production";

export async function GET(req: Request) {
  const authed = await requireVerifiedJWT(req);
  if (authed instanceof Response) return authed;

  const url = new URL(req.url);
  const daysStr = url.searchParams.get("days");
  let days = 7;
  if (daysStr) {
    const parsed = parseInt(daysStr, 10);
    if (Number.isNaN(parsed) || parsed < 1 || parsed > 31) {
      return jsonError(400, "invalid_days", "days must be between 1 and 31");
    }
    days = parsed;
  }

  try {
    const stats = await getWeeklyStats(authed.userId, days);
    if (isDev) logger.info("stats/weekly", { userId: authed.userId, days, count: stats.days.length });
    return jsonSuccess(stats);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error("stats/weekly error", msg);
    return jsonError(500, "internal_error", "Internal server error");
  }
}
