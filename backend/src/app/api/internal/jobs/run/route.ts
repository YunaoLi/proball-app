import { jsonError, jsonSuccess } from "@/lib/http";

const CRON_SECRET = process.env.CRON_SECRET;
const maxJobs = 10;

/**
 * Internal job runner (cron). Protected by x-cron-secret.
 * Async-safe: processes at most maxJobs per invocation; no unbounded loops.
 *
 * TODO: scan pending ai_reports and generate reports (batch limited by maxJobs).
 */
export async function POST(req: Request) {
  const secret = req.headers.get("x-cron-secret");
  if (!CRON_SECRET) {
    return jsonError(500, "config_error", "CRON_SECRET is not configured");
  }
  if (!secret || secret !== CRON_SECRET) {
    return jsonError(403, "forbidden", "Invalid or missing x-cron-secret");
  }

  const ranAt = new Date().toISOString();
  // TODO: scan pending ai_reports and generate (respect maxJobs)
  return jsonSuccess({ ranAt, maxJobs });
}
