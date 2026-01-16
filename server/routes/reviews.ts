import express, { Request, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';
import { v4 as uuidv4 } from 'uuid';

const router = express.Router();

// Get reviews
router.get('/', async (req: Request, res: Response) => {
  try {
    const { providerId } = req.query;
    let reviews = await db.getReviews();

    if (providerId) {
      reviews = reviews.filter(r => r.providerId === providerId);
    }

    // Add customer names
    const reviewsWithDetails = await Promise.all(reviews.map(async (review) => {
      const customer = await db.getUserById(review.customerId);
      return {
        ...review,
        customerName: customer?.name || 'Anonymous',
        customer: customer ? {
          id: customer.id,
          name: customer.name,
        } : null,
      };
    }));

    res.json(reviewsWithDetails);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Create review
router.post('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { appointmentId, providerId, rating, comment, photos } = req.body;

    if (!appointmentId || !providerId || !rating || !comment) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    if (rating < 1 || rating > 5) {
      return res.status(400).json({ error: 'Rating must be between 1 and 5' });
    }

    const appointment = await db.getAppointmentById(appointmentId);
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    if (appointment.customerId !== req.userId) {
      return res.status(403).json({ error: 'Only the customer can review' });
    }

    // Check if review already exists
    const allReviews = await db.getReviews();
    const existingReview = allReviews.find(
      r => r.appointmentId === appointmentId
    );
    if (existingReview) {
      return res.status(400).json({ error: 'Review already exists for this appointment' });
    }

    const review = await db.createReview({
      appointmentId,
      providerId,
      customerId: req.userId!,
      rating,
      comment,
      photos: photos || [],
    });

    // Update provider rating
    await db.updateProviderRating(providerId);

    const customer = await db.getUserById(req.userId!);
    res.status(201).json({
      ...review,
      customerName: customer?.name || 'Anonymous',
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update review
router.patch('/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const review = await db.getReviewById(req.params.id);
    if (!review) {
      return res.status(404).json({ error: 'Review not found' });
    }

    if (review.customerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const { rating, comment, photos } = req.body;
    const updated = await db.updateReview(req.params.id, {
      rating,
      comment,
      photos,
    });

    // Update provider rating
    await db.updateProviderRating(review.providerId);

    const customer = await db.getUserById(req.userId!);
    res.json({
      ...updated,
      customerName: customer?.name || 'Anonymous',
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete review
router.delete('/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const review = await db.getReviewById(req.params.id);
    if (!review) {
      return res.status(404).json({ error: 'Review not found' });
    }

    if (review.customerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await db.deleteReview(req.params.id);
    await db.updateProviderRating(review.providerId);

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get provider stats
router.get('/stats/:providerId', async (req: Request, res: Response) => {
  try {
    const allReviews = await db.getReviews();
    const reviews = allReviews.filter(
      r => r.providerId === req.params.providerId
    );

    if (reviews.length === 0) {
      return res.json({
        averageRating: 0,
        totalReviews: 0,
        ratingDistribution: { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 },
      });
    }

    const totalRating = reviews.reduce((sum, r) => sum + r.rating, 0);
    const averageRating = totalRating / reviews.length;

    const ratingDistribution = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    reviews.forEach(r => {
      ratingDistribution[r.rating as keyof typeof ratingDistribution]++;
    });

    res.json({
      averageRating: Math.round(averageRating * 10) / 10,
      totalReviews: reviews.length,
      ratingDistribution,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
