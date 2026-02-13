import { requireJWT, jsonError } from "@/lib/auth";
import { query } from "@/lib/db";
import { jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";

type ReportRow = {
  session_id: string;
  status: string;
  created_at: string;
  updated_at: string;
  device_id: string;
  started_at: string;
  ended_at: string | null;
  duration_sec: number | null;
  calories: number | null;
};

export async function GET(req: Request) {
  const authed = await requireJWT(req);
  if (authed instanceof Response) return authed;
  const { userId } = authed;

  try {
    const res = await query<ReportRow>(
      `SELECT
        r.session_id,
        r.status,
        r.created_at,
        r.updated_at,
        s.device_id,
        s.started_at,
        s.ended_at,
        s.duration_sec,
        s.calories
      FROM ai_reports r
      JOIN play_sessions s ON s.session_id = r.session_id
      WHERE r.user_id = $1
      ORDER BY r.created_at DESC
      LIMIT 50`,
      [userId]
    );

    const reports = res.rows.map((row) => ({
      sessionId: row.session_id,
      status: row.status,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      deviceId: row.device_id,
      startedAt: row.started_at,
      endedAt: row.ended_at,
      durationSec: row.duration_sec,
      calories: row.calories,
    }));

    logger.info("reports: listed", { userId, count: reports.length });
    return jsonSuccess({ reports });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error("reports: list error", msg);
    return jsonError(500, "internal_error", "Internal server error");
  }
}
