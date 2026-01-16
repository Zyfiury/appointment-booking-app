import express, { Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';

const router = express.Router();

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

    if (!providerId || !serviceId || !date || !time) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    if (req.userRole !== 'customer') {
      return res.status(403).json({ error: 'Only customers can book appointments' });
    }

    const service = await db.getServiceById(serviceId);
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }

    if (service.providerId !== providerId) {
      return res.status(400).json({ error: 'Service does not belong to provider' });
    }

    // Check for conflicts
    const existingAppointments = await db.getAppointments(providerId, 'provider');
    const appointmentDateTime = new Date(`${date}T${time}`);
    const conflict = existingAppointments.find(apt => {
      if (apt.status === 'cancelled') return false;
      const aptDateTime = new Date(`${apt.date}T${apt.time}`);
      const serviceDuration = service.duration;
      const aptEndTime = new Date(aptDateTime.getTime() + serviceDuration * 60000);
      return appointmentDateTime < aptEndTime && new Date(appointmentDateTime.getTime() + serviceDuration * 60000) > aptDateTime;
    });

    if (conflict) {
      return res.status(400).json({ error: 'Time slot already booked' });
    }

    const appointment = await db.createAppointment({
      customerId: req.userId!,
      providerId,
      serviceId,
      date,
      time,
      status: 'pending',
      notes,
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
    res.status(500).json({ error: 'Server error' });
  }
});

router.patch('/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const appointment = await db.getAppointmentById(req.params.id);
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    if (appointment.customerId !== req.userId && appointment.providerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const { status, notes } = req.body;
    const updates: any = {};

    if (status && ['pending', 'confirmed', 'cancelled', 'completed'].includes(status)) {
      updates.status = status;
    }
    if (notes !== undefined) {
      updates.notes = notes;
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
    res.status(500).json({ error: 'Server error' });
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
