# Auth validation – middleware, endpoints, error handling

## 1. Access + refresh token model

We use **access tokens** (short-lived JWT) for API auth and **refresh tokens** (long-lived, stored hashed in DB) to obtain new access tokens without re-login.

| Token | Purpose | Lifetime | Storage |
|-------|---------|----------|---------|
| Access token | `Authorization: Bearer <token>` on protected API requests | ~15 min (configurable) | Client memory / secure storage |
| Refresh token | Exchange for new access + refresh via `/api/auth/refresh` | ~30 days (configurable) | Client secure storage; server stores hash in `session` table |

**Flow:**
1. **Login** (`POST /api/auth/token`): Returns `accessToken` + `refreshToken`. Creates session row with `hash(refreshToken)`.
2. **API calls**: Send `Authorization: Bearer <accessToken>`.
3. **Refresh** (`POST /api/auth/refresh`): Send refresh token → get new access + refresh. Old session revoked, new session created (rotation).
4. **Logout** (`POST /api/auth/logout`): Send refresh token → server revokes session. Client clears local tokens.

---

## 2. Middleware vs per-route auth

**We do NOT use Next.js middleware.** Auth is enforced **per-route** by calling `requireJWT(req)` at the top of each protected handler:

```typescript
const authed = await requireJWT(req);
if (authed instanceof Response) return authed;
const { userId } = authed;
```

Every protected route must include this pattern. There is no central middleware that intercepts all `/api/*`–each route is responsible for auth.

---

## 3. Protected routes (all use requireJWT)

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
| `/api/auth/refresh` | POST | none (body/header: refresh token) |
| `/api/auth/logout` | POST | none (body/header: refresh token) |
| `/api/auth/jwks` | GET | none |
| `/api/internal/jobs/run` | POST | x-cron-secret |

---

## 4. requireJWT error handling

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

## 5. Auth endpoint contracts

**POST /api/auth/token** (login)  
Body: `{ email, password }`  
Response: `{ ok: true, accessToken, refreshToken, tokenType: "Bearer", expiresInSec, expiresAtMs, user: { id, email, name } }`

**POST /api/auth/refresh**  
Body: `{ refreshToken }` or `Authorization: Bearer <refreshToken>`  
Response: `{ ok: true, accessToken, refreshToken, expiresInSec }`  
Failure: `401 { error: "REFRESH_INVALID" }`

**POST /api/auth/logout**  
Body: `{ refreshToken }` or `Authorization: Bearer <refreshToken>`  
Response: `204 No Content`

---

## 6. Validation script (run against prod or local)

Set `BASE`, `EMAIL`, `PASSWORD` then run the script below. It validates:

- Public endpoints work without token
- Protected endpoints return 401 without token
- Protected endpoints return 401 with invalid token
- Protected endpoints return 200 with valid access token
- Refresh returns new access + refresh tokens
- Logout revokes refresh token (refresh fails afterward)

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
echo "=== 4. Get access + refresh token (login) ==="
LOGIN_RESP=$(curl -s -X POST "$BASE/api/auth/token" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
TOKEN=$(echo "$LOGIN_RESP" | jq -r '.accessToken')
REFRESH=$(echo "$LOGIN_RESP" | jq -r '.refreshToken')
if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "FAIL: Could not get token (check credentials)"
  exit 1
fi
echo "Access token obtained (length ${#TOKEN}), refresh token (length ${#REFRESH})"

echo ""
echo "=== 5. Protected: GET /api/me with valid token (expect 200) ==="
curl -s -w "\nHTTP %{http_code}\n" "$BASE/api/me" -H "Authorization: Bearer $TOKEN" | tail -2

echo ""
echo "=== 6. Refresh: get new access + refresh (expect 200) ==="
REFRESH_RESP=$(curl -s -w "\nHTTP %{http_code}\n" -X POST "$BASE/api/auth/refresh" \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH\"}")
HTTP_CODE=$(echo "$REFRESH_RESP" | tail -1)
BODY=$(echo "$REFRESH_RESP" | sed '$d')
if [[ "$HTTP_CODE" == *"200"* ]]; then
  TOKEN=$(echo "$BODY" | jq -r '.accessToken')
  REFRESH=$(echo "$BODY" | jq -r '.refreshToken')
  echo "Refresh OK, new tokens obtained"
else
  echo "FAIL: Refresh returned $HTTP_CODE"
fi

echo ""
echo "=== 7. Protected: GET /api/devices (expect 200 or 501) ==="
curl -s -w "\nHTTP %{http_code}\n" "$BASE/api/devices" -H "Authorization: Bearer $TOKEN" | tail -2

echo ""
echo "=== 8. Logout: revoke refresh token (expect 204) ==="
curl -s -w "\nHTTP %{http_code}\n" -X POST "$BASE/api/auth/logout" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $REFRESH" \
  -d "{\"refreshToken\":\"$REFRESH\"}" | tail -2

echo ""
echo "=== 9. Refresh with revoked token (expect 401) ==="
curl -s -w "\nHTTP %{http_code}\n" -X POST "$BASE/api/auth/refresh" \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH\"}" | tail -2

echo ""
echo "=== 10. Re-login for remaining tests ==="
LOGIN_RESP=$(curl -s -X POST "$BASE/api/auth/token" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
TOKEN=$(echo "$LOGIN_RESP" | jq -r '.accessToken')

echo ""
echo "=== 11. Protected: POST /api/devices/pair (expect 200) ==="
curl -s -w "\nHTTP %{http_code}\n" -X POST "$BASE/api/devices/pair" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"deviceId":"550e8400-e29b-41d4-a716-446655440000","deviceName":"Test Ball"}' | tail -2

echo ""
echo "=== 12. Protected: GET /api/reports (expect 501) ==="
curl -s -w "\nHTTP %{http_code}\n" "$BASE/api/reports" -H "Authorization: Bearer $TOKEN" | tail -2

echo ""
echo "=== 13. Protected: POST /api/sessions/start (expect 501) ==="
curl -s -w "\nHTTP %{http_code}\n" -X POST "$BASE/api/sessions/start" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" | tail -2

echo ""
echo "=== 14. Protected: POST /api/sessions/xxx/end (expect 501) ==="
curl -s -w "\nHTTP %{http_code}\n" -X POST "$BASE/api/sessions/00000000-0000-0000-0000-000000000000/end" \
  -H "Authorization: Bearer $TOKEN" | tail -2

echo ""
echo "=== 15. Protected: GET /api/reports/xxx (expect 501) ==="
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
