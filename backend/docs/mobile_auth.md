# Mobile auth (Flutter/Dart) – JWT Bearer

This document describes how the Flutter/Dart app should integrate with the backend’s JWT Bearer auth. **No Flutter code lives in this repo;** this is reference for the mobile team.

---

## Overview

1. **Obtain token:** `POST /api/auth/token` with email + password → receive `accessToken`, `expiresInSec`, and `user`.
2. **Store token:** Use **secure storage** (Keychain on iOS, Keystore on Android). **Do not** use `SharedPreferences` or other non-secure storage for the token.
3. **Send token:** Add header `Authorization: Bearer <accessToken>` on **every** request to protected APIs.
4. **Expiry:** If the server returns **401** (e.g. token expired), treat as “session expired” and **re-login** for MVP. Refresh tokens may be added later.

---

## 1. Obtain token

**Endpoint:** `POST {baseUrl}/api/auth/token`  
**Body:** `{ "email": "user@example.com", "password": "..." }`  
**Response (200):**

```json
{
  "ok": true,
  "accessToken": "eyJ...",
  "tokenType": "Bearer",
  "expiresInSec": 900,
  "user": { "id": "...", "email": "user@example.com", "name": "Display Name" }
}
```

**Error (401):** `{ "ok": false, "code": "invalid_credentials", "message": "Invalid email or password" }`

---

## 2. Store token securely

- **iOS:** Use Keychain (e.g. `flutter_secure_storage` with `iOSOptions.accessibility = KeychainAccessibility.private`).
- **Android:** Use Keystore-backed secure storage (e.g. `flutter_secure_storage` with EncryptedSharedPreferences / Keystore).
- **Do not** use `SharedPreferences`, in-memory only, or plain files for the access token.

Optionally store `expiresInSec` (or computed expiry time) to proactively prompt re-login before the server returns 401.

---

## 3. Authorization header on protected requests

Every request to a protected endpoint must include:

```
Authorization: Bearer <accessToken>
```

Protected endpoints include: `/api/me`, `/api/devices`, `/api/devices/pair`, `/api/reports`, `/api/reports/:sessionId`, `/api/sessions/start`, `/api/sessions/:sessionId/end`.  
See **docs/api_gateway.md** for the full list.

---

## 4. Handle token expiry (401)

- If any protected request returns **401** with body like `{ "ok": false, "code": "unauthorized", "message": "Invalid or expired token" }` (or similar), treat the session as expired.
- **MVP:** Clear stored token and navigate to login; user must sign in again. Refresh tokens are out of scope for MVP.

---

## 5. Dart pseudo-code

Pseudo-code only; adapt to your package names and project structure.

### Login

```dart
// Pseudo-code: call POST /api/auth/token and persist token + user

Future<bool> login(String email, String password) async {
  final baseUrl = 'https://your-api.com'; // or from config
  final response = await http.post(
    Uri.parse('$baseUrl/api/auth/token'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  if (response.statusCode != 200) {
    // 401 invalid credentials, etc.
    return false;
  }

  final data = jsonDecode(response.body);
  if (data['ok'] != true || data['accessToken'] == null) return false;

  final token = data['accessToken'] as String;
  final user = data['user'] as Map<String, dynamic>?;

  // Store in secure storage (Keychain/Keystore), NOT SharedPreferences
  await secureStorage.write(key: 'access_token', value: token);
  if (user != null) {
    await secureStorage.write(key: 'user_id', value: user['id']?.toString());
    // optionally store email, name for UI
  }

  return true;
}
```

### Authenticated HTTP client (inject Bearer token)

```dart
// Pseudo-code: client that adds Authorization: Bearer <token> to every request

Future<http.Response> authenticatedGet(String path) async {
  final token = await secureStorage.read(key: 'access_token');
  if (token == null || token.isEmpty) {
    // No token → redirect to login (e.g. throw or return a sentinel)
    throw SessionExpiredException();
  }

  final baseUrl = 'https://your-api.com';
  return http.get(
    Uri.parse('$baseUrl$path'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
}

// For POST/PUT/PATCH, same idea: add headers: { 'Authorization': 'Bearer $token', ... }
// If response.statusCode == 401, clear token and trigger re-login (navigate to login screen).
```

You can wrap `http.Client` or use an interceptor so that **every** outgoing request to the API gets the `Authorization` header and 401 is handled in one place (e.g. clear storage + navigate to login).

---

## Summary

| Step | Action |
|------|--------|
| Login | `POST /api/auth/token` with email + password → get `accessToken` and `user` |
| Persist | Store `accessToken` (and optionally user id) in **secure storage** (Keychain/Keystore) |
| Requests | Add `Authorization: Bearer <accessToken>` to all protected API calls |
| 401 | Treat as expired session; clear token and re-login (MVP; refresh later) |
