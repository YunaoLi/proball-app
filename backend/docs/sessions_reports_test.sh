#!/bin/bash
# End-to-end curl test: token → pair → start → end → reports → stats
# Usage: BASE=http://localhost:3001 EMAIL=you@example.com PASSWORD=pass ./docs/sessions_reports_test.sh
# For Vercel: BASE=https://proball-app.vercel.app (ensure stats routes are deployed)

BASE="${BASE:-https://proball-app.vercel.app}"
EMAIL="${EMAIL:-you@example.com}"
PASSWORD="${PASSWORD:-your-password}"
DEVICE_ID="550e8400-e29b-41d4-a716-446655440000"

echo "=== 1. Get token ==="
TOKEN=$(curl -s -X POST "$BASE/api/auth/token" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" | jq -r '.accessToken')
if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "Login failed - check EMAIL and PASSWORD"
  exit 1
fi
echo "Token obtained"

echo ""
echo "=== 2. Pair device ==="
curl -s -X POST "$BASE/api/devices/pair" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"deviceId\":\"$DEVICE_ID\",\"deviceName\":\"Test Ball\"}" | jq .

echo ""
echo "=== 3. Start session ==="
START=$(curl -s -X POST "$BASE/api/sessions/start" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"deviceId\":\"$DEVICE_ID\",\"batteryStart\":88}")
echo "$START" | jq .
SESSION_ID=$(echo "$START" | jq -r '.sessionId')
if [ "$SESSION_ID" = "null" ] || [ -z "$SESSION_ID" ]; then
  echo "Start failed"
  exit 1
fi

echo ""
echo "=== 4. End session ==="
curl -s -X POST "$BASE/api/sessions/$SESSION_ID/end" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"durationSec":600,"calories":18.4,"batteryEnd":84,"metrics":{"steps":321,"rolls":44}}' | jq .

echo ""
echo "=== 5. Run job processor (generate AI report) ==="
echo "Note: Requires JOB_RUNNER_SECRET. For local: x-job-secret: dev-job-secret"
curl -s -X POST "$BASE/api/internal/jobs/run" \
  -H "Content-Type: application/json" \
  -H "x-job-secret: ${JOB_RUNNER_SECRET:-dev-job-secret}" \
  -d '{"limit":5}' | jq .

echo ""
echo "=== 6. List reports ==="
curl -s "$BASE/api/reports" -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "=== 7. Get report by session ==="
curl -s "$BASE/api/reports/$SESSION_ID" -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "=== 8. Stats today ==="
_resp=$(curl -s -w "\n%{http_code}" "$BASE/api/stats/today" -H "Authorization: Bearer $TOKEN")
_code=$(echo "$_resp" | tail -n1)
_body=$(echo "$_resp" | sed '$d')
echo "$_body" | jq . 2>/dev/null || echo "$_body"
[ "$_code" != "200" ] && echo "(HTTP $_code - deploy stats routes if using Vercel)"

echo ""
echo "=== 9. Stats weekly (7 days, ascending) ==="
_resp=$(curl -s -w "\n%{http_code}" "$BASE/api/stats/weekly?days=7" -H "Authorization: Bearer $TOKEN")
_code=$(echo "$_resp" | tail -n1)
_body=$(echo "$_resp" | sed '$d')
echo "$_body" | jq . 2>/dev/null || echo "$_body"
[ "$_code" != "200" ] && echo "(HTTP $_code - deploy stats routes if using Vercel)"

echo ""
echo "=== Done ==="
