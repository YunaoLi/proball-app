import { auth } from "@/lib/auth";
import { createEmailVerificationToken } from "@/lib/email_verification";
import { jsonError, jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";
import { sendVerifyEmail } from "@/lib/mailer";

const BASE_URL =
  process.env.BETTER_AUTH_URL ||
  (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : "http://localhost:3001");

type RegisterBody = { name?: string; email?: string; password?: string };

/**
 * POST /api/auth/register – sign up + send verification email.
 * Wrapper: calls Better Auth sign-up, then sends verification email.
 * Client can use this instead of sign-up/email + resend-verification.
 */
export async function POST(req: Request) {
  let body: RegisterBody;
  try {
    body = (await req.json()) as RegisterBody;
  } catch {
    return jsonError(400, "invalid_body", "Invalid JSON body");
  }

  const name = typeof body?.name === "string" ? body.name.trim() : "";
  const email = typeof body?.email === "string" ? body.email.trim().toLowerCase() : "";
  const password = typeof body?.password === "string" ? body.password : "";

  if (!name || !email || !password) {
    return jsonError(400, "invalid_input", "Name, email, and password are required");
  }

  const signUpUrl = `${BASE_URL}/api/auth/sign-up/email`;
  const signUpReq = new Request(signUpUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name, email, password }),
  });

  const signUpRes = await auth.handler(signUpReq);
  if (!signUpRes.ok) {
    const errBody = await signUpRes.json().catch(() => ({})) as { message?: string };
    logger.warn("register: sign-up failed", signUpRes.status, errBody.message);
    return jsonError(400, "signup_failed", errBody.message ?? "Sign up failed");
  }

  try {
    const { token } = await createEmailVerificationToken(email);
    const verifyUrl = `${BASE_URL.replace(/\/$/, "")}/api/auth/verify?email=${encodeURIComponent(email)}&token=${encodeURIComponent(token)}`;
    await sendVerifyEmail({ to: email, verifyUrl });
    logger.info("register: verification email sent", { email: email.slice(0, 3) + "***" });
  } catch (e) {
    logger.error("register: failed to send verification email", e);
    // Still return success - user is created, they can use resend-verification
  }

  return jsonSuccess({ ok: true, message: "Check your email to verify your account" });
}
