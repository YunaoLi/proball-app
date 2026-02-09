import { requireAuth } from "@/lib/auth";
import { jsonNotImplemented } from "@/lib/http";

type Params = { params: Promise<{ sessionId: string }> };

export async function GET(req: Request, { params }: Params) {
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const { sessionId } = await params;
  return jsonNotImplemented(`GET /api/reports/${sessionId}`);
}
