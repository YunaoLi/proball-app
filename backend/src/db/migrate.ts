/**
 * Migration runner: applies SQL files from src/db/migrations/*.sql in order.
 * Uses DATABASE_URL and the pg client from src/lib/db.
 * Tracks applied migrations in schema_migrations; no secrets logged.
 * For local runs, ensure .env exists or set DATABASE_URL (dotenv loads .env from cwd).
 */
import "dotenv/config";
import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { query, withTransaction } from "../lib/db";
import { logger } from "../lib/logger";

const MIGRATIONS_DIR = path.join(process.cwd(), "src", "db", "migrations");

const SCHEMA_MIGRATIONS_TABLE = `
CREATE TABLE IF NOT EXISTS schema_migrations (
  name TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ DEFAULT now()
);
`;

async function ensureMigrationsTable(): Promise<void> {
  await query(SCHEMA_MIGRATIONS_TABLE);
  logger.info("Schema migrations table ready");
}

async function getAppliedMigrations(): Promise<string[]> {
  const result = await query<{ name: string }>(
    "SELECT name FROM schema_migrations ORDER BY name"
  );
  return result.rows.map((r) => r.name);
}

async function getMigrationFiles(): Promise<string[]> {
  const entries = await readdir(MIGRATIONS_DIR, { withFileTypes: true });
  const files = entries
    .filter((e) => e.isFile() && e.name.endsWith(".sql"))
    .map((e) => e.name)
    .sort();
  return files;
}

async function applyMigration(name: string, sql: string): Promise<void> {
  await withTransaction(async (client) => {
    await client.query(sql);
    await client.query(
      "INSERT INTO schema_migrations (name) VALUES ($1)",
      [name]
    );
  });
}

export async function runMigrations(): Promise<void> {
  if (!process.env.DATABASE_URL) {
    throw new Error("DATABASE_URL is not set");
  }
  logger.info("Running migrations");
  await ensureMigrationsTable();
  const applied = new Set(await getAppliedMigrations());
  const files = await getMigrationFiles();
  for (const file of files) {
    const name = file;
    if (applied.has(name)) {
      logger.info("Skip (already applied): " + name);
      continue;
    }
    const filePath = path.join(MIGRATIONS_DIR, file);
    const sql = await readFile(filePath, "utf-8");
    try {
      await applyMigration(name, sql);
      logger.info("Applied: " + name);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error("Migration failed: " + name + " - " + msg);
      throw e;
    }
  }
  logger.info("Migrations finished");
}

runMigrations().catch((e) => {
  logger.error("Migration runner failed", e instanceof Error ? e.message : String(e));
  process.exit(1);
});
