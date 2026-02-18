import { Resend } from "resend";
import { logger } from "./logger";

const RESEND_API_KEY = process.env.RESEND_API_KEY;
const EMAIL_FROM = process.env.EMAIL_FROM ?? "ProBall <no-reply@proball.dev>";

/**
 * Send verification email. Uses Resend when RESEND_API_KEY is set.
 * No secrets in logs.
 */
export async function sendVerifyEmail({
  to,
  verifyUrl,
}: {
  to: string;
  verifyUrl: string;
}): Promise<void> {
  if (!RESEND_API_KEY || RESEND_API_KEY.trim() === "") {
    logger.warn("mailer: RESEND_API_KEY not set, skipping verification email");
    return;
  }

  const resend = new Resend(RESEND_API_KEY);

  const { error } = await resend.emails.send({
    from: EMAIL_FROM,
    to: [to],
    subject: "Verify your ProBall email",
    html: `
      <p>Thanks for signing up for ProBall!</p>
      <p>Please verify your email by clicking the link below:</p>
      <p><a href="${verifyUrl}">${verifyUrl}</a></p>
      <p>This link expires in 24 hours.</p>
      <p>If you didn't create an account, you can ignore this email.</p>
    `,
  });

  if (error) {
    logger.error("mailer: Resend send failed", error.message);
    throw new Error("Failed to send verification email");
  }
}
