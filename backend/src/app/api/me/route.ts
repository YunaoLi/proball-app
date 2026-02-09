import { verifyJwtAndGetUserId, jsonError, AuthError } from "@/lib/auth";
import { jsonSuccess } from "@/lib/http";

export async function GET(req: Request) {
  try {
    const userId = await verifyJwtAndGetUserId(req);
    return jsonSuccess({ userId });
  } catch (e) {
    if (e instanceof AuthError) {
      return jsonError(401, e.code, e.message);
    }
    return jsonError(500, "internal_error", "Internal server error");
  }
}
