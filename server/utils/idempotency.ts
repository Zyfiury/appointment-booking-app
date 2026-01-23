/**
 * In-memory idempotency store. Use Idempotency-Key header on POST /appointments
 * and POST /payments/create-intent to avoid duplicate bookings/payments on
 * double-tap or network retries.
 * TTL 24h. Replace with Redis/DB for multi-instance or persistence.
 */

const store = new Map<string, { status: number; body: unknown; expiresAt: number }>();
const TTL_MS = 24 * 60 * 60 * 1000;

export function getIdempotencyResult(key: string): { status: number; body: unknown } | null {
  const entry = store.get(key);
  if (!entry || entry.expiresAt < Date.now()) {
    if (entry) store.delete(key);
    return null;
  }
  return { status: entry.status, body: entry.body };
}

export function setIdempotencyResult(key: string, status: number, body: unknown): void {
  store.set(key, {
    status,
    body,
    expiresAt: Date.now() + TTL_MS,
  });
}

export function getIdempotencyKey(req: { headers: Record<string, string | string[] | undefined> }): string | null {
  const v = req.headers['idempotency-key'];
  if (typeof v === 'string' && /^[a-zA-Z0-9_-]{1,128}$/.test(v)) return v;
  return null;
}
