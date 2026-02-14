import { jsonError, jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";
import { processReportJobs } from "@/lib/jobs/reportWorker";

type RunBody = {
  limit?: number;
  dryRun?: boolean;
};

function validateJobSecret(req: Request): Response | null {
  const jobSecret = process.env.JOB_RUNNER_SECRET;
  const cronSecret = process.env.CRON_SECRET;
  if (!jobSecret || jobSecret.trim() === "") {
    logger.error("jobs/run: JOB_RUNNER_SECRET is not configured");
    return jsonError(500, "config_error", "JOB_RUNNER_SECRET is not configured");
  }
  const headerSecret = req.headers.get("x-job-secret");
  const authHeader = req.headers.get("authorization");
  const bearerSecret = authHeader?.startsWith("Bearer ")
    ? authHeader.slice(7).trim()
    : null;
  const secret = headerSecret ?? bearerSecret;
  const valid =
    secret &&
    (secret === jobSecret || (cronSecret && secret === cronSecret));
  if (!valid) {
    return jsonError(401, "forbidden", "Invalid or missing x-job-secret or Authorization");
  }
  return null;
}

/** GET: for Vercel Cron (sends GET). Validates via Authorization: Bearer <JOB_RUNNER_SECRET>. */
export async function GET(req: Request) {
  const err = validateJobSecret(req);
  if (err) return err;
  return runJobs(req, { limit: 10, dryRun: false });
}

export async function POST(req: Request) {
  const err = validateJobSecret(req);
  if (err) return err;

  let body: RunBody = {};
  try {
    const text = await req.text();
    if (text && text.trim()) {
      const raw = JSON.parse(text) as unknown;
      if (raw && typeof raw === "object") {
        body = raw as RunBody;
      }
    }
  } catch {
    // Empty or invalid body: use defaults
  }

  const limit =
    typeof body.limit === "number" && body.limit > 0 ? Math.min(body.limit, 10) : 10;
  const dryRun = body.dryRun === true;

  return runJobs(req, { limit, dryRun });
}

async function runJobs(
  _req: Request,
  opts: { limit: number; dryRun: boolean }
): Promise<Response> {
  const { limit, dryRun } = opts;
  try {
    const result = await processReportJobs({
      limit,
      lockedBy: "api-internal",
      dryRun,
    });

    logger.info("jobs/run: completed", {
      processed: result.processed,
      succeeded: result.succeeded,
      failed: result.failed,
      jobCount: result.details.length,
      dryRun,
    });

    return jsonSuccess({
      ok: true,
      processed: result.processed,
      succeeded: result.succeeded,
      failed: result.failed,
      details: result.details,
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error("jobs/run: unexpected error", msg);
    return jsonError(500, "internal_error", "Internal server error");
  }
}
