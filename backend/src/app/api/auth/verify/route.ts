import { consumeEmailVerificationToken, markUserVerified } from "@/lib/email_verification";
import { logger } from "@/lib/logger";
import { NextResponse } from "next/server";

const BASE_URL =
  process.env.BETTER_AUTH_URL ||
  (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : "http://localhost:3001");
const APP_MOBILE_DEEPLINK = process.env.APP_MOBILE_DEEPLINK ?? "proball://auth";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const email = searchParams.get("email")?.trim();
  const token = searchParams.get("token")?.trim();

  if (!email || !token) {
    const errUrl = `${BASE_URL.replace(/\/$/, "")}/?verified=0`;
    return NextResponse.redirect(errUrl);
  }

  const ok = await consumeEmailVerificationToken(email, token);
  if (!ok) {
    logger.warn("verify: invalid or expired token", { email: email.slice(0, 3) + "***" });
    const errUrl = `${BASE_URL.replace(/\/$/, "")}/?verified=0`;
    return NextResponse.redirect(errUrl);
  }

  await markUserVerified(email);
  logger.info("verify: success", { email: email.slice(0, 3) + "***" });

  const userAgent = req.headers.get("User-Agent") ?? "";
  const isMobile = /mobile|android|iphone|ipad|ipod|webos|blackberry|iemobile|opera mini/i.test(
    userAgent.toLowerCase()
  );

  const redirectUrl = isMobile
    ? `${APP_MOBILE_DEEPLINK}?verified=1`
    : `${BASE_URL.replace(/\/$/, "")}/?verified=1`;

  return NextResponse.redirect(redirectUrl, 302);
}
