import { requireAuth } from "@/lib/auth";
import { jsonNotImplemented } from "@/lib/http";

type Params = { params: Promise<{ sessionId: string }> };

export async function POST(req: Request, { params }: Params) {
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const { sessionId } = await params;
  return jsonNotImplemented(`POST /api/sessions/${sessionId}/end`);
}
