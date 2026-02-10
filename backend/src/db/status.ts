/**
 * Prints applied migrations from schema_migrations.
 * Run: pnpm db:status (or npm run db:status)
 */
import "dotenv/config";
import { query } from "../lib/db";
import { logger } from "../lib/logger";

async function main(): Promise<void> {
  if (!process.env.DATABASE_URL) {
    logger.error("DATABASE_URL is not set");
    process.exit(1);
  }
  try {
    const result = await query<{ name: string; applied_at: string }>(
      "SELECT name, applied_at FROM schema_migrations ORDER BY name"
    );
    if (result.rows.length === 0) {
      logger.info("No migrations applied yet.");
      return;
    }
    for (const row of result.rows) {
      logger.info(row.applied_at + "  " + row.name);
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg.includes("schema_migrations") || msg.includes("does not exist")) {
      logger.info("No migrations applied yet (run db:migrate first).");
      return;
    }
    logger.error("db:status failed: " + msg);
    process.exit(1);
  }
}

main();
