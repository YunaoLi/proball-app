import { requireJWT } from "@/lib/auth";
import { jsonNotImplemented } from "@/lib/http";

export async function GET(req: Request) {
  const authed = await requireJWT(req);
  if (authed instanceof Response) return authed;
  const { userId } = authed;
  void userId;
  return jsonNotImplemented("GET /api/reports");
}
