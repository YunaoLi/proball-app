import { requireJWT } from "@/lib/auth";
import { query } from "@/lib/db";
import { jsonError } from "@/lib/auth";
import { jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";

/**
 * GET /api/devices – list devices paired to the current user.
 * Protected by JWT. Returns only this user's paired devices from user_devices.
 *
 * Test:
 *   curl -H "Authorization: Bearer $TOKEN" $BASE/api/devices
 */
type DeviceRow = {
  device_id: string;
  nickname: string | null;
  model: string | null;
  firmware_version: string | null;
  paired_at: Date;
};

export async function GET(req: Request) {
  const authed = await requireJWT(req);
  if (authed instanceof Response) return authed;
  const { userId } = authed;

  try {
    const res = await query<DeviceRow>(
      `SELECT ud.device_id, ud.nickname, d.model, d.firmware_version, ud.paired_at
       FROM user_devices ud
       LEFT JOIN devices d ON d.device_id = ud.device_id
       WHERE ud.user_id = $1
       ORDER BY ud.paired_at DESC`,
      [userId]
    );

    const devices = res.rows.map((row) => ({
      deviceId: row.device_id,
      nickname: row.nickname,
      model: row.model,
      firmwareVersion: row.firmware_version,
      pairedAt: row.paired_at.toISOString(),
    }));

    return jsonSuccess({ devices });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error("devices: list error", msg);
    return jsonError(500, "internal_error", "Internal server error");
  }
}
