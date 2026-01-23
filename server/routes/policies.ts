import express, { Response } from 'express';
import { PLATFORM_DEFAULT_POLICY } from '../utils/cancellation';

const router = express.Router();

/**
 * GET /policies/cancellation
 * Returns platform cancellation & refund policy for in-app display.
 */
router.get('/cancellation', (_req, res: Response) => {
  const p = PLATFORM_DEFAULT_POLICY;
  res.json({
    platformDefault: p,
    summary: `Free cancellation up to ${p.freeCancelHours} hours before your appointment. Late cancellations may incur a ${p.lateCancelFee}% fee; no-shows ${p.noShowFee}%. Refunds follow the same rules. Providers may set stricter policies.`,
  });
});

/**
 * GET /policies/terms
 * Placeholder – link to full Terms of Service URL when published.
 */
router.get('/terms', (_req, res: Response) => {
  res.json({
    url: process.env.TERMS_URL || null,
    message: 'Terms of Service. Link to be added when published.',
  });
});

/**
 * GET /policies/privacy
 * Placeholder – link to full Privacy Policy URL when published.
 */
router.get('/privacy', (_req, res: Response) => {
  res.json({
    url: process.env.PRIVACY_URL || null,
    message: 'Privacy Policy. Link to be added when published.',
  });
});

export default router;
