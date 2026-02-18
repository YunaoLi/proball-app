"use client";

import { useEffect, useState } from "react";

/**
 * POSTs JSON to Better Auth sign-in/social, then redirects to Google OAuth.
 * Better Auth requires Content-Type: application/json (form-urlencoded is rejected).
 */
export default function OAuthStartGooglePage() {
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function startOAuth() {
      const baseUrl =
        typeof window !== "undefined"
          ? window.location.origin
          : "https://proball-app.vercel.app";
      const callbackUrl = `${baseUrl}/oauth/success`;
      const actionUrl = `${baseUrl}/api/auth/sign-in/social`;

      try {
        const res = await fetch(actionUrl, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ provider: "google", callbackURL: callbackUrl }),
          credentials: "include",
          redirect: "manual",
        });

        if (cancelled) return;

        const location = res.headers.get("Location");
        if (res.status >= 300 && res.status < 400 && location) {
          window.location.href = location;
          return;
        }
        const data = (await res.json().catch(() => ({}))) as { url?: string };
        if (data?.url) {
          window.location.href = data.url;
          return;
        }
        setError(`Sign-in failed (${res.status})`);
      } catch (e) {
        if (!cancelled) {
          setError("Something went wrong. Please try again.");
        }
      }
    }

    startOAuth();
    return () => {
      cancelled = true;
    };
  }, []);

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
      {error ? (
        <p style={{ color: "#c00" }}>{error}</p>
      ) : (
        <p>Redirecting to Google...</p>
      )}
    </div>
  );
}
