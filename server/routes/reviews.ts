import express, { Request, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';
import { v4 as uuidv4 } from 'uuid';
import { validate, schemas } from '../middleware/validation';

const router = express.Router();

// Get reviews
router.get('/', (req: Request, res: Response) => {
  try {
    const { providerId } = req.query;
    let reviews = db.getReviews();

    if (providerId) {
      reviews = reviews.filter(r => r.providerId === providerId);
    }

    // Add customer names
    const reviewsWithDetails = reviews.map(review => {
      const customer = db.getUserById(review.customerId);
      return {
        ...review,
        customerName: customer?.name || 'Anonymous',
        customer: customer ? {
          id: customer.id,
          name: customer.name,
        } : null,
      };
    });

    res.json(reviewsWithDetails);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Create review
router.post('/', authenticate, validate(schemas.createReview), (req: AuthRequest, res: Response) => {
  try {
    const { appointmentId, providerId, rating, comment, photos } = req.body;

    const appointment = db.getAppointmentById(appointmentId);
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    if (appointment.customerId !== req.userId) {
      return res.status(403).json({ error: 'Only the customer can review' });
    }

    // Check if review already exists
    const existingReview = db.getReviews().find(
      r => r.appointmentId === appointmentId
    );
    if (existingReview) {
      return res.status(400).json({ error: 'Review already exists for this appointment' });
    }

    const review = db.createReview({
      appointmentId,
      providerId,
      customerId: req.userId!,
      rating,
      comment,
      photos: photos || [],
    });

    // Update provider rating
    db.updateProviderRating(providerId);

    const customer = db.getUserById(req.userId!);
    res.status(201).json({
      ...review,
      customerName: customer?.name || 'Anonymous',
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update review
router.patch('/:id', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const review = db.getReviewById(req.params.id);
    if (!review) {
      return res.status(404).json({ error: 'Review not found' });
    }

    if (review.customerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const { rating, comment, photos } = req.body;
    const updated = db.updateReview(req.params.id, {
      rating,
      comment,
      photos,
    });

    // Update provider rating
    db.updateProviderRating(review.providerId);

    const customer = db.getUserById(req.userId!);
    res.json({
      ...updated,
      customerName: customer?.name || 'Anonymous',
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete review
router.delete('/:id', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const review = db.getReviewById(req.params.id);
    if (!review) {
      return res.status(404).json({ error: 'Review not found' });
    }

    if (review.customerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    db.deleteReview(req.params.id);
    db.updateProviderRating(review.providerId);

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get provider stats
router.get('/stats/:providerId', (req: Request, res: Response) => {
  try {
    const reviews = db.getReviews().filter(
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
