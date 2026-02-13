# Backend must-do checklist (pre frontend integration)

## Production safety

### POST /api/internal/jobs/run
- [x] Protected by `JOB_RUNNER_SECRET` (401 if missing/wrong)
- [x] Limit cap: max 10 jobs per request (default 3)
- [x] `dryRun` option for debugging

## Authorization

| Route | Check |
|-------|-------|
| POST /api/sessions/start | Device must be paired to user (`user_devices`) |
| POST /api/sessions/:id/end | Session must belong to user (`play_sessions.user_id`) |
| GET /api/reports | Reports filtered by `ai_reports.user_id` |
| GET /api/reports/:sessionId | Report must belong to user (`ai_reports.user_id`) |

## Idempotency

- [x] POST /api/sessions/:id/end: Calling end twice returns same result; no duplicate ai_reports or report_jobs (ON CONFLICT)
- [x] Job worker: If ai_reports.status is READY, marks job DONE and skips generation (no duplicate reports)

## API response envelope

All endpoints return:
- Success: `{ "ok": true, ... }`
- Error: `{ "ok": false, "code": "...", "message": "..." }`

## CORS / JWT

- All protected routes use JWT Bearer token (no browser-only cookies)
- Flutter mobile can call API directly; CORS less relevant for native apps

## DB constraints (verified)

- `ai_reports.session_id` PRIMARY KEY → 1:1 with play_sessions
- `user_devices.device_id` UNIQUE → one owner per device
