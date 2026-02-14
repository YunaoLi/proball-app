# Frontend integration test

Manual verification steps for backend integration.

## Prerequisites

- Backend running at `https://proball-app.vercel.app` (or override `AppConstants.apiBaseUrl`)
- Flutter app built and running

## Steps

### 1. Sign up

- Open app
- Tap "Don't have an account? Sign up"
- Enter name, email, password
- Tap Sign Up
- Should switch to Sign In form (or navigate if token returned)

### 2. Login → token stored

- Enter email and password
- Tap Sign In
- Token stored in SharedPreferences (`auth_access_token`)
- Navigate to Pair screen (no device paired yet)

### 3. Pair → success

- On Pair screen, select a mock device (e.g. "Pro Ball Alpha")
- Tap to pair
- Should succeed and navigate to Dashboard
- `paired_device_id` stored in SharedPreferences

### 4. Start → sessionId returned

- On Dashboard, tap "Start Play"
- API: POST /api/sessions/start
- Should navigate to Current Play Session with live mock stats
- Session ID from backend

### 5. End → report PENDING

- On Current Play Session, tap "Stop Play"
- API: POST /api/sessions/{sessionId}/end with durationSec, calories, batteryEnd, metrics
- Should navigate to Report Detail
- Report status initially PENDING

### 6. Poll → READY

- Report Detail polls GET /api/reports/{sessionId} every 2s
- When backend job processor has run, status becomes READY
- Content (summary, highlights, etc.) displayed
- Or: run `curl -X POST .../api/internal/jobs/run -H "x-job-secret: ..."` to trigger job

### 7. Report list

- Navigate to Reports tab
- API: GET /api/reports
- List shows session history with status

## Quick curl (backend)

```bash
# Trigger report generation
curl -X POST https://proball-app.vercel.app/api/internal/jobs/run \
  -H "Content-Type: application/json" \
  -H "x-job-secret: $JOB_RUNNER_SECRET" \
  -d '{"limit":5}'
```
