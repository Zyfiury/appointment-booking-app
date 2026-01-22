import express, { Request, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';
import { validate, schemas } from '../middleware/validation';
import { paginate, parsePagination } from '../utils/pagination';
import { calculateCancellationFee } from '../utils/cancellation';

const router = express.Router();

router.get('/', authenticate, (req: AuthRequest, res: Response) => {
  try {
    // CRITICAL: Ensure proper data isolation - filter by user role
    if (!req.userId || !req.userRole) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    const appointments = db.getAppointments(req.userId, req.userRole);
    
    // Additional safety check: Verify appointments belong to the user
    const filteredAppointments = appointments.filter(apt => {
      if (req.userRole === 'customer') {
        return apt.customerId === req.userId;
      } else if (req.userRole === 'provider') {
        return apt.providerId === req.userId;
      }
      return false;
    });

    // Map appointments with details first
    const appointmentsWithDetails = filteredAppointments.map(apt => {
      const customer = db.getUserById(apt.customerId);
      const provider = db.getUserById(apt.providerId);
      const service = db.getServiceById(apt.serviceId);
      return {
        ...apt,
        customer: customer ? { id: customer.id, name: customer.name, email: customer.email } : null,
        provider: provider ? { id: provider.id, name: provider.name, email: provider.email } : null,
        service: service ? { id: service.id, name: service.name, duration: service.duration, price: service.price } : null,
      };
    });

    // Check if pagination is requested (backward compatible)
    const hasPagination = req.query.page || req.query.limit;
    if (hasPagination) {
      const pagination = parsePagination(req.query);
      const paginated = paginate(appointmentsWithDetails, pagination);
      res.json({
        data: paginated.data,
        pagination: paginated.pagination,
      });
    } else {
      // Return plain list for backward compatibility
      res.json(appointmentsWithDetails);
    }
  } catch (error) {
    console.error('Get appointments error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get available time slots for booking (must be before /:id route)
router.get('/available-slots', async (req: express.Request, res: Response) => {
  try {
    const { providerId, serviceId, date, interval = '30' } = req.query as {
      providerId?: string;
      serviceId?: string;
      date?: string;
      interval?: string;
    };

    if (!providerId || !serviceId || !date) {
      return res.status(400).json({ error: 'Missing required fields: providerId, serviceId, date' });
    }

    const service = db.getServiceById(serviceId as string);
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }

    // Get provider availability
    const availability = db.getAvailability(providerId as string);
    const dateObj = new Date(date as string);
    const dayOfWeek = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'][dateObj.getDay()];
    
    const dayAvailability = availability.find(a => a.dayOfWeek === dayOfWeek && a.isAvailable);
    if (!dayAvailability) {
      return res.json([]); // No availability for this day
    }

    // Check for exceptions
    const exceptions = db.getAvailabilityExceptions(providerId as string);
    const dateStr = date as string;
    const exception = exceptions.find(e => e.date === dateStr);
    
    if (exception && !exception.isAvailable) {
      return res.json([]); // Day is blocked
    }

    // Use exception times if available, otherwise use regular availability
    const startTime = exception?.startTime || dayAvailability.startTime;
    const endTime = exception?.endTime || dayAvailability.endTime;
    const breaks = exception?.breaks || dayAvailability.breaks || [];

    // Parse times
    const [startHour, startMin] = startTime.split(':').map(Number);
    const [endHour, endMin] = endTime.split(':').map(Number);
    const startMinutes = startHour * 60 + startMin;
    const endMinutes = endHour * 60 + endMin;
    const slotInterval = parseInt(interval as string) || 30;
    const serviceDuration = service.duration || 30;

    // Get existing appointments for this date
    const existingAppointments = db.getAppointments(providerId as string, 'provider')
      .filter(apt => apt.date === dateStr && apt.status !== 'cancelled');

    // Generate available slots
    const availableSlots: string[] = [];
    let currentMinutes = startMinutes;

    while (currentMinutes + serviceDuration <= endMinutes) {
      const slotEnd = currentMinutes + serviceDuration;
      const slotTime = `${Math.floor(currentMinutes / 60).toString().padStart(2, '0')}:${(currentMinutes % 60).toString().padStart(2, '0')}`;

      // Check if slot conflicts with break
      let conflictsWithBreak = false;
      for (const breakTime of breaks) {
        const [breakStart, breakEnd] = breakTime.split('-');
        const [bsh, bsm] = breakStart.split(':').map(Number);
        const [beh, bem] = breakEnd.split(':').map(Number);
        const breakStartMinutes = bsh * 60 + bsm;
        const breakEndMinutes = beh * 60 + bem;

        if (currentMinutes < breakEndMinutes && slotEnd > breakStartMinutes) {
          conflictsWithBreak = true;
          break;
        }
      }

      // Check if slot conflicts with existing appointment
      let conflictsWithAppointment = false;
      for (const apt of existingAppointments) {
        const [aptHour, aptMin] = apt.time.split(':').map(Number);
        const aptStartMinutes = aptHour * 60 + aptMin;
        const aptService = db.getServiceById(apt.serviceId);
        const aptDuration = aptService?.duration || 30;
        const aptEndMinutes = aptStartMinutes + aptDuration;

        if (currentMinutes < aptEndMinutes && slotEnd > aptStartMinutes) {
          conflictsWithAppointment = true;
          break;
        }
      }

      // Check capacity
      let atCapacity = false;
      const serviceCapacity = service.capacity || 1;
      if (serviceCapacity > 1) {
        const concurrentAppointments = existingAppointments.filter(apt => {
          const [aptHour, aptMin] = apt.time.split(':').map(Number);
          const aptStartMinutes = aptHour * 60 + aptMin;
          const aptService = db.getServiceById(apt.serviceId);
          const aptDuration = aptService?.duration || 30;
          const aptEndMinutes = aptStartMinutes + aptDuration;
          return currentMinutes < aptEndMinutes && slotEnd > aptStartMinutes;
        });
        atCapacity = concurrentAppointments.length >= serviceCapacity;
      }

      if (!conflictsWithBreak && !conflictsWithAppointment && !atCapacity) {
        availableSlots.push(slotTime);
      }

      currentMinutes += slotInterval;
    }

    res.json(availableSlots);
  } catch (error) {
    console.error('Error computing available slots:', error);
    res.status(500).json({ error: 'Failed to compute available slots' });
  }
});

router.get('/:id', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const appointment = db.getAppointmentById(req.params.id);
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    if (appointment.customerId !== req.userId && appointment.providerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const customer = db.getUserById(appointment.customerId);
    const provider = db.getUserById(appointment.providerId);
    const service = db.getServiceById(appointment.serviceId);

    res.json({
      ...appointment,
      customer: customer ? { id: customer.id, name: customer.name, email: customer.email, phone: customer.phone } : null,
      provider: provider ? { id: provider.id, name: provider.name, email: provider.email, phone: provider.phone } : null,
      service: service || null,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Create reservation hold (before payment)
router.post('/hold', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const { providerId, serviceId, date, time } = req.body;

    if (!providerId || !serviceId || !date || !time) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    if (req.userRole !== 'customer') {
      return res.status(403).json({ error: 'Only customers can create holds' });
    }

    const service = db.getServiceById(serviceId);
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }

    // Check for active holds (excluding expired ones)
    const activeHolds = db.getReservationHolds(providerId, date, time);
    if (activeHolds.length > 0) {
      return res.status(409).json({ error: 'Time slot is currently being reserved' });
    }

    // Check for existing appointments
    const existingAppointments = db.getAppointments(providerId, 'provider');
    const appointmentDateTime = new Date(`${date}T${time}`);
    const conflict = existingAppointments.find(apt => {
      if (apt.status === 'cancelled') return false;
      const aptDateTime = new Date(`${apt.date}T${apt.time}`);
      const serviceDuration = service.duration || 60;
      const aptEndTime = new Date(aptDateTime.getTime() + serviceDuration * 60000);
      return appointmentDateTime < aptEndTime && new Date(appointmentDateTime.getTime() + serviceDuration * 60000) > aptDateTime;
    });

    if (conflict) {
      return res.status(400).json({ error: 'Time slot already booked' });
    }

    // Check capacity
    const serviceCapacity = service.capacity || 1;
    const concurrentAppointments = existingAppointments.filter(apt => {
      if (apt.status === 'cancelled') return false;
      const aptDateTime = new Date(`${apt.date}T${apt.time}`);
      const serviceDuration = service.duration || 60;
      const aptEndTime = new Date(aptDateTime.getTime() + serviceDuration * 60000);
      return appointmentDateTime < aptEndTime && new Date(appointmentDateTime.getTime() + serviceDuration * 60000) > aptDateTime;
    });

    if (concurrentAppointments.length >= serviceCapacity) {
      return res.status(400).json({ error: 'Service capacity reached for this time slot' });
    }

    // Create hold (expires in 10 minutes)
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();
    const hold = db.createReservationHold({
      providerId,
      serviceId,
      date,
      time,
      customerId: req.userId!,
      expiresAt,
    });

    res.status(201).json(hold);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Release reservation hold
router.delete('/hold/:id', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const holdId = req.params.id;
    // In production, verify the hold belongs to the user
    const deleted = db.deleteReservationHold(holdId);
    if (!deleted) {
      return res.status(404).json({ error: 'Hold not found' });
    }
    res.json({ message: 'Hold released' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/', authenticate, validate(schemas.createAppointment), (req: AuthRequest, res: Response) => {
  try {
    const { providerId, serviceId, date, time, notes, holdId } = req.body;

    if (req.userRole !== 'customer') {
      return res.status(403).json({ error: 'Only customers can book appointments' });
    }

    const service = db.getServiceById(serviceId);
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }

    // CRITICAL: Double-check service ownership - prevent cross-provider booking
    if (service.providerId !== providerId) {
      return res.status(400).json({ 
        error: 'Service does not belong to the selected provider. Please select a valid service.' 
      });
    }

    // Additional safety: Verify service is active
    if (service.isActive === false) {
      return res.status(400).json({ error: 'This service is currently unavailable' });
    }

    // If holdId provided, verify and release it
    if (holdId) {
      const activeHolds = db.getReservationHolds(providerId, date, time);
      const hold = activeHolds.find(h => h.id === holdId && h.customerId === req.userId);
      if (!hold) {
        return res.status(400).json({ error: 'Invalid or expired reservation hold' });
      }
      // Release the hold
      db.deleteReservationHold(holdId);
    } else {
      // Check for active holds
      const activeHolds = db.getReservationHolds(providerId, date, time);
      if (activeHolds.length > 0) {
        return res.status(409).json({ error: 'Time slot is currently being reserved' });
      }
    }

    // Check for conflicts
    const existingAppointments = db.getAppointments(providerId, 'provider');
    const appointmentDateTime = new Date(`${date}T${time}`);
    const conflict = existingAppointments.find(apt => {
      if (apt.status === 'cancelled') return false;
      const aptDateTime = new Date(`${apt.date}T${apt.time}`);
      const serviceDuration = service.duration || 60;
      const aptEndTime = new Date(aptDateTime.getTime() + serviceDuration * 60000);
      return appointmentDateTime < aptEndTime && new Date(appointmentDateTime.getTime() + serviceDuration * 60000) > aptDateTime;
    });

    if (conflict) {
      return res.status(400).json({ error: 'Time slot already booked' });
    }

    // Check capacity
    const serviceCapacity = service.capacity || 1;
    const concurrentAppointments = existingAppointments.filter(apt => {
      if (apt.status === 'cancelled') return false;
      const aptDateTime = new Date(`${apt.date}T${apt.time}`);
      const serviceDuration = service.duration || 60;
      const aptEndTime = new Date(aptDateTime.getTime() + serviceDuration * 60000);
      return appointmentDateTime < aptEndTime && new Date(appointmentDateTime.getTime() + serviceDuration * 60000) > aptDateTime;
    });

    if (concurrentAppointments.length >= serviceCapacity) {
      return res.status(400).json({ error: 'Service capacity reached for this time slot' });
    }

    const appointment = db.createAppointment({
      customerId: req.userId!,
      providerId,
      serviceId,
      date,
      time,
      status: 'pending',
      notes,
    });

    const customer = db.getUserById(appointment.customerId);
    const provider = db.getUserById(appointment.providerId);

    res.status(201).json({
      ...appointment,
      customer: customer ? { id: customer.id, name: customer.name, email: customer.email } : null,
      provider: provider ? { id: provider.id, name: provider.name, email: provider.email } : null,
      service,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.patch('/:id', authenticate, validate(schemas.updateAppointment), (req: AuthRequest, res: Response) => {
  try {
    const appointment = db.getAppointmentById(req.params.id);
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    if (appointment.customerId !== req.userId && appointment.providerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const { status, notes } = req.body;

    // If cancelling, calculate cancellation fee
    if (status === 'cancelled' && appointment.status !== 'cancelled') {
      const service = db.getServiceById(appointment.serviceId);
      const provider = db.getUserById(appointment.providerId);
      const payments = db.getPayments();
      const payment = payments.find(p => p.appointmentId === appointment.id && p.status === 'completed');
      
      const cancellation = calculateCancellationFee(appointment, service || null, provider || null, payment || null);
      
      // Update payment if there's a cancellation fee
      if (payment && cancellation.cancellationFee > 0) {
        db.updatePayment(payment.id, {
          status: 'refunded',
        });
      }
    }
    const updates: any = {};

    if (status && ['pending', 'confirmed', 'cancelled', 'completed'].includes(status)) {
      updates.status = status;
    }
    if (notes !== undefined) {
      updates.notes = notes;
    }

    const updated = db.updateAppointment(req.params.id, updates);
    if (!updated) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    const customer = db.getUserById(updated.customerId);
    const provider = db.getUserById(updated.providerId);
    const service = db.getServiceById(updated.serviceId);

    res.json({
      ...updated,
      customer: customer ? { id: customer.id, name: customer.name, email: customer.email } : null,
      provider: provider ? { id: provider.id, name: provider.name, email: provider.email } : null,
      service: service || null,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.delete('/:id', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const appointment = db.getAppointmentById(req.params.id);
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    if (appointment.customerId !== req.userId && appointment.providerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Calculate cancellation fee using utility function
    const service = db.getServiceById(appointment.serviceId);
    const provider = db.getUserById(appointment.providerId);
    const payments = db.getPayments();
    const payment = payments.find(p => p.appointmentId === appointment.id && p.status === 'completed');
    
    const cancellation = calculateCancellationFee(
      appointment,
      service || null,
      provider || null,
      payment || null
    );

    // Update payment if there's a cancellation fee
    if (payment && cancellation.cancellationFee > 0) {
      db.updatePayment(payment.id, {
        status: 'refunded',
      });
    }

    db.updateAppointment(req.params.id, { status: 'cancelled' });
    
    res.json({ 
      message: 'Appointment cancelled',
      cancellationFee: cancellation.cancellationFee,
      refundAmount: cancellation.refundAmount,
      canCancelFree: cancellation.canCancelFree,
      reason: cancellation.reason,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
