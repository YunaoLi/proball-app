# Backend must-do checklist (pre frontend integration)

## Production safety

### POST /api/internal/jobs/run
- [x] Protected by `JOB_RUNNER_SECRET` (401 if missing/wrong)
- [x] GET also supported for Vercel Cron (validates `x-job-secret` or `Authorization: Bearer` with `JOB_RUNNER_SECRET` or `CRON_SECRET`)
- [x] Limit cap: max 10 jobs per request (default 10)
- [x] `dryRun` option for debugging

### Vercel Cron (report jobs)
- `vercel.json` schedules `GET /api/internal/jobs/run` every 2 minutes
- Set `CRON_SECRET` in Vercel env (same value as `JOB_RUNNER_SECRET` recommended) so cron requests are authorized

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
