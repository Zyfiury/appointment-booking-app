import express, { Request, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';
import {
  createConnectAccount,
  getAccountStatus,
  createLoginLink,
} from '../services/stripe_service';

const router = express.Router();

/**
 * Create Stripe Connect account for provider
 * POST /api/stripe/connect/create
 */
router.post('/connect/create', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can connect Stripe accounts' });
    }

    const user = db.getUserById(req.userId!);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if already connected (stripeAccountId not in current User type)
    const userWithStripe = user as any;
    if (userWithStripe.stripeAccountId) {
      const status = await getAccountStatus(userWithStripe.stripeAccountId);
      if (status.chargesEnabled && status.payoutsEnabled) {
        return res.status(400).json({ 
          error: 'Stripe account already connected',
          accountId: userWithStripe.stripeAccountId,
        });
      }
    }

    // Create new Stripe Connect account
    const { accountId, onboardingUrl } = await createConnectAccount(user.email, user.name);

    // Save account ID to user (stripeAccountId not in current User type)
    db.updateUser(req.userId!, { stripeAccountId: accountId } as any);

    res.json({
      accountId,
      onboardingUrl,
      message: 'Stripe account created. Complete onboarding to receive payments.',
    });
  } catch (error: any) {
    console.error('Error creating Stripe Connect account:', error);
    res.status(500).json({ error: error.message || 'Failed to create Stripe account' });
  }
});

/**
 * Get Stripe Connect account status
 * GET /api/stripe/connect/status
 */
router.get('/connect/status', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can check Stripe status' });
    }

    const user = db.getUserById(req.userId!);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userWithStripe = user as any;
    if (!userWithStripe.stripeAccountId) {
      return res.json({
        connected: false,
        message: 'No Stripe account connected',
      });
    }

    const status = await getAccountStatus(userWithStripe.stripeAccountId);

    res.json({
      connected: true,
      accountId: userWithStripe.stripeAccountId,
      chargesEnabled: status.chargesEnabled,
      payoutsEnabled: status.payoutsEnabled,
      detailsSubmitted: status.detailsSubmitted,
      ready: status.chargesEnabled && status.payoutsEnabled,
    });
  } catch (error: any) {
    console.error('Error getting Stripe status:', error);
    res.status(500).json({ error: error.message || 'Failed to get Stripe status' });
  }
});

/**
 * Create login link for provider to access Stripe dashboard
 * GET /api/stripe/connect/login
 */
router.get('/connect/login', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can access Stripe dashboard' });
    }

    const user = db.getUserById(req.userId!);
    const userWithStripe = user as any;
    if (!user || !userWithStripe.stripeAccountId) {
      return res.status(404).json({ error: 'Stripe account not connected' });
    }

    const loginUrl = await createLoginLink(userWithStripe.stripeAccountId);

    res.json({
      loginUrl,
    });
  } catch (error: any) {
    console.error('Error creating login link:', error);
    res.status(500).json({ error: error.message || 'Failed to create login link' });
  }
});

export default router;
