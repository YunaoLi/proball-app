-- Report job queue for AI report generation
CREATE TABLE IF NOT EXISTS report_jobs (
  job_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES play_sessions(session_id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('QUEUED', 'PROCESSING', 'DONE', 'FAILED')),
  attempts INT NOT NULL DEFAULT 0,
  max_attempts INT NOT NULL DEFAULT 5,
  run_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  locked_at TIMESTAMPTZ,
  locked_by TEXT,
  last_error TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (session_id)
);

CREATE INDEX IF NOT EXISTS idx_report_jobs_status_run_at
  ON report_jobs (status, run_at)
  WHERE status = 'QUEUED';

CREATE INDEX IF NOT EXISTS idx_report_jobs_locked_at
  ON report_jobs (locked_at)
  WHERE locked_at IS NOT NULL;
