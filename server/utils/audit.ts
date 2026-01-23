/**
 * Audit log for critical actions: payments, refunds, appointment status changes.
 * Log to console for now; later persist to DB or external service.
 */

export type AuditAction =
  | 'payment.confirmed'
  | 'payment.failed'
  | 'payment.refunded'
  | 'appointment.created'
  | 'appointment.confirmed'
  | 'appointment.cancelled'
  | 'appointment.completed'
  | 'hold.created'
  | 'hold.released'
  | 'review.removed'
  | 'image.removed'
  | 'support.contact';

export interface AuditEntry {
  action: AuditAction;
  entity: 'payment' | 'appointment' | 'hold' | 'review' | 'provider_image' | 'support';
  entityId: string;
  userId?: string;
  timestamp: string;
  meta?: Record<string, unknown>;
}

const log: AuditEntry[] = [];
const MAX_IN_MEMORY = 10_000;

export function auditLog(entry: Omit<AuditEntry, 'timestamp'>): void {
  const e: AuditEntry = { ...entry, timestamp: new Date().toISOString() };
  log.push(e);
  if (log.length > MAX_IN_MEMORY) log.shift();
  if (process.env.NODE_ENV !== 'test') {
    console.info('[audit]', JSON.stringify(e));
  }
}

export function getAuditLog(limit = 100): AuditEntry[] {
  return log.slice(-limit).reverse();
}
