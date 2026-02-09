import { requireAuth } from "@/lib/auth";
import { jsonNotImplemented } from "@/lib/http";

export async function POST(req: Request) {
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  return jsonNotImplemented("POST /api/devices/pair");
}
