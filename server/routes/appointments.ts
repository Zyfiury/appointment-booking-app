import express, { Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';

const router = express.Router();

function toMinutes(hhmm: string): number | null {
  const parts = hhmm.split(':');
  if (parts.length < 2) return null;
  const h = parseInt(parts[0], 10);
  const m = parseInt(parts[1], 10);
  if (Number.isNaN(h) || Number.isNaN(m)) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

function minutesToTime(mins: number): string {
  const h = Math.floor(mins / 60);
  const m = mins % 60;
  return `${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}`;
}

router.get('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const appointments = await db.getAppointments(req.userId!, req.userRole!);
    const appointmentsWithDetails = await Promise.all(appointments.map(async (apt) => {
      const customer = await db.getUserById(apt.customerId);
      const provider = await db.getUserById(apt.providerId);
      const service = await db.getServiceById(apt.serviceId);
      return {
        ...apt,
        customer: customer ? { id: customer.id, name: customer.name, email: customer.email } : null,
        provider: provider ? { id: provider.id, name: provider.name, email: provider.email } : null,
        service: service ? { id: service.id, name: service.name, duration: service.duration, price: service.price } : null,
      };
    }));
    res.json(appointmentsWithDetails);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get available slots for a provider/service/date (includes availability + breaks + current bookings + capacity)
router.get('/available-slots', async (req, res: Response) => {
  try {
    const providerId = req.query.providerId as string | undefined;
    const serviceId = req.query.serviceId as string | undefined;
    const date = req.query.date as string | undefined; // yyyy-mm-dd
    const interval = req.query.interval ? parseInt(req.query.interval as string, 10) : 30;

    if (!providerId || !serviceId || !date) {
      return res.status(400).json({ error: 'Missing required query params: providerId, serviceId, date' });
    }
    if (Number.isNaN(interval) || interval < 5 || interval > 120) {
      return res.status(400).json({ error: 'interval must be between 5 and 120 minutes' });
    }

    const service = await db.getServiceById(serviceId);
    if (!service) return res.status(404).json({ error: 'Service not found' });
    if (service.providerId !== providerId) {
      return res.status(400).json({ error: 'Service does not belong to provider' });
    }

    const dayDate = new Date(`${date}T00:00:00`);
    if (isNaN(dayDate.getTime())) {
      return res.status(400).json({ error: 'Invalid date format. Expected yyyy-mm-dd' });
    }

    const dayOfWeek = dayDate.toLocaleDateString('en-US', { weekday: 'lowercase' });
    // Prefer date-specific exceptions if present
    const exception = await db.getAvailabilityExceptionByDate(providerId, date);
    if (exception && exception.isAvailable === false) {
      return res.json([] as string[]);
    }

    const providerAvailability = await db.getAvailabilityByDay(providerId, dayOfWeek);
    if (!providerAvailability || !providerAvailability.isAvailable) {
      // No weekly schedule; but if exception exists and isAvailable=true, we still allow it
      if (!exception || exception.isAvailable !== true) {
        return res.json([] as string[]);
      }
    }

    const effectiveStart = exception?.startTime || providerAvailability?.startTime;
    const effectiveEnd = exception?.endTime || providerAvailability?.endTime;
    const effectiveBreaks = (exception && exception.isAvailable === true)
      ? (exception.breaks || [])
      : (providerAvailability?.breaks || []);

    if (!effectiveStart || !effectiveEnd) return res.json([] as string[]);

    const startMinutes = toMinutes(effectiveStart);
    const endMinutes = toMinutes(effectiveEnd);
    if (startMinutes === null || endMinutes === null || endMinutes <= startMinutes) {
      return res.json([] as string[]);
    }

    const breakRanges: Array<[number, number]> = [];
    for (const b of effectiveBreaks) {
      const [bs, be] = b.split('-');
      const bsm = bs ? toMinutes(bs) : null;
      const bem = be ? toMinutes(be) : null;
      if (bsm !== null && bem !== null && bem > bsm) {
        breakRanges.push([bsm, bem]);
      }
    }

    // Fetch existing appointments for capacity checks (same provider, same date, same service)
    const existing = await db.getAppointments(providerId, 'provider');
    const relevant = existing.filter(a => a.status !== 'cancelled' && a.serviceId === serviceId && a.date === date);

    const slots: string[] = [];
    for (let t = startMinutes; t + service.duration <= endMinutes; t += interval) {
      const slotEnd = t + service.duration;

      // Break conflict
      const conflictsBreak = breakRanges.some(([bs, be]) => t < be && slotEnd > bs);
      if (conflictsBreak) continue;

      // Capacity conflict
      const slotStartDt = new Date(`${date}T${minutesToTime(t)}`);
      const slotEndDt = new Date(slotStartDt.getTime() + service.duration * 60000);
      const concurrent = relevant.filter(a => {
        const aStart = new Date(`${a.date}T${a.time}`);
        const aEnd = new Date(aStart.getTime() + service.duration * 60000);
        return slotStartDt < aEnd && slotEndDt > aStart;
      }).length;

      if (concurrent >= (service.capacity || 1)) continue;

      slots.push(minutesToTime(t));
    }

    res.json(slots);
  } catch (error) {
    console.error('Error computing available slots:', error);
    res.status(500).json({ error: 'Failed to compute available slots' });
  }
});

router.get('/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const appointment = await db.getAppointmentById(req.params.id);
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    if (appointment.customerId !== req.userId && appointment.providerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const customer = await db.getUserById(appointment.customerId);
    const provider = await db.getUserById(appointment.providerId);
    const service = await db.getServiceById(appointment.serviceId);

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

router.post('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { providerId, serviceId, date, time, notes } = req.body;

    // Validate required fields
    if (!providerId || !serviceId || !date || !time) {
      return res.status(400).json({ error: 'Missing required fields: providerId, serviceId, date, and time are required' });
    }

    // Only customers can book appointments
    if (req.userRole !== 'customer') {
      return res.status(403).json({ error: 'Only customers can book appointments' });
    }

    // Validate date format and ensure it's in the future
    const appointmentDate = new Date(`${date}T${time}`);
    if (isNaN(appointmentDate.getTime())) {
      return res.status(400).json({ error: 'Invalid date or time format' });
    }

    const now = new Date();
    if (appointmentDate <= now) {
      return res.status(400).json({ error: 'Appointment must be scheduled for a future date and time' });
    }

    // Validate that appointment is not too far in the future (e.g., 1 year)
    const oneYearFromNow = new Date();
    oneYearFromNow.setFullYear(oneYearFromNow.getFullYear() + 1);
    if (appointmentDate > oneYearFromNow) {
      return res.status(400).json({ error: 'Appointments cannot be scheduled more than 1 year in advance' });
    }

    // Validate notes length if provided
    if (notes !== undefined && notes !== null && typeof notes === 'string' && notes.length > 1000) {
      return res.status(400).json({ error: 'Notes cannot exceed 1000 characters' });
    }

    // Get and validate service
    const service = await db.getServiceById(serviceId);
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }

    // Verify service belongs to the specified provider
    if (service.providerId !== providerId) {
      return res.status(400).json({ error: 'Service does not belong to the specified provider' });
    }

    // Verify provider exists
    const provider = await db.getUserById(providerId);
    if (!provider || provider.role !== 'provider') {
      return res.status(404).json({ error: 'Provider not found' });
    }

    // Check provider availability for the day
    const dayOfWeek = appointmentDate.toLocaleDateString('en-US', { weekday: 'lowercase' });
    const providerAvailability = await db.getAvailabilityByDay(providerId, dayOfWeek);
    
    if (!providerAvailability || !providerAvailability.isAvailable) {
      return res.status(400).json({ error: 'Provider is not available on this day' });
    }

    // Check if appointment time is within working hours
    const [apptHour, apptMin] = time.split(':').map(Number);
    const [startHour, startMin] = providerAvailability.startTime.split(':').map(Number);
    const [endHour, endMin] = providerAvailability.endTime.split(':').map(Number);
    const apptMinutes = apptHour * 60 + apptMin;
    const startMinutes = startHour * 60 + startMin;
    const endMinutes = endHour * 60 + endMin;
    const serviceEndMinutes = apptMinutes + service.duration;

    if (apptMinutes < startMinutes || serviceEndMinutes > endMinutes) {
      return res.status(400).json({ 
        error: `Appointment time must be between ${providerAvailability.startTime} and ${providerAvailability.endTime}` 
      });
    }

    // Check if appointment conflicts with breaks
    for (const breakTime of providerAvailability.breaks) {
      const [breakStart, breakEnd] = breakTime.split('-');
      const [breakStartHour, breakStartMin] = breakStart.split(':').map(Number);
      const [breakEndHour, breakEndMin] = breakEnd.split(':').map(Number);
      const breakStartMinutes = breakStartHour * 60 + breakStartMin;
      const breakEndMinutes = breakEndHour * 60 + breakEndMin;

      if ((apptMinutes >= breakStartMinutes && apptMinutes < breakEndMinutes) ||
          (serviceEndMinutes > breakStartMinutes && serviceEndMinutes <= breakEndMinutes) ||
          (apptMinutes < breakStartMinutes && serviceEndMinutes > breakEndMinutes)) {
        return res.status(400).json({ error: `This time conflicts with provider's break: ${breakTime}` });
      }
    }

    // Check service capacity - count concurrent appointments at the same time
    const existingAppointments = await db.getAppointments(providerId, 'provider');
    const appointmentDateTime = new Date(`${date}T${time}`);
    const serviceEndTime = new Date(appointmentDateTime.getTime() + service.duration * 60000);
    
    // Count appointments that overlap with this time slot (excluding cancelled)
    const concurrentAppointments = existingAppointments.filter(apt => {
      if (apt.status === 'cancelled' || apt.serviceId !== serviceId) return false;
      const aptDateTime = new Date(`${apt.date}T${apt.time}`);
      const aptService = service; // We know it's the same service
      const aptEndTime = new Date(aptDateTime.getTime() + aptService.duration * 60000);
      
      // Check if appointments overlap
      return appointmentDateTime < aptEndTime && serviceEndTime > aptDateTime;
    });

    // Check if capacity is exceeded
    if (concurrentAppointments.length >= service.capacity) {
      return res.status(400).json({ 
        error: `This time slot is full. Service capacity: ${service.capacity} concurrent appointment(s). Please choose another time.` 
      });
    }

    const appointment = await db.createAppointment({
      customerId: req.userId!,
      providerId,
      serviceId,
      date,
      time,
      status: 'pending',
      notes: notes ? notes.trim() : null,
    });

    const customer = await db.getUserById(appointment.customerId);
    const provider = await db.getUserById(appointment.providerId);

    res.status(201).json({
      ...appointment,
      customer: customer ? { id: customer.id, name: customer.name, email: customer.email } : null,
      provider: provider ? { id: provider.id, name: provider.name, email: provider.email } : null,
      service,
    });
  } catch (error) {
    console.error('Error creating appointment:', error);
    res.status(500).json({ error: 'Failed to create appointment. Please try again.' });
  }
});

router.patch('/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const appointment = await db.getAppointmentById(req.params.id);
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    // Security check: Only customer or provider can update their appointments
    if (appointment.customerId !== req.userId && appointment.providerId !== req.userId) {
      return res.status(403).json({ error: 'You can only update your own appointments' });
    }

    const { status, notes } = req.body;
    const updates: any = {};

    // Customer reschedule (only pending appointments can be rescheduled by customer)
    const newDate = req.body.date as string | undefined;
    const newTime = req.body.time as string | undefined;
    if (newDate !== undefined || newTime !== undefined) {
      if (req.userRole !== 'customer') {
        return res.status(403).json({ error: 'Only customers can reschedule' });
      }
      if (appointment.customerId !== req.userId) {
        return res.status(403).json({ error: 'You can only reschedule your own appointments' });
      }
      if (appointment.status !== 'pending') {
        return res.status(400).json({ error: 'Only pending appointments can be rescheduled' });
      }
      if (!newDate || !newTime) {
        return res.status(400).json({ error: 'Both date and time are required to reschedule' });
      }

      // Validate date/time and enforce availability + capacity using the same rules as booking
      const service = await db.getServiceById(appointment.serviceId);
      if (!service) return res.status(404).json({ error: 'Service not found' });

      const apptDate = new Date(`${newDate}T${newTime}`);
      if (isNaN(apptDate.getTime())) {
        return res.status(400).json({ error: 'Invalid date or time format' });
      }
      const now = new Date();
      if (apptDate <= now) {
        return res.status(400).json({ error: 'Appointment must be scheduled for a future date and time' });
      }

      const dayOfWeek = apptDate.toLocaleDateString('en-US', { weekday: 'lowercase' });
      const exception = await db.getAvailabilityExceptionByDate(appointment.providerId, newDate);
      if (exception && exception.isAvailable === false) {
        return res.status(400).json({ error: 'Provider is not available on this date' });
      }
      const providerAvailability = await db.getAvailabilityByDay(appointment.providerId, dayOfWeek);
      if (!providerAvailability || !providerAvailability.isAvailable) {
        if (!exception || exception.isAvailable !== true) {
          return res.status(400).json({ error: 'Provider is not available on this day' });
        }
      }

      const effectiveStart = exception?.startTime || providerAvailability?.startTime;
      const effectiveEnd = exception?.endTime || providerAvailability?.endTime;
      const effectiveBreaks = (exception && exception.isAvailable === true)
        ? (exception.breaks || [])
        : (providerAvailability?.breaks || []);
      if (!effectiveStart || !effectiveEnd) {
        return res.status(400).json({ error: 'Provider availability is not configured for this date' });
      }

      const [apptHour, apptMin] = newTime.split(':').map(Number);
      const [startHour, startMin] = effectiveStart.split(':').map(Number);
      const [endHour, endMin] = effectiveEnd.split(':').map(Number);
      const apptMinutes = apptHour * 60 + apptMin;
      const startMinutes = startHour * 60 + startMin;
      const endMinutes = endHour * 60 + endMin;
      const serviceEndMinutes = apptMinutes + service.duration;
      if (apptMinutes < startMinutes || serviceEndMinutes > endMinutes) {
        return res.status(400).json({ error: `Appointment time must be between ${effectiveStart} and ${effectiveEnd}` });
      }
      for (const breakTime of effectiveBreaks) {
        const [breakStart, breakEnd] = breakTime.split('-');
        const [bsh, bsm] = breakStart.split(':').map(Number);
        const [beh, bem] = breakEnd.split(':').map(Number);
        const bs = bsh * 60 + bsm;
        const be = beh * 60 + bem;
        if (apptMinutes < be && serviceEndMinutes > bs) {
          return res.status(400).json({ error: `This time conflicts with provider's break: ${breakTime}` });
        }
      }

      // Capacity check (exclude this appointment itself)
      const existingAppointments = await db.getAppointments(appointment.providerId, 'provider');
      const startDt = new Date(`${newDate}T${newTime}`);
      const endDt = new Date(startDt.getTime() + service.duration * 60000);
      const concurrent = existingAppointments.filter(a => {
        if (a.status === 'cancelled') return false;
        if (a.serviceId !== appointment.serviceId) return false;
        if (a.id === appointment.id) return false;
        const aStart = new Date(`${a.date}T${a.time}`);
        const aEnd = new Date(aStart.getTime() + service.duration * 60000);
        return startDt < aEnd && endDt > aStart;
      }).length;
      if (concurrent >= (service.capacity || 1)) {
        return res.status(400).json({ error: 'This slot is full. Please choose another time.' });
      }

      updates.date = newDate;
      updates.time = newTime;
    }

    // Validate status if provided
    if (status !== undefined) {
      if (!['pending', 'confirmed', 'cancelled', 'completed'].includes(status)) {
        return res.status(400).json({ error: 'Invalid status. Must be one of: pending, confirmed, cancelled, completed' });
      }
      
      // Business logic: Only providers can confirm appointments
      if (status === 'confirmed' && req.userRole !== 'provider') {
        return res.status(403).json({ error: 'Only providers can confirm appointments' });
      }
      
      // Business logic: Only providers can mark as completed
      if (status === 'completed' && req.userRole !== 'provider') {
        return res.status(403).json({ error: 'Only providers can mark appointments as completed' });
      }
      
      updates.status = status;
    }

    // Validate notes if provided
    if (notes !== undefined) {
      if (notes !== null && typeof notes === 'string' && notes.length > 1000) {
        return res.status(400).json({ error: 'Notes cannot exceed 1000 characters' });
      }
      updates.notes = notes ? notes.trim() : null;
    }

    const updated = await db.updateAppointment(req.params.id, updates);
    if (!updated) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    const customer = await db.getUserById(updated.customerId);
    const provider = await db.getUserById(updated.providerId);
    const service = await db.getServiceById(updated.serviceId);

    res.json({
      ...updated,
      customer: customer ? { id: customer.id, name: customer.name, email: customer.email } : null,
      provider: provider ? { id: provider.id, name: provider.name, email: provider.email } : null,
      service: service || null,
    });
  } catch (error) {
    console.error('Error updating appointment:', error);
    res.status(500).json({ error: 'Failed to update appointment. Please try again.' });
  }
});

router.delete('/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const appointment = await db.getAppointmentById(req.params.id);
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    if (appointment.customerId !== req.userId && appointment.providerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await db.deleteAppointment(req.params.id);
    res.json({ message: 'Appointment deleted' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
