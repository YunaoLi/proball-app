import { requireAuth } from "@/lib/auth";
import { jsonSuccess } from "@/lib/http";

export async function GET(req: Request) {
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  return jsonSuccess({ userId: auth.userId });
}
