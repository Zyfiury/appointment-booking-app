import { db } from '../data/database';

/**
 * Provider is ready for search/discovery only when:
 * - Location set (address or lat/lng)
 * - At least 1 active service
 * - At least 1 availability rule
 */
export function isOnboardingComplete(providerId: string): boolean {
  const user = db.getUserById(providerId);
  if (!user || user.role !== 'provider') return false;

  const hasLocation = Boolean(
    (user.latitude != null && user.longitude != null) || (user.address && user.address.trim().length > 0)
  );
  const services = db.getServices(providerId).filter(s => s.isActive !== false);
  const availability = db.getAvailability(providerId).filter(a => a.isAvailable);

  return hasLocation && services.length >= 1 && availability.length >= 1;
}
