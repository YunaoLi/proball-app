-- Add timezone column to user table for user-local "today" computation.
-- Existing users default to UTC.
ALTER TABLE "user" ADD COLUMN IF NOT EXISTS timezone TEXT NOT NULL DEFAULT 'UTC';
