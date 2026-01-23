import express, { Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { z } from 'zod';
import { auditLog } from '../utils/audit';

const router = express.Router();

const contactSchema = z.object({
  subject: z.string().min(3, 'Subject must be at least 3 characters'),
  message: z.string().min(10, 'Message must be at least 10 characters'),
  category: z.enum(['technical', 'billing', 'general', 'report']).optional(),
});

// Contact support form
router.post('/contact', authenticate, validate(contactSchema), (req: AuthRequest, res: Response) => {
  try {
    const { subject, message, category = 'general' } = req.body;
    const userId = req.userId!;

    // Log support request
    auditLog({
      action: 'support.contact',
      entity: 'support',
      entityId: `req_${Date.now()}`,
      userId,
      meta: { subject, category, messageLength: message.length },
    });

    // In production, send email or create ticket
    // For now, log and return success
    console.log(`[SUPPORT REQUEST] User: ${userId}, Subject: ${subject}, Category: ${category}`);
    console.log(`Message: ${message}`);

    res.status(202).json({
      message: 'Support request submitted. We\'ll get back to you soon.',
      ticketId: `req_${Date.now()}`,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
