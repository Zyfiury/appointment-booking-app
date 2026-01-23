import express, { Request, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';
import { v4 as uuidv4 } from 'uuid';
import Stripe from 'stripe';
import { auditLog } from '../utils/audit';
import { getIdempotencyKey, getIdempotencyResult, setIdempotencyResult } from '../utils/idempotency';
import { paymentRateLimit } from '../middleware/rateLimit';

const router = express.Router();
const stripe = process.env.STRIPE_SECRET_KEY 
  ? new Stripe(process.env.STRIPE_SECRET_KEY, { apiVersion: '2023-10-16' })
  : null;

// Stripe webhook endpoint (source of truth for payment status)
router.post('/webhook', express.raw({ type: 'application/json' }), (req: Request, res: Response) => {
  try {
    const signature = req.headers['stripe-signature'];
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    if (!stripe || !webhookSecret) {
      console.warn('⚠️ Stripe not configured - webhook verification skipped');
      // In development, allow unverified webhooks
      if (process.env.NODE_ENV === 'production') {
        return res.status(400).json({ error: 'Webhook secret not configured' });
      }
    }

    let event;
    if (stripe && webhookSecret && signature) {
      try {
        event = stripe.webhooks.constructEvent(req.body, signature, webhookSecret);
      } catch (err: any) {
        console.error('⚠️ Webhook signature verification failed:', err.message);
        return res.status(400).json({ error: `Webhook signature verification failed: ${err.message}` });
      }
    } else {
      // Development fallback - parse body directly
      event = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    }

    switch (event.type) {
      case 'payment_intent.succeeded':
        handlePaymentSucceeded(event.data.object);
        break;
      case 'payment_intent.payment_failed':
        handlePaymentFailed(event.data.object);
        break;
      case 'charge.refunded':
        handleRefund(event.data.object);
        break;
      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({ received: true });
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(400).json({ error: 'Webhook processing failed' });
  }
});

function handlePaymentSucceeded(paymentIntent: any) {
  // Find payment by payment_intent_id
  const payments = db.getPayments();
  const payment = payments.find(p => p.transactionId === paymentIntent.id);
  
  if (payment) {
    // Calculate commission (15% platform, 85% provider)
    const commissionRate = 0.15;
    const platformCommission = payment.amount * commissionRate;
    const providerAmount = payment.amount - platformCommission;
    
    db.updatePayment(payment.id, {
      status: 'completed',
      transactionId: paymentIntent.id,
      platformCommission,
      providerAmount,
      commissionRate: commissionRate * 100,
    });

    // Confirm the appointment
    const appointment = db.getAppointmentById(payment.appointmentId);
    if (appointment && appointment.status === 'pending') {
      db.updateAppointment(appointment.id, { status: 'confirmed' });
    }
    auditLog({
      action: 'payment.confirmed',
      entity: 'payment',
      entityId: payment.id,
      userId: appointment?.customerId,
      meta: { paymentIntentId: paymentIntent.id, appointmentId: payment.appointmentId },
    });
  }
}

function handlePaymentFailed(paymentIntent: any) {
  const payments = db.getPayments();
  const payment = payments.find(p => p.transactionId === paymentIntent.id);
  
  if (payment) {
    db.updatePayment(payment.id, { status: 'failed' });
    const appointment = db.getAppointmentById(payment.appointmentId);
    auditLog({
      action: 'payment.failed',
      entity: 'payment',
      entityId: payment.id,
      userId: appointment?.customerId,
      meta: { paymentIntentId: paymentIntent.id },
    });
    // Release any reservation hold
    if (appointment) {
      const holds = db.getReservationHolds(appointment.providerId, appointment.date, appointment.time);
      holds.forEach(hold => {
        if (hold.customerId === appointment.customerId) {
          db.deleteReservationHold(hold.id);
        }
      });
    }
  }
}

function handleRefund(charge: any) {
  const payments = db.getPayments();
  const payment = payments.find(p => p.transactionId === charge.payment_intent);
  
  if (payment) {
    db.updatePayment(payment.id, { status: 'refunded' });
    const appointment = db.getAppointmentById(payment.appointmentId);
    auditLog({
      action: 'payment.refunded',
      entity: 'payment',
      entityId: payment.id,
      userId: appointment?.customerId,
      meta: { chargeId: charge.id },
    });
  }
}

// Create payment intent (Stripe). Idempotency-Key supported to avoid duplicate charges.
router.post('/create-intent', authenticate, paymentRateLimit, async (req: AuthRequest, res: Response) => {
  try {
    const idemKey = getIdempotencyKey(req);
    if (idemKey) {
      const cached = getIdempotencyResult(idemKey);
      if (cached) return res.status(cached.status).json(cached.body);
    }

    const { appointmentId, amount, currency = 'USD' } = req.body;

    if (!appointmentId || !amount) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const appointment = db.getAppointmentById(appointmentId);
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    if (appointment.customerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    let id: string;
    let clientSecret: string;
    let amountCents: number;
    let currencyStr: string;

    if (stripe) {
      const pi = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100),
        currency: (currency as string).toLowerCase(),
        metadata: { appointmentId },
        automatic_payment_methods: { enabled: true },
      });
      id = pi.id;
      clientSecret = pi.client_secret ?? '';
      amountCents = pi.amount;
      currencyStr = pi.currency;
    } else {
      id = `pi_mock_${uuidv4()}`;
      clientSecret = `pi_mock_${uuidv4()}_secret_${uuidv4()}`;
      amountCents = amount * 100;
      currencyStr = (currency as string).toLowerCase();
    }

    const payment = db.createPayment({
      appointmentId,
      amount,
      currency,
      status: 'pending',
      paymentMethod: 'card',
      transactionId: id,
    });

    const payload = { id, clientSecret, amount: amountCents, currency: currencyStr, paymentId: payment.id };
    if (idemKey) setIdempotencyResult(idemKey, 200, payload);
    res.json(payload);
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
    const payments = db.getPayments();
    const payment = payments.find(p => p.transactionId === paymentIntentId);
    
    if (payment) {
      db.updatePayment(payment.id, { status: 'completed' });
      res.json({ success: true, payment });
    } else {
      res.status(404).json({ error: 'Payment not found' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get user payments
router.get('/', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const payments = db.getPayments().filter(p => {
      const appointment = db.getAppointmentById(p.appointmentId);
      return appointment && (
        appointment.customerId === req.userId ||
        appointment.providerId === req.userId
      );
    });
    res.json(payments);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get payment by ID
router.get('/:id', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const payment = db.getPaymentById(req.params.id);
    if (!payment) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    const appointment = db.getAppointmentById(payment.appointmentId);
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
router.post('/:id/refund', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const payment = db.getPaymentById(req.params.id);
    if (!payment) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    if (payment.status !== 'completed') {
      return res.status(400).json({ error: 'Payment cannot be refunded' });
    }

    db.updatePayment(payment.id, { status: 'refunded' });
    res.json({ success: true, payment: db.getPaymentById(payment.id) });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
