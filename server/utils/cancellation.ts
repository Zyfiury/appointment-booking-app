import { Appointment, Service, User, CancellationPolicy, Payment } from '../data/database';

export interface CancellationResult {
  cancellationFee: number;
  refundAmount: number;
  canCancelFree: boolean;
  reason: string;
}

export function calculateCancellationFee(
  appointment: Appointment,
  service: Service | null,
  provider: User | null,
  payment: Payment | null
): CancellationResult {
  const policy: CancellationPolicy | undefined = 
    service?.cancellationPolicy || provider?.cancellationPolicy;

  if (!policy) {
    // No policy = free cancellation
    return {
      cancellationFee: 0,
      refundAmount: payment?.amount || 0,
      canCancelFree: true,
      reason: 'No cancellation policy',
    };
  }

  const appointmentDateTime = new Date(`${appointment.date}T${appointment.time}`);
  const now = new Date();
  const hoursUntilAppointment = (appointmentDateTime.getTime() - now.getTime()) / (1000 * 60 * 60);

  // Check if within free cancellation window
  if (hoursUntilAppointment >= policy.freeCancelHours) {
    return {
      cancellationFee: 0,
      refundAmount: payment?.amount || 0,
      canCancelFree: true,
      reason: `Free cancellation (${Math.round(hoursUntilAppointment)} hours before appointment)`,
    };
  }

  // Late cancellation
  const servicePrice = service?.price || 0;
  let cancellationFee = 0;

  if (hoursUntilAppointment < 0) {
    // No-show (appointment time has passed)
    if (policy.noShowFee) {
      cancellationFee = servicePrice * (policy.noShowFee / 100);
    }
  } else {
    // Late cancellation (within free window)
    if (policy.lateCancelFee) {
      cancellationFee = servicePrice * (policy.lateCancelFee / 100);
    }
  }

  const refundAmount = Math.max(0, (payment?.amount || 0) - cancellationFee);

  return {
    cancellationFee,
    refundAmount,
    canCancelFree: false,
    reason: hoursUntilAppointment < 0 
      ? `No-show fee: ${policy.noShowFee || 0}%`
      : `Late cancellation fee: ${policy.lateCancelFee || 0}% (${Math.round(hoursUntilAppointment)} hours before)`,
  };
}
