-- ProBall schema: devices, user_devices, play_sessions, ai_reports
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE devices (
  device_id TEXT PRIMARY KEY,
  model TEXT,
  firmware_version TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE user_devices (
  user_id TEXT NOT NULL,
  device_id TEXT NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
  nickname TEXT,
  paired_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, device_id),
  CONSTRAINT one_owner_per_device UNIQUE (device_id)
);

CREATE INDEX idx_user_devices_user_id ON user_devices (user_id);

CREATE TABLE play_sessions (
  session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  device_id TEXT NOT NULL REFERENCES devices(device_id),
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'COMPLETED')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at TIMESTAMPTZ,
  duration_sec INT,
  calories DOUBLE PRECISION,
  battery_start INT,
  battery_end INT,
  metrics_json JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_play_sessions_user_created ON play_sessions (user_id, created_at DESC);

CREATE TABLE ai_reports (
  session_id UUID PRIMARY KEY REFERENCES play_sessions(session_id) ON DELETE CASCADE,
  user_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'READY', 'FAILED')),
  content_json JSONB,
  failure_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_ai_reports_user_created ON ai_reports (user_id, created_at DESC);
