/**
 * Simple console logger wrapper. Use for auth and API logging.
 * Never log tokens or raw Authorization headers.
 */

export const logger = {
  info(message: string, ...args: unknown[]): void {
    console.log(`[info] ${message}`, ...args);
  },

  warn(message: string, ...args: unknown[]): void {
    console.warn(`[warn] ${message}`, ...args);
  },

  error(message: string, ...args: unknown[]): void {
    console.error(`[error] ${message}`, ...args);
  },
};
