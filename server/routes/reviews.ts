import express, { Request, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';
import { v4 as uuidv4 } from 'uuid';
<<<<<<< HEAD
import { validate, schemas } from '../middleware/validation';
import { createReport } from '../utils/reports';
=======
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209

const router = express.Router();

// Get reviews
<<<<<<< HEAD
router.get('/', (req: Request, res: Response) => {
  try {
    const { providerId } = req.query;
    let reviews = db.getReviews();
=======
router.get('/', async (req: Request, res: Response) => {
  try {
    const { providerId } = req.query;
    let reviews = await db.getReviews();
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209

    if (providerId) {
      reviews = reviews.filter(r => r.providerId === providerId);
    }

    // Add customer names
<<<<<<< HEAD
    const reviewsWithDetails = reviews.map(review => {
      const customer = db.getUserById(review.customerId);
=======
    const reviewsWithDetails = await Promise.all(reviews.map(async (review) => {
      const customer = await db.getUserById(review.customerId);
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
      return {
        ...review,
        customerName: customer?.name || 'Anonymous',
        customer: customer ? {
          id: customer.id,
          name: customer.name,
        } : null,
      };
<<<<<<< HEAD
    });
=======
    }));
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209

    res.json(reviewsWithDetails);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Create review
<<<<<<< HEAD
router.post('/', authenticate, validate(schemas.createReview), (req: AuthRequest, res: Response) => {
  try {
    const { appointmentId, providerId, rating, comment, photos } = req.body;

    const appointment = db.getAppointmentById(appointmentId);
=======
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
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    if (appointment.customerId !== req.userId) {
      return res.status(403).json({ error: 'Only the customer can review' });
    }

    // Check if review already exists
<<<<<<< HEAD
    const existingReview = db.getReviews().find(
=======
    const allReviews = await db.getReviews();
    const existingReview = allReviews.find(
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
      r => r.appointmentId === appointmentId
    );
    if (existingReview) {
      return res.status(400).json({ error: 'Review already exists for this appointment' });
    }

<<<<<<< HEAD
    const review = db.createReview({
=======
    const review = await db.createReview({
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
      appointmentId,
      providerId,
      customerId: req.userId!,
      rating,
      comment,
      photos: photos || [],
    });

    // Update provider rating
<<<<<<< HEAD
    db.updateProviderRating(providerId);

    const customer = db.getUserById(req.userId!);
=======
    await db.updateProviderRating(providerId);

    const customer = await db.getUserById(req.userId!);
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
    res.status(201).json({
      ...review,
      customerName: customer?.name || 'Anonymous',
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

<<<<<<< HEAD
// Report review (flag for moderation)
router.post('/:id/report', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const review = db.getReviewById(req.params.id);
    if (!review) return res.status(404).json({ error: 'Review not found' });
    const { reason } = req.body || {};
    createReport('review', review.id, req.userId!, reason);
    res.status(202).json({ message: 'Report submitted. Thank you.' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update review
router.patch('/:id', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const review = db.getReviewById(req.params.id);
=======
// Update review
router.patch('/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const review = await db.getReviewById(req.params.id);
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
    if (!review) {
      return res.status(404).json({ error: 'Review not found' });
    }

    if (review.customerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const { rating, comment, photos } = req.body;
<<<<<<< HEAD
    const updated = db.updateReview(req.params.id, {
=======
    const updated = await db.updateReview(req.params.id, {
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
      rating,
      comment,
      photos,
    });

    // Update provider rating
<<<<<<< HEAD
    db.updateProviderRating(review.providerId);

    const customer = db.getUserById(req.userId!);
=======
    await db.updateProviderRating(review.providerId);

    const customer = await db.getUserById(req.userId!);
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
    res.json({
      ...updated,
      customerName: customer?.name || 'Anonymous',
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete review
<<<<<<< HEAD
router.delete('/:id', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const review = db.getReviewById(req.params.id);
=======
router.delete('/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const review = await db.getReviewById(req.params.id);
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
    if (!review) {
      return res.status(404).json({ error: 'Review not found' });
    }

    if (review.customerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

<<<<<<< HEAD
    db.deleteReview(req.params.id);
    db.updateProviderRating(review.providerId);
=======
    await db.deleteReview(req.params.id);
    await db.updateProviderRating(review.providerId);
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get provider stats
<<<<<<< HEAD
router.get('/stats/:providerId', (req: Request, res: Response) => {
  try {
    const reviews = db.getReviews().filter(
=======
router.get('/stats/:providerId', async (req: Request, res: Response) => {
  try {
    const allReviews = await db.getReviews();
    const reviews = allReviews.filter(
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
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
