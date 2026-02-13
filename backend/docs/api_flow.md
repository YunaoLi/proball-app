# API call flow – activation and sequence

This document describes the order of API calls to activate (create an account, obtain a token) and what to call next for protected features.

Base URL: `https://proball-app.vercel.app` (or `http://localhost:3001` locally).

---

## Step 1: Create an account (first time only)

**POST** `/api/auth/sign-up/email`

Creates a new user. Call this **once** before you can sign in or obtain a token.

```bash
BASE="https://proball-app.vercel.app"

curl -s -X POST "$BASE/api/auth/sign-up/email" \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"your-password","name":"Your Name"}'
```

**Success (200):** `{ "user": {...}, "token": "...", "redirect": false }`  
**Error (400):** User already exists or invalid input.

---

## Step 2: Obtain a JWT access token

**POST** `/api/auth/token`

Exchanges email + password for a JWT. Call this **after sign-up** (or when the token expires). This is the "activation" step for all protected APIs.

```bash
curl -s -X POST "$BASE/api/auth/token" \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"your-password"}'
```

**Success (200):**
```json
{
  "ok": true,
  "accessToken": "eyJ...",
  "tokenType": "Bearer",
  "expiresInSec": 900,
  "user": { "id": "...", "email": "you@example.com", "name": "Your Name" }
}
```

**Error (401):** `{ "ok": false, "code": "invalid_credentials", "message": "Invalid email or password" }`

Save the `accessToken` for the next steps:

```bash
TOKEN=$(curl -s -X POST "$BASE/api/auth/token" \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"your-password"}' | jq -r '.accessToken')
```

---

## Step 3: Call protected APIs (with Bearer token)

Add header **`Authorization: Bearer <accessToken>`** to every request. Call these **only after** you have a valid token from Step 2.

### GET /api/me – verify auth, get user id

```bash
curl -s "$BASE/api/me" -H "Authorization: Bearer $TOKEN"
```

**Success:** `{"userId":"...","ok":true}`

### POST /api/devices/pair – pair a device

```bash
curl -s -X POST "$BASE/api/devices/pair" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"deviceId":"550e8400-e29b-41d4-a716-446655440000","deviceName":"My Ball"}'
```

**Success:** `{"deviceId":"...","nickname":"My Ball","ok":true}`

### POST /api/sessions/start – start a play session

Device must be paired first. Idempotent: returns existing ACTIVE session if one exists.

```bash
curl -s -X POST "$BASE/api/sessions/start" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"deviceId":"550e8400-e29b-41d4-a716-446655440000","batteryStart":88,"startedAt":"2026-02-12T01:02:03.000Z"}'
```

**Success:** `{"sessionId":"<uuid>","deviceId":"...","status":"ACTIVE","startedAt":"...","ok":true}`  
**Error (403):** `{ "ok": false, "code": "device_not_paired", "message": "Device is not paired to this user" }`

### POST /api/sessions/[sessionId]/end – end a play session

```bash
# Replace SESSION_ID with the sessionId from start
curl -s -X POST "$BASE/api/sessions/$SESSION_ID/end" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"endedAt":"2026-02-12T01:12:03.000Z","durationSec":600,"calories":18.4,"batteryEnd":84,"metrics":{"steps":321,"rolls":44}}'
```

**Success:** `{"session":{...},"report":{"status":"PENDING"},"ok":true}`  
**Error (404):** `{ "ok": false, "code": "session_not_found", "message": "Session not found" }`

### GET /api/reports – list report history

```bash
curl -s "$BASE/api/reports" -H "Authorization: Bearer $TOKEN"
```

**Success:** `{"reports":[{...}],"ok":true}` (last 50 reports)

### GET /api/reports/[sessionId] – get report by session

```bash
curl -s "$BASE/api/reports/$SESSION_ID" -H "Authorization: Bearer $TOKEN"
```

**Success (PENDING):** `{"sessionId":"...","status":"PENDING","content":null,"ok":true}`  
**Success (READY):** `{"sessionId":"...","status":"READY","content":{...},"ok":true}`  
**Error (404):** `{ "ok": false, "code": "report_not_found", "message": "Report not found" }`

### POST /api/internal/jobs/run – process report jobs (internal)

**No JWT.** Protected by `x-job-secret` header. Used by Vercel Cron or manual trigger to generate AI reports from queued sessions.

```bash
curl -s -X POST "$BASE/api/internal/jobs/run" \
  -H "Content-Type: application/json" \
  -H "x-job-secret: $JOB_RUNNER_SECRET" \
  -d '{"limit":5,"dryRun":false}'
```

**Success:** `{"ok":true,"processed":2,"succeeded":2,"failed":0,"details":[{...}]}`  
**Error (401):** `{ "ok": false, "code": "forbidden", "message": "Invalid or missing x-job-secret" }`

Body defaults: `limit=3`, `dryRun=false`. Limit is capped at 10 (production-safe). Set `JOB_RUNNER_SECRET` in env.

### Other protected endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/devices` | List paired devices |
| POST | `/api/internal/jobs/run` | Process report jobs (x-job-secret, no JWT) |

Protected endpoints require `Authorization: Bearer $TOKEN`. Internal jobs use `x-job-secret` instead.

---

## Summary flow

```
1. POST /api/auth/sign-up/email   →  Create account (once)
2. POST /api/auth/token           →  Get accessToken (login)
3. POST /api/devices/pair         →  Pair device (once per device)
4. POST /api/sessions/start       →  Start play session
5. POST /api/sessions/:id/end     →  End session with metrics (enqueues report job)
6. POST /api/internal/jobs/run   →  Process queued jobs → AI report (cron or manual)
7. GET /api/reports               →  List reports
8. GET /api/reports/:sessionId    →  Get report detail (content when READY)
```

If the token expires (~15 min), call **Step 2** again to get a new token.

---

## Full curl test script

Run the end-to-end test (requires `jq`):

```bash
chmod +x docs/sessions_reports_test.sh

# Local
BASE=http://localhost:3001 EMAIL=your@email.com PASSWORD=your-password ./docs/sessions_reports_test.sh

# Vercel
BASE=https://proball-app.vercel.app EMAIL=your@email.com PASSWORD=your-password ./docs/sessions_reports_test.sh
```

Or run individual curls (set `BASE`, `TOKEN`, and `SESSION_ID` first):

```bash
# Get token
TOKEN=$(curl -s -X POST "$BASE/api/auth/token" -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"your-password"}' | jq -r '.accessToken')

# Start session (use your paired deviceId)
curl -s -X POST "$BASE/api/sessions/start" -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"deviceId":"550e8400-e29b-41d4-a716-446655440000","batteryStart":88}' | jq .

# End session (replace SESSION_ID)
curl -s -X POST "$BASE/api/sessions/SESSION_ID/end" -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"durationSec":600,"calories":18.4}' | jq .

# Process report jobs (requires JOB_RUNNER_SECRET)
curl -s -X POST "$BASE/api/internal/jobs/run" -H "Content-Type: application/json" \
  -H "x-job-secret: $JOB_RUNNER_SECRET" -d '{"limit":5}' | jq .

# List reports
curl -s "$BASE/api/reports" -H "Authorization: Bearer $TOKEN" | jq .

# Get report by session
curl -s "$BASE/api/reports/SESSION_ID" -H "Authorization: Bearer $TOKEN" | jq .
```

---

## Report storage (DB)

When a report is generated:

- **`ai_reports`**: `status` → `READY`, `content_json` → full AI output (summaryTitle, summary, highlights, stats, recommendations, generatedAt)
- **`report_jobs`**: `status` → `DONE` for that session

Example `content_json` shape:
```json
{
  "summaryTitle": "Five-Min Play Spark",
  "summary": "Nice short burst — a 5-minute session...",
  "highlights": ["Duration: 300 seconds...", "..."],
  "stats": { "durationSec": 300, "calories": 9.2, "batteryDelta": -2 },
  "recommendations": ["Repeat 2–3 short sessions...", "..."],
  "generatedAt": "2026-02-13T20:43:18Z"
}
```
