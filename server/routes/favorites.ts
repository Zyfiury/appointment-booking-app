import express, { Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';

const router = express.Router();

// Get user's favorites
router.get('/', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const favorites = db.getFavorites(userId);
    const providers = db.getUsers().filter(u => u.role === 'provider');
    const reviews = db.getReviews();

    const favoriteProviders = favorites.map(fav => {
      const provider = providers.find(p => p.id === fav.providerId);
      if (!provider) return null;

      const providerReviews = reviews.filter(r => r.providerId === provider.id);
      const rating = providerReviews.length > 0
        ? providerReviews.reduce((sum, r) => sum + r.rating, 0) / providerReviews.length
        : null;

      return {
        id: provider.id,
        name: provider.name,
        email: provider.email,
        phone: provider.phone,
        rating: rating ? Math.round(rating * 10) / 10 : null,
        reviewCount: providerReviews.length,
        latitude: provider.latitude,
        longitude: provider.longitude,
        address: provider.address,
        profilePicture: provider.profilePicture,
        favoritedAt: fav.createdAt,
      };
    }).filter(p => p !== null);

    res.json(favoriteProviders);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Check if provider is favorited
router.get('/check/:providerId', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const { providerId } = req.params;
    const isFavorite = db.isFavorite(userId, providerId);
    res.json({ isFavorite });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Add favorite
router.post('/:providerId', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const { providerId } = req.params;
    
    // Verify provider exists
    const provider = db.getUserById(providerId);
    if (!provider || provider.role !== 'provider') {
      return res.status(404).json({ error: 'Provider not found' });
    }

    const favorite = db.addFavorite(userId, providerId);
    res.json({ success: true, favorite });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Remove favorite
router.delete('/:providerId', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const { providerId } = req.params;
    const removed = db.removeFavorite(userId, providerId);
    if (!removed) {
      return res.status(404).json({ error: 'Favorite not found' });
    }
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
