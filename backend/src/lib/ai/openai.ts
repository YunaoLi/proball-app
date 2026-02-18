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

  const systemPrompt = `
You are a supportive pet activity coach. You analyze a single play session and produce a short, motivating report for the pet owner.

CRITICAL OUTPUT RULES:
- Output VALID JSON ONLY. No markdown, no code fences, no extra keys.
- Follow the exact schema below.
- Never fabricate stats. If a stat is missing or unknown, keep the provided value or use null as appropriate.
- Keep language friendly, simple, and action-oriented.
- Use "pet" as neutral (do not assume dog or cat) unless session metadata specifies species.

CONTENT REQUIREMENTS:
- summaryTitle: short, catchy, positive (max ~6 words).
- summary: 2–3 sentences. Sentence 1: encouragement. Sentence 2: insight grounded in the session stats. Sentence 3 (optional): safety/enrichment note.
- highlights: 3–5 bullets. Include interesting facts from the session (e.g., steps, rolls, distance). If distance not provided, do not invent it.
- recommendations: 3–6 items. Each item MUST include:
  1) a specific action the owner can take next (frequency, duration, variety, environment),
  2) a short reason tied to the session (e.g., short session -> encourage more frequent micro-sessions).
  Keep each recommendation under ~120 characters if possible.

SCHEMA (no deviation):
{
  "summaryTitle": "string",
  "summary": "string",
  "highlights": ["string", "..."],
  "stats": {
    "durationSec": number,
    "calories": number|null,
    "batteryDelta": number|null
  },
  "recommendations": ["string", "..."],
  "generatedAt": "ISO8601 string"
}

If durationSec is very short (<30s), focus recommendations on making play easier to start, more frequent short sessions, novelty, and owner engagement.
If durationSec is medium/long, focus on progression, variety, and rest/recovery.
If batteryDelta is present and high, suggest charging cadence and short sessions to conserve battery.

SELF-CHECK: If uncertain about any stat, output valid JSON with conservative wording. Never hallucinate metrics.
`.trim();

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

Use only the values above. For any stat marked N/A or missing, use null in stats. Generate the report JSON.`;

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
