import { timeZonesNames } from "@vvo/tzdb";

/** Valid IANA timezone names (whitelist). Includes UTC and Etc/UTC. */
const VALID_ZONES = new Set([
  "UTC",
  "Etc/UTC",
  ...timeZonesNames,
]);

/**
 * Validates that the input is a known IANA timezone string.
 * @param tz - Timezone string (e.g. "America/Chicago")
 * @returns true if valid
 */
export function isValidTimezone(tz: unknown): tz is string {
  if (typeof tz !== "string" || tz.trim() === "") return false;
  return VALID_ZONES.has(tz.trim());
}
