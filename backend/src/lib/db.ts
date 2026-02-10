import { Pool, PoolClient, QueryResult, QueryResultRow } from "pg";

let connectionString = process.env.DATABASE_URL ?? undefined;

// Neon requires SSL. Use verify-full to match current secure behavior and silence pg warning
// (pg v9 will change sslmode=require semantics; see https://www.postgresql.org/docs/current/libpq-ssl.html)
if (connectionString?.includes("sslmode=require")) {
  connectionString = connectionString.replace("sslmode=require", "sslmode=verify-full");
}
if (connectionString?.includes("ssl=true") && !connectionString.includes("sslmode=")) {
  connectionString = connectionString.replace("ssl=true", "sslmode=verify-full");
}

const ssl =
  connectionString?.includes("sslmode=verify-full") || connectionString?.includes("sslmode=require")
    ? { rejectUnauthorized: true }
    : undefined;

const pool = connectionString ? new Pool({ connectionString, ssl }) : null;

export type QueryParams = unknown[];

/**
 * Run a parameterized query. Uses the shared pool (DATABASE_URL).
 */
export async function query<R extends QueryResultRow = QueryResultRow>(
  sql: string,
  params?: QueryParams
): Promise<QueryResult<R>> {
  if (!pool) throw new Error("DATABASE_URL is not set");
  return pool.query<R>(sql, params);
}

/**
 * Run a function inside a transaction. The client is committed on return
 * or rolled back on throw. Async-safe: no unbounded loops.
 */
export async function withTransaction<T>(
  fn: (client: PoolClient) => Promise<T>
): Promise<T> {
  if (!pool) throw new Error("DATABASE_URL is not set");
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const result = await fn(client);
    await client.query("COMMIT");
    return result;
  } catch (e) {
    await client.query("ROLLBACK").catch(() => {});
    throw e;
  } finally {
    client.release();
  }
}
