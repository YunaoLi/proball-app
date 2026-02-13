import { requireJWT, jsonError } from "@/lib/auth";
import { query } from "@/lib/db";
import { jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";
import { isValidUuid } from "@/lib/uuid";

type Params = { params: Promise<{ sessionId: string }> };

type ReportRow = {
  session_id: string;
  status: string;
  content_json: Record<string, unknown> | null;
};

export async function GET(req: Request, { params }: Params) {
  const authed = await requireJWT(req);
  if (authed instanceof Response) return authed;
  const { userId } = authed;
  const { sessionId } = await params;

  if (!sessionId || !isValidUuid(sessionId)) {
    return jsonError(400, "invalid_session_id", "sessionId must be a valid UUID");
  }

  const res = await query<ReportRow>(
    `SELECT session_id, status, content_json FROM ai_reports WHERE session_id = $1 AND user_id = $2`,
    [sessionId, userId]
  );

  if (res.rows.length === 0) {
    logger.warn("reports/[sessionId]: not found", { userId, sessionId });
    return jsonError(404, "report_not_found", "Report not found");
  }

  const row = res.rows[0];
  const content = row.status === "READY" ? row.content_json : null;

  return jsonSuccess({
    sessionId: row.session_id,
    status: row.status,
    content,
  });
}
