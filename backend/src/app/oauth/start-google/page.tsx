"use client";

import { useEffect, useRef } from "react";

/**
 * Auto-submits a form to Better Auth sign-in/social (POST).
 * Flutter opens this URL in webview; form POST redirects to Google OAuth.
 */
export default function OAuthStartGooglePage() {
  const formRef = useRef<HTMLFormElement>(null);

  useEffect(() => {
    formRef.current?.requestSubmit();
  }, []);

  const baseUrl =
    typeof window !== "undefined"
      ? `${window.location.origin}`
      : process.env.NEXT_PUBLIC_APP_BASE_URL ?? "https://proball-app.vercel.app";
  const callbackUrl = `${baseUrl}/oauth/success`;
  const actionUrl = `${baseUrl}/api/auth/sign-in/social`;

  return (
    <div
      style={{
        minHeight: "100vh",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        padding: 24,
        fontFamily: "system-ui, sans-serif",
      }}
    >
      <p>Redirecting to Google...</p>
      <form
        ref={formRef}
        method="POST"
        action={actionUrl}
        style={{ display: "none" }}
      >
        <input type="hidden" name="provider" value="google" />
        <input type="hidden" name="callbackURL" value={callbackUrl} />
      </form>
    </div>
  );
}
