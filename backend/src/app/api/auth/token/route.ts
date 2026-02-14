import { auth } from "@/lib/auth";
import { jsonError, jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";

const BASE_URL =
  process.env.BETTER_AUTH_URL ||
  (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : "http://localhost:3001");
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN ?? "15m";

/** Parse "15m" -> 900, "1h" -> 3600, etc. */
function expiresInToSeconds(s: string): number {
  const match = s.trim().match(/^(\d+)\s*(s|m|h|d)?$/i);
  if (!match) return 900;
  const n = parseInt(match[1], 10);
  const unit = (match[2] ?? "m").toLowerCase();
  if (unit === "s") return n;
  if (unit === "m") return n * 60;
  if (unit === "h") return n * 3600;
  if (unit === "d") return n * 86400;
  return n * 60;
}

export async function POST(req: Request) {
  let body: { email?: string; password?: string };
  try {
    body = (await req.json()) as { email?: string; password?: string };
  } catch {
    return jsonError(400, "invalid_body", "Invalid JSON body");
  }
  const email = typeof body?.email === "string" ? body.email.trim() : "";
  const password = typeof body?.password === "string" ? body.password : "";
  if (!email || !password) {
    return jsonError(401, "invalid_credentials", "Email and password required");
  }

  const signInUrl = `${BASE_URL}/api/auth/sign-in/email`;
  const signInReq = new Request(signInUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });
  const signInRes = await auth.handler(signInReq);
  if (!signInRes.ok) {
    logger.warn("auth/token: sign-in failed", signInRes.status);
    return jsonError(401, "invalid_credentials", "Invalid email or password");
  }
  const setCookie = signInRes.headers.get("set-cookie");
  if (!setCookie) {
    logger.warn("auth/token: no session cookie after sign-in");
    return jsonError(500, "internal_error", "Could not establish session");
  }
  let signInData: { user?: { id?: string; email?: string; name?: string } };
  try {
    signInData = (await signInRes.json()) as {
      user?: { id?: string; email?: string; name?: string };
    };
  } catch {
    signInData = {};
  }
  const user = signInData?.user;

  const tokenUrl = `${BASE_URL}/api/auth/token`;
  const tokenReq = new Request(tokenUrl, {
    method: "GET",
    headers: { Cookie: setCookie },
  });
  const tokenRes = await auth.handler(tokenReq);
  if (!tokenRes.ok) {
    logger.warn("auth/token: get token failed", tokenRes.status);
    return jsonError(500, "internal_error", "Could not issue token");
  }
  let tokenData: { token?: string };
  try {
    tokenData = (await tokenRes.json()) as { token?: string };
  } catch {
    return jsonError(500, "internal_error", "Invalid token response");
  }
  const accessToken = tokenData?.token;
  if (!accessToken || typeof accessToken !== "string") {
    return jsonError(500, "internal_error", "Could not issue token");
  }

  const expiresInSec = expiresInToSeconds(JWT_EXPIRES_IN);
  const expiresAtMs = Date.now() + expiresInSec * 1000;

  // Extract session token for refresh: "better-auth.session_token=value; ..." -> value
  let refreshToken: string | undefined;
  const sessionCookieMatch = setCookie.match(/better-auth\.session_token=([^;]+)/i);
  if (sessionCookieMatch?.[1]) {
    refreshToken = sessionCookieMatch[1].trim();
  }

  return jsonSuccess({
    accessToken,
    refreshToken: refreshToken ?? undefined,
    tokenType: "Bearer",
    expiresInSec,
    expiresAtMs,
    user: {
      id: user?.id ?? "",
      email: user?.email ?? email,
      name: user?.name ?? null,
    },
  });
}
