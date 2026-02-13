#!/bin/bash
# Validate auth: public endpoints, protected 401 without token, protected 200 with token.
# Usage: BASE=https://proball-app.vercel.app EMAIL=you@example.com PASSWORD=pass ./docs/validate_auth.sh

BASE="${BASE:-https://proball-app.vercel.app}"
EMAIL="${EMAIL:-you@example.com}"
PASSWORD="${PASSWORD:-your-password}"

echo "=== 1. Public: GET /api/health (no auth) ==="
curl -s -w "\nHTTP %{http_code}\n" "$BASE/api/health" | tail -2

echo ""
echo "=== 2. Protected: GET /api/me without token (expect 401) ==="
curl -s -w "\nHTTP %{http_code}\n" "$BASE/api/me" | tail -2

echo ""
echo "=== 3. Protected: GET /api/me with invalid token (expect 401) ==="
curl -s -w "\nHTTP %{http_code}\n" "$BASE/api/me" -H "Authorization: Bearer invalid-token" | tail -2

echo ""
echo "=== 4. Get valid token ==="
TOKEN=$(curl -s -X POST "$BASE/api/auth/token" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" | jq -r '.accessToken')
if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "FAIL: Could not get token (check credentials)"
  exit 1
fi
echo "Token obtained (length ${#TOKEN})"

echo ""
echo "=== 5. Protected: GET /api/me with valid token (expect 200) ==="
curl -s -w "\nHTTP %{http_code}\n" "$BASE/api/me" -H "Authorization: Bearer $TOKEN" | tail -2

echo ""
echo "=== 6. Protected: GET /api/devices (expect 200 or 501) ==="
curl -s -w "\nHTTP %{http_code}\n" "$BASE/api/devices" -H "Authorization: Bearer $TOKEN" | tail -2

echo ""
echo "=== 7. Protected: POST /api/devices/pair (expect 200) ==="
curl -s -w "\nHTTP %{http_code}\n" -X POST "$BASE/api/devices/pair" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"deviceId":"550e8400-e29b-41d4-a716-446655440000","deviceName":"Test Ball"}' | tail -2

echo ""
echo "=== 8. Protected: GET /api/reports (expect 501) ==="
curl -s -w "\nHTTP %{http_code}\n" "$BASE/api/reports" -H "Authorization: Bearer $TOKEN" | tail -2

echo ""
echo "=== 9. Protected: POST /api/sessions/start (expect 501) ==="
curl -s -w "\nHTTP %{http_code}\n" -X POST "$BASE/api/sessions/start" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" | tail -2

echo ""
echo "=== 10. Protected: POST /api/sessions/xxx/end (expect 501) ==="
curl -s -w "\nHTTP %{http_code}\n" -X POST "$BASE/api/sessions/00000000-0000-0000-0000-000000000000/end" \
  -H "Authorization: Bearer $TOKEN" | tail -2

echo ""
echo "=== 11. Protected: GET /api/reports/xxx (expect 501) ==="
curl -s -w "\nHTTP %{http_code}\n" "$BASE/api/reports/00000000-0000-0000-0000-000000000000" \
  -H "Authorization: Bearer $TOKEN" | tail -2

echo ""
echo "=== Done ==="
