import express, { Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';

const router = express.Router();

// Helper function to calculate distance between two coordinates (Haversine formula)
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371; // Earth's radius in kilometers
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c; // Distance in kilometers
}

router.get('/providers', async (req, res: Response) => {
  try {
    const allUsers = await db.getUsers();
    const providers = allUsers.filter(u => u.role === 'provider');
    const reviews = await db.getReviews();
    
    res.json(providers.map(p => {
      const providerReviews = reviews.filter(r => r.providerId === p.id);
      const rating = providerReviews.length > 0
        ? providerReviews.reduce((sum, r) => sum + r.rating, 0) / providerReviews.length
        : null;
      
      return {
        id: p.id,
        name: p.name,
        email: p.email,
        phone: p.phone,
        rating: rating ? Math.round(rating * 10) / 10 : null,
        reviewCount: providerReviews.length,
        latitude: p.latitude,
        longitude: p.longitude,
        address: p.address,
      };
    }));
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/providers/search', async (req, res: Response) => {
  try {
    const allUsers = await db.getUsers();
    let providers = allUsers.filter(u => u.role === 'provider');
    const reviews = await db.getReviews();
    const { q, category, minPrice, maxPrice, minRating, latitude, longitude, radius, sortBy } = req.query;

    // Apply filters
    if (q) {
      const query = (q as string).toLowerCase();
      providers = providers.filter(p => 
        p.name.toLowerCase().includes(query) ||
        p.email.toLowerCase().includes(query)
      );
    }

    if (minRating) {
      providers = providers.filter(p => {
        const providerReviews = reviews.filter(r => r.providerId === p.id);
        if (providerReviews.length === 0) return false;
        const rating = providerReviews.reduce((sum, r) => sum + r.rating, 0) / providerReviews.length;
        return rating >= parseFloat(minRating as string);
      });
    }

    // Filter by location if provided
    const userLat = latitude ? parseFloat(latitude as string) : null;
    const userLng = longitude ? parseFloat(longitude as string) : null;
    const searchRadius = radius ? parseFloat(radius as string) : null;

    if (userLat !== null && userLng !== null && searchRadius !== null) {
      providers = providers.filter(p => {
        if (p.latitude === undefined || p.longitude === undefined) return false;
        const distance = calculateDistance(userLat, userLng, p.latitude, p.longitude);
        return distance <= searchRadius;
      });
    }

    // Add ratings and distance to providers
    const providersWithRatings = providers.map(p => {
      const providerReviews = reviews.filter(r => r.providerId === p.id);
      const rating = providerReviews.length > 0
        ? providerReviews.reduce((sum, r) => sum + r.rating, 0) / providerReviews.length
        : null;
      
      let distance: number | null = null;
      if (userLat !== null && userLng !== null && p.latitude !== undefined && p.longitude !== undefined) {
        distance = calculateDistance(userLat, userLng, p.latitude, p.longitude);
      }
      
      return {
        id: p.id,
        name: p.name,
        email: p.email,
        phone: p.phone,
        rating: rating ? Math.round(rating * 10) / 10 : null,
        reviewCount: providerReviews.length,
        latitude: p.latitude,
        longitude: p.longitude,
        address: p.address,
        distance: distance ? Math.round(distance * 10) / 10 : null, // Round to 1 decimal place
      };
    });

    // Sort
    if (sortBy === 'rating') {
      providersWithRatings.sort((a, b) => 
        (b.rating ?? 0) - (a.rating ?? 0)
      );
    } else if (sortBy === 'distance' && userLat !== null && userLng !== null) {
      providersWithRatings.sort((a, b) => 
        (a.distance ?? Infinity) - (b.distance ?? Infinity)
      );
    } else if (sortBy === 'name') {
      providersWithRatings.sort((a, b) => a.name.localeCompare(b.name));
    }

    res.json(providersWithRatings);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/providers/:id', async (req, res: Response) => {
  try {
    const provider = await db.getUserById(req.params.id);
    if (!provider || provider.role !== 'provider') {
      return res.status(404).json({ error: 'Provider not found' });
    }
    const reviews = await db.getReviews();
    const providerReviews = reviews.filter(r => r.providerId === provider.id);
    const rating = providerReviews.length > 0
      ? providerReviews.reduce((sum, r) => sum + r.rating, 0) / providerReviews.length
      : null;
    
    res.json({
      id: provider.id,
      name: provider.name,
      email: provider.email,
      phone: provider.phone,
      rating: rating ? Math.round(rating * 10) / 10 : null,
      reviewCount: providerReviews.length,
      latitude: provider.latitude,
      longitude: provider.longitude,
      address: provider.address,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/profile', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const user = await db.getUserById(req.userId!);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      phone: user.phone,
      latitude: user.latitude,
      longitude: user.longitude,
      address: user.address,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.patch('/profile', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { name, phone, latitude, longitude, address, profilePicture } = req.body;
    const updates: any = {};
    if (name) updates.name = name;
    if (phone !== undefined) updates.phone = phone;
    if (latitude !== undefined) updates.latitude = latitude;
    if (longitude !== undefined) updates.longitude = longitude;
    if (address !== undefined) updates.address = address;
    if (profilePicture !== undefined) updates.profilePicture = profilePicture;

    const updated = await db.updateUser(req.userId!, updates);
    if (!updated) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      id: updated.id,
      email: updated.email,
      name: updated.name,
      role: updated.role,
      phone: updated.phone,
      latitude: updated.latitude,
      longitude: updated.longitude,
      address: updated.address,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
