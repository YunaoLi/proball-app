"use client";

import { useEffect, useState } from "react";

const APP_DEEPLINK = process.env.NEXT_PUBLIC_APP_MOBILE_DEEPLINK ?? "proball://auth";

export default function OAuthSuccessPage() {
  const [status, setStatus] = useState<"loading" | "success" | "error">("loading");
  const [message, setMessage] = useState("Completing sign in...");

  useEffect(() => {
    let cancelled = false;

    async function complete() {
      try {
        const res = await fetch("/api/auth/oauth/mobile-complete", {
          credentials: "include",
        });
        const data = (await res.json()) as {
          ok?: boolean;
          accessToken?: string;
          refreshToken?: string;
          expiresAtMs?: number;
          user?: { id?: string; email?: string; name?: string | null };
        };

        if (cancelled) return;

        if (!res.ok || !data.ok || !data.accessToken) {
          setStatus("error");
          setMessage("Sign in could not be completed. Please try again.");
          return;
        }

        setStatus("success");
        setMessage("Login complete. Redirecting to app...");

        const params = new URLSearchParams({
          accessToken: data.accessToken,
          ...(data.refreshToken && { refreshToken: data.refreshToken }),
          ...(data.expiresAtMs && { expiresAtMs: String(data.expiresAtMs) }),
          ...(data.user?.id && { userId: data.user.id }),
          ...(data.user?.email && { email: data.user.email }),
          ...(data.user?.name && { name: data.user.name }),
        });
        const redirectUrl = `${APP_DEEPLINK}?${params.toString()}`;
        window.location.href = redirectUrl;
      } catch {
        if (!cancelled) {
          setStatus("error");
          setMessage("Something went wrong. Please try again.");
        }
      }
    }

    complete();
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
      {status === "loading" && (
        <>
          <div
            style={{
              width: 40,
              height: 40,
              border: "3px solid #e0e0e0",
              borderTopColor: "#333",
              borderRadius: "50%",
              animation: "spin 0.8s linear infinite",
            }}
          />
          <p style={{ marginTop: 16 }}>{message}</p>
        </>
      )}
      {status === "success" && <p>{message}</p>}
      {status === "error" && (
        <>
          <p style={{ color: "#c00" }}>{message}</p>
          <p style={{ marginTop: 8, fontSize: 14, color: "#666" }}>
            You can close this window and try again in the app.
          </p>
        </>
      )}
      <style>{`
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
}
