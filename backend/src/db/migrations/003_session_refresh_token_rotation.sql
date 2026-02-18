-- Evolve session table for refresh-token rotation and revocation.
-- sessions.token will store hash(refreshToken); expiresAt = refresh expiry (sliding).
-- revokedAt != null means invalid; replacedBySessionId links rotation chain.

-- Add columns
ALTER TABLE session ADD COLUMN IF NOT EXISTS "revokedAt" TIMESTAMPTZ NULL;
ALTER TABLE session ADD COLUMN IF NOT EXISTS "replacedBySessionId" TEXT NULL;
ALTER TABLE session ADD COLUMN IF NOT EXISTS "lastUsedAt" TIMESTAMPTZ NULL;
ALTER TABLE session ADD COLUMN IF NOT EXISTS "deviceId" TEXT NULL;

-- FK: replacedBySessionId references session(id), ON DELETE SET NULL
ALTER TABLE session
  ADD CONSTRAINT session_replaced_by_fkey
  FOREIGN KEY ("replacedBySessionId")
  REFERENCES session(id)
  ON DELETE SET NULL;

-- Indexes: session_token_key (UNIQUE on token) and session_userId_idx already exist.
