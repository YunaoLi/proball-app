# API gateway – endpoints and auth

Base URL: `http://localhost:3001` (or `BETTER_AUTH_URL`).

All JSON error responses use the same shape:  
`{ "ok": false, "code": "<code>", "message": "<message>", "details": <optional> }`

Success responses include `"ok": true` and endpoint-specific data.

---

## Public (no auth)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | Liveness/readiness |
| POST | `/api/auth/sign-up/email` | Register with email/password (Better Auth) |
| POST | `/api/auth/sign-in/email` | Sign in with email/password (Better Auth, sets cookie) |
| POST | `/api/auth/token` | Exchange email/password for JWT access token (mobile) |
| GET | `/api/auth/jwks` | JSON Web Key Set for JWT verification |

Other Better Auth routes (sign-out, get-session, etc.) are under `/api/auth/[...all]` and may require a session or Bearer token depending on the endpoint.

---

## Protected (JWT Bearer required)

Require header: **`Authorization: Bearer <access_token>`**  
Obtain `<access_token>` from **POST /api/auth/token** with `{ "email", "password" }`.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/me` | Current user id (`userId`) |
| GET | `/api/devices` | List devices for the current user |
| POST | `/api/devices/pair` | Pair a device (body: `deviceId`, optional `deviceName`) |
| GET | `/api/reports` | Report history for the current user |
| GET | `/api/reports/:sessionId` | Report detail for a session |
| POST | `/api/sessions/start` | Start a play session |
| POST | `/api/sessions/:sessionId/end` | End a play session |

All of these return **401** with `{ "ok": false, "code": "unauthorized", "message": "..." }` if the Bearer token is missing, invalid, or expired. DB writes use the JWT `sub` as the authenticated user id.

---

## Internal

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/internal/jobs/run` | Header `x-cron-secret` (must match `CRON_SECRET`) | Internal job runner (cron) |

Returns **403** if `x-cron-secret` is missing or invalid.
