import { jsonSuccess } from "@/lib/http";

export async function GET() {
  return jsonSuccess({
    timestamp: new Date().toISOString(),
  });
}
