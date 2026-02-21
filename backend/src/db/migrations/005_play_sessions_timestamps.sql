-- Ensure play_sessions timestamps are timestamptz and add time-range constraint.
-- Columns are already "timestamp with time zone" in Neon; this migration is idempotent.
-- If your DB had "timestamp without time zone", uncomment and run the ALTERs below first.
-- ALTER TABLE play_sessions ALTER COLUMN started_at TYPE timestamptz USING started_at AT TIME ZONE 'UTC';
-- ALTER TABLE play_sessions ALTER COLUMN ended_at TYPE timestamptz USING ended_at AT TIME ZONE 'UTC';
-- NOTE: Only use AT TIME ZONE 'UTC' if the existing data was stored as UTC instant (no TZ).
-- If data was stored as local time, you need a one-time data fix script (see docs).

-- One-time fix: set ended_at = started_at for any rows where ended_at < started_at.
UPDATE play_sessions
SET ended_at = started_at
WHERE ended_at IS NOT NULL AND ended_at < started_at;

-- Add CHECK constraint: ended_at must be >= started_at when both exist.
ALTER TABLE play_sessions
  DROP CONSTRAINT IF EXISTS play_sessions_ended_after_started;

ALTER TABLE play_sessions
  ADD CONSTRAINT play_sessions_ended_after_started
  CHECK (ended_at IS NULL OR ended_at >= started_at);
