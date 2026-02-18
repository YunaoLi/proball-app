import { randomBytes, randomUUID } from "crypto";
import { getPool, withTransaction } from "./db";

/** Generate a cryptographically strong base64url token (32 bytes). */
function generateToken(): string {
  return randomBytes(32).toString("base64url");
}

/**
 * Create verification token for email. Inserts into verification table.
 * identifier=email, value=token, expiresAt=now+24h.
 */
export async function createEmailVerificationToken(
  email: string
): Promise<{ token: string; expiresAt: Date }> {
  const token = generateToken();
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

  const pool = getPool();
  await pool.query(
    `INSERT INTO verification (id, identifier, value, "expiresAt", "createdAt", "updatedAt")
     VALUES ($1, $2, $3, $4, now(), now())`,
    [randomUUID(), email.toLowerCase().trim(), token, expiresAt]
  );

  return { token, expiresAt };
}

/**
 * Consume verification token. If valid: delete row and return true.
 * Else return false.
 */
export async function consumeEmailVerificationToken(
  email: string,
  token: string
): Promise<boolean> {
  const normalizedEmail = email.toLowerCase().trim();
  const trimmedToken = token.trim();
  if (!normalizedEmail || !trimmedToken) return false;

  const result = await withTransaction(async (client) => {
    const res = await client.query<{ id: string }>(
      `SELECT id FROM verification
       WHERE identifier = $1 AND value = $2 AND "expiresAt" > now()
       FOR UPDATE`,
      [normalizedEmail, trimmedToken]
    );
    if (res.rows.length === 0) return false;
    await client.query(`DELETE FROM verification WHERE id = $1`, [res.rows[0].id]);
    return true;
  });

  return result;
}

/**
 * Mark user as verified. UPDATE "user" SET "emailVerified"=true WHERE email=$1.
 */
export async function markUserVerified(email: string): Promise<void> {
  const pool = getPool();
  await pool.query(
    `UPDATE "user" SET "emailVerified" = true, "updatedAt" = now() WHERE email = $1`,
    [email.toLowerCase().trim()]
  );
}
