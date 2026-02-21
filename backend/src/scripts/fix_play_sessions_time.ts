/**
 * One-time DB cleanup: fix play_sessions rows where ended_at < started_at.
 * Caused by earlier timezone bug. Run locally against Neon:
 *
 *   DATABASE_URL="postgresql://..." npx tsx src/scripts/fix_play_sessions_time.ts
 *
 * For each bad row:
 * - If duration_sec is positive and reasonable (< 24h), set ended_at = started_at + duration_sec
 * - Else set ended_at = started_at (safe fallback)
 */

import "dotenv/config";
import { getPool } from "../lib/db";

const MAX_DURATION_SEC = 24 * 3600; // 24 hours

async function main() {
  const pool = getPool();

  const bad = await pool.query<{
    session_id: string;
    started_at: Date;
    ended_at: Date;
    duration_sec: number | null;
  }>(
    `SELECT session_id, started_at, ended_at, duration_sec
     FROM play_sessions
     WHERE ended_at IS NOT NULL AND ended_at < started_at`
  );

  if (bad.rows.length === 0) {
    console.log("No rows with ended_at < started_at. Nothing to fix.");
    process.exit(0);
  }

  console.log(`Found ${bad.rows.length} bad row(s).`);

  for (const row of bad.rows) {
    const durationSec = row.duration_sec;
    const useDuration =
      durationSec != null &&
      durationSec > 0 &&
      durationSec <= MAX_DURATION_SEC;

    if (useDuration) {
      await pool.query(
        `UPDATE play_sessions
         SET ended_at = started_at + ($1::int * interval '1 second')
         WHERE session_id = $2`,
        [durationSec, row.session_id]
      );
      console.log(`  ${row.session_id}: set ended_at = started_at + ${durationSec}s`);
    } else {
      await pool.query(
        `UPDATE play_sessions SET ended_at = started_at WHERE session_id = $1`,
        [row.session_id]
      );
      console.log(`  ${row.session_id}: set ended_at = started_at (fallback)`);
    }
  }

  console.log("Done.");
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
