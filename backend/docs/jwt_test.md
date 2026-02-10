# JWT auth – cURL test

Use these steps to obtain an access token and call a protected route.

## 1. Get an access token

**POST** `/api/auth/token` with email and password (same credentials as Better Auth sign-in).

```bash
curl -s -X POST http://localhost:3001/api/auth/token \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"your-password"}'
```

Example response:

```json
{
  "ok": true,
  "accessToken": "eyJ...",
  "tokenType": "Bearer",
  "expiresInSec": 900,
  "user": { "id": "...", "email": "you@example.com", "name": "Your Name" }
}
```

Save the `accessToken` for the next step (or use `jq`):

```bash
TOKEN=$(curl -s -X POST http://localhost:3001/api/auth/token \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"your-password"}' | jq -r '.accessToken')
```

## 2. Call a protected route with the token

Send **Authorization: Bearer &lt;token&gt;** on protected endpoints (e.g. `/api/me`, `/api/devices/pair`).

**GET /api/me**

```bash
curl -s http://localhost:3001/api/me \
  -H "Authorization: Bearer $TOKEN"
```

**POST /api/devices/pair**

```bash
curl -s -X POST http://localhost:3001/api/devices/pair \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"deviceId":"550e8400-e29b-41d4-a716-446655440000","deviceName":"My Ball"}'
```

Without a valid Bearer token, these return **401** with body like:

```json
{ "ok": false, "code": "unauthorized", "message": "Missing bearer token" }
```

(or "Invalid or expired token" if the token is malformed or expired).
