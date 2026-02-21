import { requireVerifiedJWT, jsonError } from "@/lib/auth";
import { query } from "@/lib/db";
import { jsonSuccess } from "@/lib/http";
import { isValidTimezone } from "@/lib/timezone/validateTimezone";

type Body = { timezone?: string };

export async function POST(req: Request) {
  const authed = await requireVerifiedJWT(req);
  if (authed instanceof Response) return authed;
  const { userId } = authed;

  let body: Body;
  try {
    body = (await req.json()) as Body;
  } catch {
    return jsonError(400, "invalid_body", "Invalid JSON body");
  }

  const tz = typeof body?.timezone === "string" ? body.timezone.trim() : "";
  if (!tz) {
    return jsonError(400, "INVALID_TIMEZONE", "timezone is required");
  }
  if (!isValidTimezone(tz)) {
    return jsonError(400, "INVALID_TIMEZONE", "Invalid timezone");
  }

  await query(
    `UPDATE "user" SET timezone = $1, "updatedAt" = now() WHERE id = $2`,
    [tz, userId]
  );

  return jsonSuccess({ timezone: tz });
}
