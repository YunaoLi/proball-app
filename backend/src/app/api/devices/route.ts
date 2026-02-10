import { requireJWT } from "@/lib/auth";
import { jsonNotImplemented } from "@/lib/http";

export async function GET(req: Request) {
  const authed = await requireJWT(req);
  if (authed instanceof Response) return authed;
  const { userId } = authed;
  void userId; // binding key for user-specific data when implemented
  return jsonNotImplemented("GET /api/devices");
}
