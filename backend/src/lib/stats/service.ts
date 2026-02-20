import { query } from "@/lib/db";
import type { DailyStatsPoint, TodayStats, WeeklyStats } from "./types";

const DEFAULT_TZ = "UTC";

async function getUserTimezone(userId: string): Promise<string> {
  const res = await query<{ timezone: string }>(
    `SELECT timezone FROM "user" WHERE id = $1`,
    [userId]
  );
  if (res.rows.length === 0 || !res.rows[0].timezone) return DEFAULT_TZ;
  return res.rows[0].timezone;
}

export async function getTodayStats(userId: string): Promise<TodayStats> {
  const tz = await getUserTimezone(userId);
  const tzSafe = tz?.trim() || DEFAULT_TZ;

  const res = await query<{
    date: string;
    total_play_time_sec: string;
    total_calories: string;
    session_count: string;
  }>(
    `SELECT
      (now() AT TIME ZONE $2)::date::text AS date,
      COALESCE(SUM(
        COALESCE(s.duration_sec, CASE WHEN s.ended_at IS NOT NULL THEN EXTRACT(EPOCH FROM (s.ended_at - s.started_at))::int ELSE 0 END)
      ), 0)::bigint AS total_play_time_sec,
      COALESCE(SUM(COALESCE(s.calories, 0)), 0)::double precision AS total_calories,
      COUNT(s.session_id)::int AS session_count
    FROM (SELECT (now() AT TIME ZONE $2)::date AS today) AS d
    LEFT JOIN play_sessions s
      ON s.user_id = $1
      AND (s.started_at AT TIME ZONE $2)::date = d.today
    GROUP BY d.today`,
    [userId, tzSafe]
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
  const tz = await getUserTimezone(userId);
  const tzSafe = tz?.trim() || DEFAULT_TZ;

  const [datesRes, aggRes] = await Promise.all([
    query<{ local_date: string }>(
      `SELECT ((now() AT TIME ZONE $1)::date - $2 + n)::text AS local_date
       FROM generate_series(1, $2) AS n
       ORDER BY n ASC`,
      [tzSafe, days]
    ),
    query<{
      local_date: string;
      total_play_time_sec: string;
      total_calories: string;
      session_count: string;
    }>(
      `SELECT
        (s.started_at AT TIME ZONE $2)::date::text AS local_date,
        COALESCE(SUM(
          COALESCE(s.duration_sec, CASE WHEN s.ended_at IS NOT NULL THEN EXTRACT(EPOCH FROM (s.ended_at - s.started_at))::int ELSE 0 END)
        ), 0)::bigint AS total_play_time_sec,
        COALESCE(SUM(COALESCE(s.calories, 0)), 0)::double precision AS total_calories,
        COUNT(*)::int AS session_count
      FROM play_sessions s
      WHERE s.user_id = $1
        AND (s.started_at AT TIME ZONE $2)::date
          >= (now() AT TIME ZONE $2)::date - ($3::int - 1)
        AND (s.started_at AT TIME ZONE $2)::date
          <= (now() AT TIME ZONE $2)::date
      GROUP BY (s.started_at AT TIME ZONE $2)::date`,
      [userId, tzSafe, days]
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
