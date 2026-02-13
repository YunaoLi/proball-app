import { jsonError, jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";
import { processReportJobs } from "@/lib/jobs/reportWorker";

type RunBody = {
  limit?: number;
  dryRun?: boolean;
};

export async function POST(req: Request) {
  const secret = req.headers.get("x-job-secret");
  const jobSecret = process.env.JOB_RUNNER_SECRET;

  if (!jobSecret || jobSecret.trim() === "") {
    logger.error("jobs/run: JOB_RUNNER_SECRET is not configured");
    return jsonError(500, "config_error", "JOB_RUNNER_SECRET is not configured");
  }
  if (!secret || secret !== jobSecret) {
    return jsonError(401, "forbidden", "Invalid or missing x-job-secret");
  }

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
    // Empty or invalid body: use defaults (limit=3, dryRun=false)
  }

  const limit =
    typeof body.limit === "number" && body.limit > 0 ? Math.min(body.limit, 10) : 3;
  const dryRun = body.dryRun === true;

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
