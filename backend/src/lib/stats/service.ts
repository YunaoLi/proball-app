import { query } from "@/lib/db";
import type { DailyStatsPoint, TodayStats, WeeklyStats } from "./types";

const DEFAULT_TZ = "UTC";

export async function getTodayStats(userId: string): Promise<TodayStats> {
  const res = await query<{
    date: string;
    total_play_time_sec: string;
    total_calories: string;
    session_count: string;
  }>(
    `WITH tz AS (
      SELECT COALESCE(NULLIF(TRIM(timezone), ''), $2) AS tz FROM "user" WHERE id = $1
    ),
    effective_tz AS (
      SELECT COALESCE((SELECT tz FROM tz), $2) AS tz
    ),
    today_local AS (
      SELECT (now() AT TIME ZONE (SELECT tz FROM effective_tz))::date AS d
    )
    SELECT
      (SELECT d::text FROM today_local) AS date,
      COALESCE(SUM(
        COALESCE(ps.duration_sec, CASE WHEN ps.ended_at IS NOT NULL THEN EXTRACT(EPOCH FROM (ps.ended_at - ps.started_at))::int ELSE 0 END)
      ), 0)::bigint AS total_play_time_sec,
      COALESCE(SUM(COALESCE(ps.calories, 0)), 0)::double precision AS total_calories,
      COUNT(ps.session_id)::int AS session_count
    FROM today_local tl
    LEFT JOIN play_sessions ps
      ON ps.user_id = $1
      AND (ps.started_at AT TIME ZONE (SELECT tz FROM effective_tz))::date = tl.d
    GROUP BY tl.d`,
    [userId, DEFAULT_TZ]
  );

  const row = res.rows[0];
  const date = row?.date ?? new Date().toISOString().slice(0, 10);

  return {
    date: date.length >= 10 ? date.slice(0, 10) : date,
    totalPlayTimeSec: parseInt(row?.total_play_time_sec ?? "0", 10) || 0,
    totalCalories: parseFloat(row?.total_calories ?? "0") || 0,
    sessionCount: parseInt(row?.session_count ?? "0", 10) || 0,
  };
}

export async function getWeeklyStats(
  userId: string,
  days: number
): Promise<WeeklyStats> {
  const [datesRes, aggRes] = await Promise.all([
    query<{ local_date: string }>(
      `WITH tz AS (
        SELECT COALESCE(NULLIF(TRIM(timezone), ''), $2) AS tz FROM "user" WHERE id = $1
      ),
      effective_tz AS (
        SELECT COALESCE((SELECT tz FROM tz), $2) AS tz
      )
      SELECT ((now() AT TIME ZONE (SELECT tz FROM effective_tz))::date - $3 + n)::text AS local_date
       FROM generate_series(1, $3) AS n
       ORDER BY n ASC`,
      [userId, DEFAULT_TZ, days]
    ),
    query<{
      local_date: string;
      total_play_time_sec: string;
      total_calories: string;
      session_count: string;
    }>(
      `WITH tz AS (
        SELECT COALESCE(NULLIF(TRIM(timezone), ''), $2) AS tz FROM "user" WHERE id = $1
      ),
      effective_tz AS (
        SELECT COALESCE((SELECT tz FROM tz), $2) AS tz
      ),
      today_local AS (
        SELECT (now() AT TIME ZONE (SELECT tz FROM effective_tz))::date AS d
      )
      SELECT
        (ps.started_at AT TIME ZONE (SELECT tz FROM effective_tz))::date::text AS local_date,
        COALESCE(SUM(
          COALESCE(ps.duration_sec, CASE WHEN ps.ended_at IS NOT NULL THEN EXTRACT(EPOCH FROM (ps.ended_at - ps.started_at))::int ELSE 0 END)
        ), 0)::bigint AS total_play_time_sec,
        COALESCE(SUM(COALESCE(ps.calories, 0)), 0)::double precision AS total_calories,
        COUNT(*)::int AS session_count
      FROM play_sessions ps
      WHERE ps.user_id = $1
        AND (ps.started_at AT TIME ZONE (SELECT tz FROM effective_tz))::date
          >= (SELECT d FROM today_local) - ($3::int - 1)
        AND (ps.started_at AT TIME ZONE (SELECT tz FROM effective_tz))::date
          <= (SELECT d FROM today_local)
      GROUP BY (ps.started_at AT TIME ZONE (SELECT tz FROM effective_tz))::date`,
      [userId, DEFAULT_TZ, days]
    ),
  ]);

  const byDate = new Map<string, { totalPlayTimeSec: number; totalCalories: number; sessionCount: number }>();
  for (const row of aggRes.rows) {
    const dateStr = row.local_date?.slice(0, 10) ?? "";
    byDate.set(dateStr, {
      totalPlayTimeSec: parseInt(row.total_play_time_sec ?? "0", 10) || 0,
      totalCalories: parseFloat(row.total_calories ?? "0") || 0,
      sessionCount: parseInt(row.session_count ?? "0", 10) || 0,
    });
  }

  const daysList: DailyStatsPoint[] = datesRes.rows.map((row) => {
    const dateStr = row.local_date?.slice(0, 10) ?? "";
    const agg = byDate.get(dateStr);
    return {
      date: dateStr,
      totalPlayTimeSec: agg?.totalPlayTimeSec ?? 0,
      totalCalories: agg?.totalCalories ?? 0,
      sessionCount: agg?.sessionCount ?? 0,
    };
  });

  return { days: daysList };
}
