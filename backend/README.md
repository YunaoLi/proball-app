This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Authentication (Better Auth + JWT)

Auth is handled by [Better Auth](https://better-auth.com) with email/password. The handler is mounted at **GET/POST** `/api/auth/[...all]` (runtime: **nodejs**). Protected API routes require **Authorization: Bearer &lt;JWT&gt;** (see `requireJWT` in `src/lib/auth.ts`). Cookie sessions are deprecated in favor of JWT for mobile.

### Environment variables

See `src/lib/env.ts` for the full list. Required and optional:

- `BETTER_AUTH_SECRET` – Secret for Better Auth (min 32 chars; e.g. `openssl rand -base64 32`). **Do not commit.**
- `BETTER_AUTH_URL` – Base URL of the app (e.g. `http://localhost:3001` or `https://your-app.vercel.app`).
- `DATABASE_URL` – PostgreSQL connection string (Better Auth stores users, sessions, and JWKS).
- `JWT_ISSUER` – JWT issuer claim (default: `proball-app`).
- `JWT_AUDIENCE` – JWT audience claim (default: `proball-mobile`).
- `JWT_EXPIRES_IN` – Access token lifetime, e.g. `15m`, `1h` (default: `15m`).
- `JWT_SIGNING_ALG` – Signing algorithm (default: `RS256`). JWKS at **GET** `/api/auth/jwks`.

For **JWT** flow (mobile): **POST** `/api/auth/token` with `{ email, password }` to get an access token; then send **Authorization: Bearer &lt;token&gt;** on protected routes. See **`docs/jwt_test.md`** for cURL examples.

### Create auth tables

Run the Better Auth CLI to create user/session (and JWT plugin `jwks`) tables:

```bash
npx @better-auth/cli migrate
```

### cURL examples (cookies)

**Sign up** (saves session cookie to `cookies.txt`):

```bash
curl -c cookies.txt -X POST http://localhost:3000/api/auth/sign-up/email \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"your-password","name":"Your Name"}'
```

**Sign in** (updates session cookie):

```bash
curl -c cookies.txt -X POST http://localhost:3000/api/auth/sign-in/email \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"your-password"}'
```

**Call a protected route** (send cookie back):

```bash
curl -b cookies.txt http://localhost:3000/api/me
# -> {"userId":"...","ok":true}
```

Without a valid session cookie, `/api/me` and other protected routes return **401**.

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
