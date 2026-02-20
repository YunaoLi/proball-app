export type DailyStatsPoint = {
  date: string;
  totalPlayTimeSec: number;
  totalCalories: number;
  sessionCount: number;
};

export type TodayStats = DailyStatsPoint;

export type WeeklyStats = {
  days: DailyStatsPoint[];
};
