import { requireJWT, jsonError } from "@/lib/auth";
import { withTransaction } from "@/lib/db";
import { jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";
import { isValidUuid } from "@/lib/uuid";

type Params = { params: Promise<{ sessionId: string }> };

type EndBody = {
  endedAt?: string;
  durationSec?: number;
  calories?: number;
  batteryEnd?: number;
  metrics?: Record<string, unknown>;
};

type SessionRow = {
  session_id: string;
  device_id: string;
  status: string;
  started_at: string;
  ended_at: string | null;
  duration_sec: number | null;
  calories: number | null;
  battery_end: number | null;
};

export async function POST(req: Request, { params }: Params) {
  const authed = await requireJWT(req);
  if (authed instanceof Response) return authed;
  const { userId } = authed;
  const { sessionId } = await params;

  if (!sessionId || !isValidUuid(sessionId)) {
    return jsonError(400, "invalid_session_id", "sessionId must be a valid UUID");
  }

  let body: EndBody;
  try {
    body = (await req.json()) as EndBody;
  } catch {
    body = {};
  }

  const endedAt =
    typeof body?.endedAt === "string" && body.endedAt.trim() ? body.endedAt.trim() : null;
  const durationSec =
    typeof body?.durationSec === "number" && body.durationSec >= 0 ? body.durationSec : null;
  const calories =
    typeof body?.calories === "number" && body.calories >= 0 ? body.calories : null;
  const batteryEnd =
    typeof body?.batteryEnd === "number" && body.batteryEnd >= 0 && body.batteryEnd <= 100
      ? body.batteryEnd
      : null;
  const metrics =
    body?.metrics != null && typeof body.metrics === "object" && !Array.isArray(body.metrics)
      ? body.metrics
      : null;

  try {
    const result = await withTransaction(async (client) => {
      const sessionRes = await client.query<SessionRow>(
        `SELECT session_id, device_id, status, started_at, ended_at, duration_sec, calories, battery_end FROM play_sessions WHERE session_id = $1 AND user_id = $2`,
        [sessionId, userId]
      );
      if (sessionRes.rows.length === 0) {
        return { kind: "not_found" as const };
      }
      const session = sessionRes.rows[0];

      if (session.status === "COMPLETED") {
        let reportStatus = "PENDING";
        const reportRes = await client.query<{ status: string }>(
          `SELECT status FROM ai_reports WHERE session_id = $1`,
          [sessionId]
        );
        if (reportRes.rows.length === 0) {
          await client.query(
            `INSERT INTO ai_reports (session_id, user_id, device_id, status, created_at, updated_at) VALUES ($1, $2, $3, 'PENDING', now(), now())`,
            [sessionId, userId, session.device_id]
          );
        } else {
          reportStatus = reportRes.rows[0].status;
        }
        if (reportStatus === "PENDING") {
          await client.query(
            `INSERT INTO report_jobs (session_id, status)
             VALUES ($1, 'QUEUED')
             ON CONFLICT (session_id) DO UPDATE SET
               status = CASE
                 WHEN report_jobs.status IN ('DONE', 'PROCESSING') THEN report_jobs.status
                 ELSE 'QUEUED'
               END,
               run_at = now(),
               updated_at = now()`,
            [sessionId]
          );
        }
        return {
          kind: "completed" as const,
          session,
          reportStatus,
        };
      }

      const finalEndedAt = endedAt ?? new Date().toISOString();
      const finalDurationSec =
        durationSec ??
        (session.started_at && finalEndedAt
          ? Math.floor(
              (new Date(finalEndedAt).getTime() - new Date(session.started_at).getTime()) / 1000
            )
          : null);

      await client.query(
        `UPDATE play_sessions SET status = 'COMPLETED', ended_at = $1, duration_sec = COALESCE($2, duration_sec), calories = COALESCE($3, calories), battery_end = COALESCE($4, battery_end), metrics_json = COALESCE($5::jsonb, metrics_json) WHERE session_id = $6`,
        [
          finalEndedAt,
          finalDurationSec,
          calories,
          batteryEnd,
          metrics ? JSON.stringify(metrics) : null,
          sessionId,
        ]
      );

      const reportRes = await client.query<{ status: string }>(
        `SELECT status FROM ai_reports WHERE session_id = $1`,
        [sessionId]
      );
      let reportStatus = "PENDING";
      if (reportRes.rows.length === 0) {
        await client.query(
          `INSERT INTO ai_reports (session_id, user_id, device_id, status, created_at, updated_at) VALUES ($1, $2, $3, 'PENDING', now(), now())`,
          [sessionId, userId, session.device_id]
        );
      } else {
        reportStatus = reportRes.rows[0].status;
      }

      if (reportStatus !== "READY" && reportStatus !== "FAILED") {
        const jobRes = await client.query<{ job_id: string }>(
          `INSERT INTO report_jobs (session_id, status)
           VALUES ($1, 'QUEUED')
           ON CONFLICT (session_id) DO UPDATE SET
             status = CASE
               WHEN report_jobs.status IN ('DONE', 'PROCESSING') THEN report_jobs.status
               ELSE 'QUEUED'
             END,
             run_at = now(),
             updated_at = now()
           RETURNING job_id`,
          [sessionId]
        );
        const jobId = jobRes.rows[0]?.job_id;
        logger.info("sessions/end: enqueued report job", { sessionId, jobId });
      }

      const updated = await client.query<SessionRow>(
        `SELECT session_id, device_id, status, started_at, ended_at, duration_sec, calories, battery_end FROM play_sessions WHERE session_id = $1 AND user_id = $2`,
        [sessionId, userId]
      );
      return {
        kind: "updated" as const,
        session: updated.rows[0],
        reportStatus: "PENDING" as const,
      };
    });

    if (result.kind === "not_found") {
      logger.warn("sessions/end: session not found", { userId, sessionId });
      return jsonError(404, "session_not_found", "Session not found");
    }

    const session = result.session;
    const endedAtVal =
      session.ended_at ?? (result.kind === "updated" ? new Date().toISOString() : null);
    logger.info("sessions/end: completed", { userId, sessionId });

    return jsonSuccess({
      session: {
        sessionId: session.session_id,
        deviceId: session.device_id,
        status: session.status,
        startedAt: session.started_at,
        endedAt: endedAtVal,
        durationSec: session.duration_sec,
        calories: session.calories,
      },
      report: { status: result.reportStatus },
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error("sessions/end: unexpected error", msg);
    return jsonError(500, "internal_error", "Internal server error");
  }
}
