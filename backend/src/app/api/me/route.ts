import { requireVerifiedJWT } from "@/lib/auth";
import { jsonSuccess } from "@/lib/http";

export async function GET(req: Request) {
  const authed = await requireVerifiedJWT(req);
  if (authed instanceof Response) return authed;
  const { userId } = authed;
  return jsonSuccess({ userId });
}
