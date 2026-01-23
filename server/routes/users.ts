import express, { Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';
import { searchRateLimit } from '../middleware/rateLimit';
import { isOnboardingComplete } from '../utils/onboarding';

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

router.get('/providers', (req, res: Response) => {
  try {
    const providers = db.getUsers()
      .filter(u => u.role === 'provider' && isOnboardingComplete(u.id));
    const reviews = db.getReviews();
    
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
        profilePicture: p.profilePicture,
      };
    }));
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/providers/search', searchRateLimit, (req, res: Response) => {
  try {
    let providers = db.getUsers()
      .filter(u => u.role === 'provider' && isOnboardingComplete(u.id));
    const reviews = db.getReviews();
    const services = db.getServices();
    const { q, category, subcategory, minPrice, maxPrice, minRating, latitude, longitude, radius, sortBy, hasService } = req.query;

    // Apply filters
    if (q) {
      const query = (q as string).toLowerCase();
      // Search in provider name, address, and also in service names/descriptions
      const matchingProviderIds = new Set<string>();
      
      providers.forEach(p => {
        if (p.name.toLowerCase().includes(query) ||
            p.email.toLowerCase().includes(query) ||
            p.address?.toLowerCase().includes(query)) {
          matchingProviderIds.add(p.id);
        }
      });
      
      // Also search in services
      services.forEach(s => {
        if (s.name.toLowerCase().includes(query) ||
            s.description.toLowerCase().includes(query) ||
            s.tags?.some(tag => tag.toLowerCase().includes(query))) {
          matchingProviderIds.add(s.providerId);
        }
      });
      
      providers = providers.filter(p => matchingProviderIds.has(p.id));
    }

    // Filter by service name/keyword (hasService)
    if (hasService) {
      const serviceQuery = (hasService as string).toLowerCase();
      const providerIdsWithService = new Set(
        services
          .filter(s => 
            s.name.toLowerCase().includes(serviceQuery) ||
            s.description.toLowerCase().includes(serviceQuery) ||
            s.tags?.some(tag => tag.toLowerCase().includes(serviceQuery))
          )
          .map(s => s.providerId)
      );
      providers = providers.filter(p => providerIdsWithService.has(p.id));
    }

    // Filter by category (via services)
    if (category) {
      const categoryStr = category as string;
      const providerIdsWithCategory = new Set(
        services
          .filter(s => s.category.toLowerCase() === categoryStr.toLowerCase())
          .map(s => s.providerId)
      );
      providers = providers.filter(p => providerIdsWithCategory.has(p.id));
    }

    // Filter by subcategory (via services)
    if (subcategory) {
      const subcategoryStr = subcategory as string;
      const providerIdsWithSubcategory = new Set(
        services
          .filter(s => s.subcategory?.toLowerCase() === subcategoryStr.toLowerCase())
          .map(s => s.providerId)
      );
      providers = providers.filter(p => providerIdsWithSubcategory.has(p.id));
    }

    // Filter by price range (via services)
    if (minPrice || maxPrice) {
      const min = minPrice ? parseFloat(minPrice as string) : 0;
      const max = maxPrice ? parseFloat(maxPrice as string) : Infinity;
      
      const providerIdsInPriceRange = new Set(
        services
          .filter(s => s.price >= min && s.price <= max)
          .map(s => s.providerId)
      );
      providers = providers.filter(p => providerIdsInPriceRange.has(p.id));
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
    } else if (sortBy === 'price') {
      // Sort by minimum service price
      providersWithRatings.sort((a, b) => {
        const aServices = services.filter(s => s.providerId === a.id);
        const bServices = services.filter(s => s.providerId === b.id);
        const aMinPrice = aServices.length > 0 ? Math.min(...aServices.map(s => s.price)) : Infinity;
        const bMinPrice = bServices.length > 0 ? Math.min(...bServices.map(s => s.price)) : Infinity;
        return aMinPrice - bMinPrice;
      });
    }

    res.json(providersWithRatings);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/providers/:id', (req, res: Response) => {
  try {
    const provider = db.getUserById(req.params.id);
    if (!provider || provider.role !== 'provider') {
      return res.status(404).json({ error: 'Provider not found' });
    }
    const reviews = db.getReviews();
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
      profilePicture: provider.profilePicture,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/profile', authenticate, (req: AuthRequest, res: Response) => {
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
      profilePicture: user.profilePicture,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.patch('/profile', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const { name, email, phone, latitude, longitude, address, profilePicture } = req.body;
    const updates: any = {};
    if (name) updates.name = name;
    if (email) updates.email = email;
    if (phone !== undefined) updates.phone = phone;
    if (latitude !== undefined) updates.latitude = latitude;
    if (longitude !== undefined) updates.longitude = longitude;
    if (address !== undefined) updates.address = address;
    if (profilePicture !== undefined) updates.profilePicture = profilePicture;

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
    res.status(500).json({ error: 'Server error' });
  }
});

// Profile picture upload endpoint
router.post('/upload-profile-picture', authenticate, (req: AuthRequest, res: Response) => {
  try {
    // In production, use multer or similar to handle file uploads
    // For now, accept base64 or URL
    const { image, imageUrl } = req.body;
    
    let profilePictureUrl: string;
    
    if (imageUrl) {
      // If URL provided, use it directly
      profilePictureUrl = imageUrl;
    } else if (image) {
      // If base64 image provided, save it and return URL
      // In production, upload to S3, Cloudinary, or similar
      // For now, return a placeholder URL
      profilePictureUrl = `https://api.placeholder.com/200/200?text=Profile`;
    } else {
      return res.status(400).json({ error: 'Image or imageUrl is required' });
    }

    // Update user profile picture
    const updated = db.updateUser(req.userId!, { profilePicture: profilePictureUrl });
    if (!updated) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      profilePicture: profilePictureUrl,
      message: 'Profile picture updated successfully',
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
