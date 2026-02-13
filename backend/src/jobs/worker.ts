/**
 * Local report job worker. Run with: pnpm jobs:worker
 * Processes queued report jobs in a loop (every 5s) until none queued or max iterations.
 */
import "dotenv/config";
import { processReportJobs } from "@/lib/jobs/reportWorker";

const LIMIT = 3;
const POLL_INTERVAL_MS = 5000;
const MAX_ITERATIONS = 100;

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function run(): Promise<void> {
  let iteration = 0;
  let totalProcessed = 0;

  while (iteration < MAX_ITERATIONS) {
    iteration++;
    const result = await processReportJobs({
      limit: LIMIT,
      lockedBy: "local-worker",
      dryRun: false,
    });

    totalProcessed += result.processed;
    console.log(
      `[worker] iteration ${iteration}: processed=${result.processed} succeeded=${result.succeeded} failed=${result.failed}`
    );

    if (result.processed === 0) {
      console.log("[worker] no jobs queued, exiting");
      break;
    }

    await sleep(POLL_INTERVAL_MS);
  }

  if (iteration >= MAX_ITERATIONS) {
    console.log(`[worker] reached max iterations (${MAX_ITERATIONS}), exiting`);
  }

  console.log(`[worker] done. total processed: ${totalProcessed}`);
}

run().catch((e) => {
  console.error("[worker] fatal error", e instanceof Error ? e.message : String(e));
  process.exit(1);
});
