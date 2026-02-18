import { requireVerifiedJWT, jsonError } from "@/lib/auth";
import { query } from "@/lib/db";
import { jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";
import { isValidUuid } from "@/lib/uuid";

type StartBody = {
  deviceId?: string;
  batteryStart?: number;
  startedAt?: string;
};

export async function POST(req: Request) {
  const authed = await requireVerifiedJWT(req);
  if (authed instanceof Response) return authed;
  const { userId } = authed;

  let body: StartBody;
  try {
    body = (await req.json()) as StartBody;
  } catch {
    logger.warn("sessions/start: invalid JSON body");
    return jsonError(400, "invalid_body", "Invalid JSON body");
  }

  const deviceId = typeof body?.deviceId === "string" ? body.deviceId.trim() : "";
  if (!deviceId || !isValidUuid(deviceId)) {
    logger.warn("sessions/start: invalid or missing deviceId");
    return jsonError(400, "invalid_device_id", "deviceId must be a valid UUID");
  }

  const batteryStart =
    typeof body?.batteryStart === "number" && body.batteryStart >= 0 && body.batteryStart <= 100
      ? body.batteryStart
      : null;
  const startedAt =
    typeof body?.startedAt === "string" && body.startedAt.trim()
      ? body.startedAt.trim()
      : null;

  const paired = await query<{ device_id: string }>(
    `SELECT 1 FROM user_devices WHERE user_id = $1 AND device_id = $2`,
    [userId, deviceId]
  );
  if (paired.rows.length === 0) {
    logger.warn("sessions/start: device not paired to user", { userId, deviceId });
    return jsonError(403, "device_not_paired", "Device is not paired to this user");
  }

  const existing = await query<{ session_id: string; started_at: string }>(
    `SELECT session_id, started_at FROM play_sessions WHERE user_id = $1 AND device_id = $2 AND status = 'ACTIVE' ORDER BY started_at DESC LIMIT 1`,
    [userId, deviceId]
  );

  if (existing.rows.length > 0) {
    const row = existing.rows[0];
    logger.info("sessions/start: idempotent return existing ACTIVE session", {
      userId,
      deviceId,
      sessionId: row.session_id,
    });
    return jsonSuccess({
      sessionId: row.session_id,
      deviceId,
      status: "ACTIVE",
      startedAt: row.started_at,
    });
  }

  const inserted = await query<{ session_id: string; started_at: string }>(
    `INSERT INTO play_sessions (user_id, device_id, status, started_at, battery_start) VALUES ($1, $2, 'ACTIVE', COALESCE($3::timestamptz, now()), $4) RETURNING session_id, started_at`,
    [userId, deviceId, startedAt, batteryStart]
  );
  const row = inserted.rows[0];
  logger.info("sessions/start: created session", { userId, deviceId, sessionId: row.session_id });
  return jsonSuccess({
    sessionId: row.session_id,
    deviceId,
    status: "ACTIVE",
    startedAt: row.started_at,
  });
}
