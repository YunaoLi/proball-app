import { requireJWT } from "@/lib/auth";
import { jsonNotImplemented } from "@/lib/http";

type Params = { params: Promise<{ sessionId: string }> };

export async function GET(req: Request, { params }: Params) {
  const authed = await requireJWT(req);
  if (authed instanceof Response) return authed;
  const { userId } = authed;
  const { sessionId } = await params;
  void userId;
  return jsonNotImplemented(`GET /api/reports/${sessionId}`);
}
