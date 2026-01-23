/**
 * Simple in-memory report store for reviews and images.
 * Log and persist for moderation; replace with DB when scaling.
 */

export type ReportEntity = 'review' | 'provider_image';

export interface Report {
  id: string;
  entityType: ReportEntity;
  entityId: string;
  reportedBy: string;
  reason?: string;
  createdAt: string;
}

const store: Report[] = [];
const MAX = 50_000;

function nextId(): string {
  return `rpt_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
}

export function createReport(
  entityType: ReportEntity,
  entityId: string,
  reportedBy: string,
  reason?: string
): Report {
  const r: Report = {
    id: nextId(),
    entityType,
    entityId,
    reportedBy,
    reason,
    createdAt: new Date().toISOString(),
  };
  store.push(r);
  if (store.length > MAX) store.shift();
  if (process.env.NODE_ENV !== 'test') {
    console.info('[report]', JSON.stringify(r));
  }
  return r;
}

export function getReports(limit = 500): Report[] {
  return store.slice(-limit).reverse();
}
