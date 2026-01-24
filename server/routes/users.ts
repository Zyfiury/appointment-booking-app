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
    const allUsers = db.getUsers();
    const providers = allUsers.filter(u => u.role === 'provider');
    const reviews = db.getReviews();
    
    res.json(providers.map((p: any) => {
      const providerReviews = reviews.filter((r: any) => r.providerId === p.id);
      const rating = providerReviews.length > 0
        ? providerReviews.reduce((sum: number, r: any) => sum + r.rating, 0) / providerReviews.length
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
    const allUsers = db.getUsers();
    let providers = allUsers.filter(u => u.role === 'provider');
    const reviews = db.getReviews();
    const services = db.getServices();
    const { q, category, minPrice, maxPrice, minRating, latitude, longitude, radius, sortBy } = req.query;

    // Apply filters
    if (q) {
      const query = (q as string).toLowerCase();
      providers = providers.filter((p: any) => 
        p.name.toLowerCase().includes(query) ||
        p.email.toLowerCase().includes(query)
      );
    }

    // Filter by category (providers who have services in this category)
    if (category && typeof category === 'string') {
      const providerIdsWithCategory = new Set(
        services.filter((s: any) => s.category === category).map((s: any) => s.providerId)
      );
      providers = providers.filter(p => providerIdsWithCategory.has(p.id));
    }

    // Filter by price range (providers who have services in this price range)
    if (minPrice || maxPrice) {
      const min = minPrice ? parseFloat(minPrice as string) : 0;
      const max = maxPrice ? parseFloat(maxPrice as string) : Infinity;
      if (!isNaN(min) && !isNaN(max)) {
        const providerIdsInPriceRange = new Set(
          services.filter((s: any) => s.price >= min && s.price <= max).map((s: any) => s.providerId)
        );
        providers = providers.filter(p => providerIdsInPriceRange.has(p.id));
      }
    }

    if (minRating) {
      providers = providers.filter((p: any) => {
        const providerReviews = reviews.filter((r: any) => r.providerId === p.id);
        if (providerReviews.length === 0) return false;
        const rating = providerReviews.reduce((sum: number, r: any) => sum + r.rating, 0) / providerReviews.length;
        return rating >= parseFloat(minRating as string);
      });
    }

    // Filter by location if provided
    const userLat = latitude ? parseFloat(latitude as string) : null;
    const userLng = longitude ? parseFloat(longitude as string) : null;
    const searchRadius = radius ? parseFloat(radius as string) : null;

    if (userLat !== null && userLng !== null && searchRadius !== null) {
      providers = providers.filter((p: any) => {
        if (p.latitude === undefined || p.longitude === undefined) return false;
        const distance = calculateDistance(userLat, userLng, p.latitude, p.longitude);
        return distance <= searchRadius;
      });
    }

    // Add ratings and distance to providers
    const providersWithRatings = providers.map((p: any) => {
      const providerReviews = reviews.filter((r: any) => r.providerId === p.id);
      const rating = providerReviews.length > 0
        ? providerReviews.reduce((sum: number, r: any) => sum + r.rating, 0) / providerReviews.length
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
      providersWithRatings.sort((a: any, b: any) => 
        (b.rating ?? 0) - (a.rating ?? 0)
      );
    } else if (sortBy === 'distance' && userLat !== null && userLng !== null) {
      providersWithRatings.sort((a: any, b: any) => 
        (a.distance ?? Infinity) - (b.distance ?? Infinity)
      );
    } else if (sortBy === 'name') {
      providersWithRatings.sort((a: any, b: any) => a.name.localeCompare(b.name));
    }

    res.json(providersWithRatings);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/providers/:id', async (req, res: Response) => {
  try {
    const user = db.getUserById(req.params.id);
    if (!user || user.role !== 'provider') {
      return res.status(404).json({ error: 'Provider not found' });
    }
    const reviews = db.getReviews();
    const providerReviews = reviews.filter((r: any) => r.providerId === user.id);
    const rating = providerReviews.length > 0
      ? providerReviews.reduce((sum: number, r: any) => sum + r.rating, 0) / providerReviews.length
      : null;
    
    res.json({
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      rating: rating ? Math.round(rating * 10) / 10 : null,
      reviewCount: providerReviews.length,
      latitude: user.latitude,
      longitude: user.longitude,
      address: user.address,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/profile', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const user = db.getUserById(req.userId!);
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

    // Validate name if provided
    if (name !== undefined) {
      if (typeof name !== 'string' || name.trim().length < 2 || name.trim().length > 100) {
        return res.status(400).json({ error: 'Name must be between 2 and 100 characters' });
      }
      updates.name = name.trim();
    }

    // Validate phone if provided
    if (phone !== undefined) {
      if (phone !== null && phone !== '') {
        // Basic phone validation (allows various formats)
        const phoneRegex = /^[\d\s\-\+\(\)]+$/;
        if (typeof phone !== 'string' || !phoneRegex.test(phone) || phone.length > 20) {
          return res.status(400).json({ error: 'Invalid phone number format' });
        }
        updates.phone = phone.trim();
      } else {
        updates.phone = null;
      }
    }

    // Validate coordinates if provided
    if (latitude !== undefined) {
      const lat = parseFloat(latitude);
      if (isNaN(lat) || lat < -90 || lat > 90) {
        return res.status(400).json({ error: 'Latitude must be between -90 and 90' });
      }
      updates.latitude = lat;
    }

    if (longitude !== undefined) {
      const lng = parseFloat(longitude);
      if (isNaN(lng) || lng < -180 || lng > 180) {
        return res.status(400).json({ error: 'Longitude must be between -180 and 180' });
      }
      updates.longitude = lng;
    }

    // Validate address if provided
    if (address !== undefined) {
      if (address !== null && address !== '') {
        if (typeof address !== 'string' || address.trim().length > 200) {
          return res.status(400).json({ error: 'Address cannot exceed 200 characters' });
        }
        updates.address = address.trim();
      } else {
        updates.address = null;
      }
    }

    // Validate profile picture URL if provided
    if (profilePicture !== undefined) {
      if (profilePicture !== null && profilePicture !== '') {
        if (typeof profilePicture !== 'string' || profilePicture.length > 500) {
          return res.status(400).json({ error: 'Profile picture URL cannot exceed 500 characters' });
        }
        // Basic URL validation
        try {
          new URL(profilePicture);
        } catch {
          return res.status(400).json({ error: 'Invalid profile picture URL format' });
        }
        updates.profilePicture = profilePicture.trim();
      } else {
        updates.profilePicture = null;
      }
    }

    // Check if there are any updates
    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    const updated = db.updateUser(req.userId!, updates);
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
      profilePicture: updated.profilePicture,
    });
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ error: 'Failed to update profile. Please try again.' });
  }
});

export default router;
