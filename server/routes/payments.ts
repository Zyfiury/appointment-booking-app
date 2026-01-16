import express, { Request, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';
import { v4 as uuidv4 } from 'uuid';

const router = express.Router();

// Create payment intent (Stripe)
router.post('/create-intent', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { appointmentId, amount, currency = 'USD' } = req.body;

    if (!appointmentId || !amount) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const appointment = await db.getAppointmentById(appointmentId);
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    // In production, integrate with Stripe API here
    // For now, return a mock payment intent
    const paymentIntent = {
      id: `pi_${uuidv4()}`,
      clientSecret: `pi_${uuidv4()}_secret_${uuidv4()}`,
      amount: amount * 100, // Convert to cents
      currency: currency.toLowerCase(),
    };

    // Create payment record
    const payment = await db.createPayment({
      appointmentId,
      amount,
      currency,
      status: 'pending',
      paymentMethod: 'card',
    });

    res.json({
      ...paymentIntent,
      paymentId: payment.id,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Confirm payment
router.post('/confirm', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { paymentIntentId, paymentMethodId } = req.body;

    if (!paymentIntentId) {
      return res.status(400).json({ error: 'Missing payment intent ID' });
    }

    // In production, confirm with Stripe API
    // For now, update payment status
    const payments = await db.getPayments();
    const payment = payments.find(p => p.transactionId === paymentIntentId);
    
    if (payment) {
      await db.updatePayment(payment.id, { status: 'completed' });
      res.json({ success: true, payment });
    } else {
      res.status(404).json({ error: 'Payment not found' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get user payments
router.get('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const allPayments = await db.getPayments();
    const payments = await Promise.all(
      allPayments.map(async (p) => {
        const appointment = await db.getAppointmentById(p.appointmentId);
        return { payment: p, appointment };
      })
    );
    const filteredPayments = payments
      .filter(({ appointment }) => appointment && (
        appointment.customerId === req.userId ||
        appointment.providerId === req.userId
      ))
      .map(({ payment }) => payment);
    res.json(filteredPayments);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get payment by ID
router.get('/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const payment = await db.getPaymentById(req.params.id);
    if (!payment) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    const appointment = await db.getAppointmentById(payment.appointmentId);
    if (!appointment || 
        (appointment.customerId !== req.userId && 
         appointment.providerId !== req.userId)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    res.json(payment);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Refund payment
router.post('/:id/refund', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const payment = await db.getPaymentById(req.params.id);
    if (!payment) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    if (payment.status !== 'completed') {
      return res.status(400).json({ error: 'Payment cannot be refunded' });
    }

    await db.updatePayment(payment.id, { status: 'refunded' });
    const updatedPayment = await db.getPaymentById(payment.id);
    res.json({ success: true, payment: updatedPayment });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
