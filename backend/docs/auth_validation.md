# Auth validation – middleware, endpoints, error handling

## 1. Middleware vs per-route auth

**We do NOT use Next.js middleware.** Auth is enforced **per-route** by calling `requireJWT(req)` at the top of each protected handler:

```typescript
const authed = await requireJWT(req);
if (authed instanceof Response) return authed;
const { userId } = authed;
```

Every protected route must include this pattern. There is no central middleware that intercepts all `/api/*`–each route is responsible for auth.

---

## 2. Protected routes (all use requireJWT)

| Route | Method | Auth |
|-------|--------|------|
| `/api/me` | GET | requireJWT |
| `/api/devices` | GET | requireJWT |
| `/api/devices/pair` | POST | requireJWT |
| `/api/reports` | GET | requireJWT |
| `/api/reports/:sessionId` | GET | requireJWT |
| `/api/sessions/start` | POST | requireJWT |
| `/api/sessions/:sessionId/end` | POST | requireJWT |

**Public routes (no JWT):**

| Route | Method | Auth |
|-------|--------|------|
| `/api/health` | GET | none |
| `/api/auth/sign-up/email` | POST | none |
| `/api/auth/sign-in/email` | POST | none |
| `/api/auth/token` | POST | none |
| `/api/auth/jwks` | GET | none |
| `/api/internal/jobs/run` | POST | x-cron-secret |

---

## 3. requireJWT error handling

`requireJWT(req)` returns a `Response` with these 401 cases:

| Condition | Code | Message |
|-----------|------|---------|
| No `Authorization` header | 401 | "Missing bearer token" |
| Header not `Bearer <token>` | 401 | "Missing bearer token" |
| Empty token after `Bearer ` | 401 | "Missing bearer token" |
| JWT invalid or expired | 401 | "Invalid or expired token" |
| JWT missing `sub` claim | 401 | "Invalid token" |

All responses use `{ ok: false, code: "unauthorized", message: "..." }`.

---

## 4. Validation script (run against prod or local)

Set `BASE`, `EMAIL`, `PASSWORD` then run the script below. It validates:

- Public endpoints work without token
- Protected endpoints return 401 without token
- Protected endpoints return 401 with invalid token
- Protected endpoints return 200 with valid token

```bash
#!/bin/bash
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
```

Save as `docs/validate_auth.sh`, then:

```bash
chmod +x docs/validate_auth.sh
BASE=https://proball-app.vercel.app EMAIL=your@email.com PASSWORD=your-password ./docs/validate_auth.sh
```
