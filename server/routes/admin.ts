import express, { Response, NextFunction } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';
import { auditLog } from '../utils/audit';

const router = express.Router();

// Simple admin check (in production, use role-based auth with 'admin' role)
const isAdmin = (req: AuthRequest): boolean => {
  // For now, check if user email is admin (configure via env)
  const adminEmail = process.env.ADMIN_EMAIL || '';
  const user = db.getUserById(req.userId!);
  return user?.email === adminEmail || process.env.NODE_ENV !== 'production';
};

// Admin middleware
const requireAdmin = (req: express.Request, res: Response, next: NextFunction) => {
  const authReq = req as AuthRequest;
  if (!isAdmin(authReq)) {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

// Get all users (admin only)
router.get('/users', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const users = db.getUsers().map(u => ({
      id: u.id,
      email: u.email,
      name: u.name,
      role: u.role,
      createdAt: u.createdAt,
    }));
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get all providers (admin only)
router.get('/providers', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const providers = db.getUsers().filter(u => u.role === 'provider');
    res.json(providers);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get all appointments (admin only)
router.get('/appointments', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const appointments = db.getAppointments();
    const withDetails = appointments.map(apt => {
      const customer = db.getUserById(apt.customerId);
      const provider = db.getUserById(apt.providerId);
      const service = db.getServiceById(apt.serviceId);
      return {
        ...apt,
        customer: customer ? { id: customer.id, name: customer.name, email: customer.email } : null,
        provider: provider ? { id: provider.id, name: provider.name, email: provider.email } : null,
        service: service || null,
      };
    });
    res.json(withDetails);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get all payments (admin only)
router.get('/payments', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const payments = db.getPayments();
    const withDetails = payments.map(payment => {
      const appointment = db.getAppointmentById(payment.appointmentId);
      return {
        ...payment,
        appointment: appointment || null,
      };
    });
    res.json(withDetails);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Issue refund (admin only)
router.post('/payments/:id/refund', authenticate, requireAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const payment = db.getPaymentById(req.params.id);
    if (!payment) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    if (payment.status !== 'completed') {
      return res.status(400).json({ error: 'Only completed payments can be refunded' });
    }

    // Update payment status
    db.updatePayment(payment.id, { status: 'refunded' });

    auditLog({
      action: 'payment.refunded',
      entity: 'payment',
      entityId: payment.id,
      userId: req.userId!,
      meta: { adminRefund: true, amount: payment.amount },
    });

    res.json({ success: true, payment: db.getPaymentById(payment.id) });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Remove review (admin only)
router.delete('/reviews/:id', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const review = db.getReviewById(req.params.id);
    if (!review) {
      return res.status(404).json({ error: 'Review not found' });
    }

    db.deleteReview(req.params.id);
    db.updateProviderRating(review.providerId);

    auditLog({
      action: 'review.removed',
      entity: 'review',
      entityId: review.id,
      userId: req.userId!,
      meta: { adminAction: true, providerId: review.providerId },
    });

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Remove provider image (admin only)
router.delete('/provider-images/:id', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const image = db.getProviderImageById(req.params.id);
    if (!image) {
      return res.status(404).json({ error: 'Image not found' });
    }

    db.deleteProviderImage(req.params.id);

    auditLog({
      action: 'image.removed',
      entity: 'provider_image',
      entityId: image.id,
      userId: req.userId!,
      meta: { adminAction: true, providerId: image.providerId },
    });

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get audit logs (admin only)
router.get('/audit-logs', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const { getAuditLog } = require('../utils/audit');
    const limit = parseInt((req.query.limit as string) || '100');
    const logs = getAuditLog(limit);
    res.json(logs);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get reports (admin only)
router.get('/reports', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const { getReports } = require('../utils/reports');
    const limit = parseInt((req.query.limit as string) || '500');
    const reports = getReports(limit);
    res.json(reports);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
