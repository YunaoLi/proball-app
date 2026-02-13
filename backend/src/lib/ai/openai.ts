/**
 * OpenAI client for AI report generation.
 * Uses Chat Completions API. Requires OPENAI_API_KEY.
 */

export type SessionForReport = {
  session_id: string;
  user_id: string;
  device_id: string;
  started_at: string;
  ended_at: string | null;
  duration_sec: number | null;
  calories: number | null;
  battery_start: number | null;
  battery_end: number | null;
  metrics_json: Record<string, unknown> | null;
  device_nickname?: string | null;
};

export type ReportContentJson = {
  summaryTitle: string;
  summary: string;
  highlights: string[];
  stats: {
    durationSec: number;
    calories: number | null;
    batteryDelta: number | null;
  };
  recommendations: string[];
  generatedAt: string;
};

const MODEL = process.env.OPENAI_MODEL ?? "gpt-4o-mini";

/**
 * Generate an AI report for a play session.
 * Returns parsed JSON content. Throws on API error or invalid JSON.
 */
export async function generateSessionReport(params: {
  session: SessionForReport;
}): Promise<ReportContentJson> {
  const { session } = params;
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey || apiKey.trim() === "") {
    throw new Error("OPENAI_API_KEY is not set");
  }

  const batteryDelta =
    session.battery_start != null && session.battery_end != null
      ? session.battery_end - session.battery_start
      : null;

  const systemPrompt = `You are a fitness and pet activity coach. Analyze play session data and output a brief, encouraging report.
Output valid JSON only, no markdown or extra text. Use this exact schema:
{
  "summaryTitle": "string (short catchy title)",
  "summary": "string (2-3 sentences)",
  "highlights": ["string", "..."],
  "stats": {
    "durationSec": number,
    "calories": number|null,
    "batteryDelta": number|null
  },
  "recommendations": ["string", "..."],
  "generatedAt": "ISO8601 string"
}`;

  const userPrompt = `Session data:
- Session ID: ${session.session_id}
- Device: ${session.device_nickname ?? session.device_id}
- Started: ${session.started_at}
- Ended: ${session.ended_at ?? "N/A"}
- Duration (sec): ${session.duration_sec ?? "N/A"}
- Calories: ${session.calories ?? "N/A"}
- Battery start: ${session.battery_start ?? "N/A"}
- Battery end: ${session.battery_end ?? "N/A"}
- Battery delta: ${batteryDelta ?? "N/A"}
- Metrics: ${JSON.stringify(session.metrics_json ?? {})}

Generate the report JSON.`;

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: MODEL,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
      response_format: { type: "json_object" },
    }),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`OpenAI API error ${res.status}: ${errText.slice(0, 200)}`);
  }

  const data = (await res.json()) as { choices?: Array<{ message?: { content?: string } }> };
  const content = data.choices?.[0]?.message?.content;
  if (!content || typeof content !== "string") {
    throw new Error("OpenAI returned empty or invalid response");
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(content);
  } catch {
    throw new Error("invalid_json");
  }

  const obj = parsed as Record<string, unknown>;
  const result: ReportContentJson = {
    summaryTitle: typeof obj.summaryTitle === "string" ? obj.summaryTitle : "",
    summary: typeof obj.summary === "string" ? obj.summary : "",
    highlights: Array.isArray(obj.highlights)
      ? obj.highlights.filter((h): h is string => typeof h === "string")
      : [],
    stats: {
      durationSec: typeof obj.stats === "object" && obj.stats && typeof (obj.stats as Record<string, unknown>).durationSec === "number"
        ? (obj.stats as Record<string, unknown>).durationSec as number
        : session.duration_sec ?? 0,
      calories: typeof obj.stats === "object" && obj.stats && (obj.stats as Record<string, unknown>).calories != null
        ? (obj.stats as Record<string, unknown>).calories as number | null
        : session.calories ?? null,
      batteryDelta: typeof obj.stats === "object" && obj.stats && (obj.stats as Record<string, unknown>).batteryDelta != null
        ? (obj.stats as Record<string, unknown>).batteryDelta as number | null
        : batteryDelta,
    },
    recommendations: Array.isArray(obj.recommendations)
      ? obj.recommendations.filter((r): r is string => typeof r === "string")
      : [],
    generatedAt: typeof obj.generatedAt === "string" ? obj.generatedAt : new Date().toISOString(),
  };

  return result;
}
