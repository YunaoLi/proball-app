/**
 * Report job worker: claims queued jobs, generates AI reports, updates ai_reports.
 * Uses transactional claim with SELECT FOR UPDATE SKIP LOCKED.
 */

import type { PoolClient } from "pg";
import { withTransaction, query } from "@/lib/db";
import { logger } from "@/lib/logger";
import { generateSessionReport, type SessionForReport } from "@/lib/ai/openai";

export type JobRow = {
  job_id: string;
  session_id: string;
  attempts: number;
  max_attempts: number;
};

export type ProcessResult = {
  processed: number;
  succeeded: number;
  failed: number;
  details: Array<{ jobId: string; sessionId: string; status: string }>;
};

const BACKOFF_BASE_SEC = 30;
const BACKOFF_CAP_SEC = 30 * 60; // 30 min

/**
 * Claim up to `limit` QUEUED jobs with run_at <= now().
 * Uses SELECT FOR UPDATE SKIP LOCKED to avoid concurrent processing.
 */
export async function claimNextJobs(
  client: PoolClient,
  limit: number,
  lockedBy: string
): Promise<JobRow[]> {
  const res = await client.query<JobRow>(
    `SELECT job_id, session_id, attempts, max_attempts
     FROM report_jobs
     WHERE status = 'QUEUED' AND run_at <= now()
     ORDER BY created_at ASC
     LIMIT $1
     FOR UPDATE SKIP LOCKED`,
    [limit]
  );

  const rows = res.rows;
  if (rows.length === 0) {
    logger.info("reportWorker: no QUEUED jobs found");
    return [];
  }
  logger.info("reportWorker: claiming jobs", { count: rows.length, jobIds: rows.map((r) => r.job_id) });

  const jobIds = rows.map((r) => r.job_id);
  await client.query(
    `UPDATE report_jobs
     SET status = 'PROCESSING', locked_at = now(), locked_by = $1, updated_at = now()
     WHERE job_id = ANY($2::uuid[])`,
    [lockedBy, jobIds]
  );

  return rows;
}

/**
 * Process a single job: fetch session, generate report, update ai_reports and report_jobs.
 */
export async function processOneJob(job: JobRow): Promise<{ ok: boolean; error?: string }> {
  const { job_id, session_id, attempts, max_attempts } = job;

  try {
    const reportRes = await query<{ status: string }>(
      `SELECT status FROM ai_reports WHERE session_id = $1`,
      [session_id]
    );
    if (reportRes.rows.length === 0) {
      return { ok: false, error: "ai_reports row not found" };
    }
    if (reportRes.rows[0].status === "READY") {
      await query(
        `UPDATE report_jobs SET status = 'DONE', updated_at = now() WHERE job_id = $1`,
        [job_id]
      );
      return { ok: true };
    }

    const sessionRes = await query<
      SessionForReport & { nickname: string | null }
    >(
      `SELECT s.session_id, s.user_id, s.device_id, s.started_at, s.ended_at,
              s.duration_sec, s.calories, s.battery_start, s.battery_end, s.metrics_json,
              ud.nickname
       FROM play_sessions s
       LEFT JOIN user_devices ud ON ud.user_id = s.user_id AND ud.device_id = s.device_id
       WHERE s.session_id = $1`,
      [session_id]
    );
    if (sessionRes.rows.length === 0) {
      return { ok: false, error: "session not found" };
    }

    const row = sessionRes.rows[0];
    const session: SessionForReport = {
      session_id: row.session_id,
      user_id: row.user_id,
      device_id: row.device_id,
      started_at: row.started_at,
      ended_at: row.ended_at,
      duration_sec: row.duration_sec,
      calories: row.calories,
      battery_start: row.battery_start,
      battery_end: row.battery_end,
      metrics_json: row.metrics_json as Record<string, unknown> | null,
      device_nickname: row.nickname,
    };

    const contentJson = await generateSessionReport({ session });

    await query(
      `UPDATE ai_reports SET status = 'READY', content_json = $1::jsonb, updated_at = now() WHERE session_id = $2`,
      [JSON.stringify(contentJson), session_id]
    );
    await query(
      `UPDATE report_jobs SET status = 'DONE', updated_at = now() WHERE job_id = $1`,
      [job_id]
    );

    logger.info("reportWorker: job done", { jobId: job_id, sessionId: session_id });
    return { ok: true };
  } catch (e) {
    const errMsg = e instanceof Error ? e.message : String(e);
    const nextAttempts = attempts + 1;
    const isFinal = nextAttempts >= max_attempts;

    const backoffSec = Math.min(
      Math.pow(2, nextAttempts) * BACKOFF_BASE_SEC,
      BACKOFF_CAP_SEC
    );
    const runAt = new Date(Date.now() + backoffSec * 1000).toISOString();

    if (isFinal) {
      await query(
        `UPDATE report_jobs SET status = 'FAILED', attempts = $1, last_error = $2, updated_at = now() WHERE job_id = $3`,
        [nextAttempts, errMsg.slice(0, 500), job_id]
      );
      await query(
        `UPDATE ai_reports SET status = 'FAILED', failure_reason = $1, updated_at = now() WHERE session_id = $2`,
        [errMsg.slice(0, 500), session_id]
      );
      logger.warn("reportWorker: job failed (max attempts)", {
        jobId: job_id,
        sessionId: session_id,
      });
    } else {
      await query(
        `UPDATE report_jobs SET status = 'QUEUED', attempts = $1, run_at = $2, last_error = $3, updated_at = now() WHERE job_id = $4`,
        [nextAttempts, runAt, errMsg.slice(0, 500), job_id]
      );
      logger.warn("reportWorker: job retry scheduled", {
        jobId: job_id,
        sessionId: session_id,
        nextAttempts,
      });
    }

    return { ok: false, error: errMsg };
  }
}

/**
 * Process up to `limit` queued report jobs.
 * Returns stats and details. Safe for concurrent invocations (Vercel Cron).
 */
export async function processReportJobs(params: {
  limit: number;
  lockedBy: string;
  dryRun?: boolean;
}): Promise<ProcessResult> {
  const { limit, lockedBy, dryRun = false } = params;
  const result: ProcessResult = { processed: 0, succeeded: 0, failed: 0, details: [] };

  const jobs = await withTransaction(async (client) => {
    return claimNextJobs(client, limit, lockedBy);
  });

  if (jobs.length === 0) return result;

  if (dryRun) {
    for (const j of jobs) {
      result.processed++;
      result.details.push({ jobId: j.job_id, sessionId: j.session_id, status: "dry_run" });
    }
    await withTransaction(async (client) => {
      await client.query(
        `UPDATE report_jobs SET status = 'QUEUED', locked_at = NULL, locked_by = NULL, updated_at = now() WHERE job_id = ANY($1::uuid[])`,
        [jobs.map((j) => j.job_id)]
      );
    });
    return result;
  }

  for (const job of jobs) {
    const { ok, error } = await processOneJob(job);
    result.processed++;
    if (ok) {
      result.succeeded++;
      result.details.push({ jobId: job.job_id, sessionId: job.session_id, status: "DONE" });
    } else {
      result.failed++;
      result.details.push({
        jobId: job.job_id,
        sessionId: job.session_id,
        status: "FAILED",
      });
      if (error) result.details[result.details.length - 1].status += `: ${error.slice(0, 80)}`;
    }
  }

  return result;
}
