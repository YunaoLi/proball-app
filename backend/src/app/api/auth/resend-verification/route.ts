import { query } from "@/lib/db";
import { createEmailVerificationToken } from "@/lib/email_verification";
import { jsonError, jsonSuccess } from "@/lib/http";
import { logger } from "@/lib/logger";
import { sendVerifyEmail } from "@/lib/mailer";

const BASE_URL =
  process.env.BETTER_AUTH_URL ||
  (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : "http://localhost:3001");

type ResendBody = { email?: string };

export async function POST(req: Request) {
  let body: ResendBody;
  try {
    body = (await req.json()) as ResendBody;
  } catch {
    return jsonError(400, "invalid_body", "Invalid JSON body");
  }

  const email = typeof body?.email === "string" ? body.email.trim().toLowerCase() : "";
  if (!email) {
    return jsonError(400, "invalid_email", "Email is required");
  }

  try {
    const userRes = await query<{ "emailVerified": boolean }>(
      `SELECT "emailVerified" FROM "user" WHERE email = $1`,
      [email]
    );

    if (userRes.rows.length === 0) {
      return jsonError(404, "user_not_found", "User not found");
    }

    if (userRes.rows[0].emailVerified === true) {
      return jsonSuccess({ ok: true, alreadyVerified: true });
    }

    const { token } = await createEmailVerificationToken(email);
    const verifyUrl = `${BASE_URL.replace(/\/$/, "")}/api/auth/verify?email=${encodeURIComponent(email)}&token=${encodeURIComponent(token)}`;

    await sendVerifyEmail({ to: email, verifyUrl });

    logger.info("resend-verification: sent", { email: email.slice(0, 3) + "***" });
    return jsonSuccess({ ok: true, sent: true });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error("resend-verification: error", msg);
    return jsonError(500, "internal_error", "Failed to send verification email");
  }
}
