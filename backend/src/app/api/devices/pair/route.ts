import { requireJWT, jsonError } from "@/lib/auth";
import { withTransaction } from "@/lib/db";
import { jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";
import { isValidUuid } from "@/lib/uuid";

type PairBody = { deviceId?: string; deviceName?: string };

export async function POST(req: Request) {
  const authed = await requireJWT(req);
  if (authed instanceof Response) return authed;
  const { userId } = authed;

  let body: PairBody;
  try {
    body = (await req.json()) as PairBody;
  } catch {
    logger.warn("devices/pair: invalid JSON body");
    return jsonError(400, "invalid_body", "Invalid JSON body");
  }

  const deviceId = typeof body?.deviceId === "string" ? body.deviceId.trim() : "";
  if (!deviceId || !isValidUuid(deviceId)) {
    logger.warn("devices/pair: invalid or missing deviceId");
    return jsonError(400, "invalid_device_id", "deviceId must be a valid UUID");
  }

  const nickname =
    typeof body?.deviceName === "string" ? body.deviceName.trim() || null : null;

  try {
    const result = await withTransaction(async (client) => {
      // Upsert device (reuse if exists)
      await client.query(
        `INSERT INTO devices (device_id) VALUES ($1) ON CONFLICT (device_id) DO NOTHING`,
        [deviceId]
      );

      const existing = await client.query<{ device_id: string }>(
        `SELECT device_id FROM user_devices WHERE user_id = $1`,
        [userId]
      );

      if (existing.rows.length > 0) {
        const current = existing.rows[0].device_id;
        if (current !== deviceId) {
          return { kind: "user_has_other_device" as const };
        }
        // Idempotent: same device already paired; update nickname if provided
        await client.query(
          `UPDATE user_devices SET nickname = COALESCE($1, nickname) WHERE user_id = $2 AND device_id = $3`,
          [nickname, userId, deviceId]
        );
        return { kind: "paired" as const };
      }

      await client.query(
        `INSERT INTO user_devices (user_id, device_id, nickname) VALUES ($1, $2, $3)`,
        [userId, deviceId, nickname]
      );
      return { kind: "paired" as const };
    });

    if (result.kind === "user_has_other_device") {
      logger.info("devices/pair: user already has a device", { userId });
      return jsonError(
        409,
        "device_already_paired",
        "User already has a device paired. One device per user (MVP)."
      );
    }

    logger.info("devices/pair: success", { userId, deviceId });
    return jsonSuccess({ deviceId, nickname: nickname ?? undefined });
  } catch (e: unknown) {
    const err = e as { code?: string };
    if (err?.code === "23505") {
      // unique_violation: device already paired to another user
      logger.info("devices/pair: device already paired to another account", {
        deviceId,
      });
      return jsonError(
        409,
        "device_owned_by_other",
        "Device is already paired to another account."
      );
    }
    const msg = e instanceof Error ? e.message : String(e);
    logger.error("devices/pair: unexpected error", msg);
    return jsonError(500, "internal_error", "Internal server error");
  }
}
