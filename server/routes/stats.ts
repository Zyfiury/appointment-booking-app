import express, { Request, Response } from 'express';
import { db } from '../data/database';
import { isOnboardingComplete } from '../utils/onboarding';

const router = express.Router();

// Simple in-memory cache for public stats (5 minute TTL)
let cachedStats: { data: any; expiresAt: number } | null = null;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

// Public stats endpoint (no authentication required)
router.get('/public', (req: Request, res: Response) => {
  try {
    // Return cached data if still valid
    if (cachedStats && cachedStats.expiresAt > Date.now()) {
      return res.json(cachedStats.data);
    }

    const users = db.getUsers();
    // Only count providers who have completed onboarding
    const providers = users.filter(
      u => u.role === 'provider' && isOnboardingComplete(u.id)
    );
    const customers = users.filter(u => u.role === 'customer');
    const services = db.getServices().filter(s => s.isActive);
    const appointments = db.getAppointments();
    const reviews = db.getReviews();
    const payments = db.getPayments().filter(p => p.status === 'completed');

    // Calculate average rating
    const totalRating = reviews.reduce((sum, r) => sum + r.rating, 0);
    const averageRating = reviews.length > 0 
      ? Math.round((totalRating / reviews.length) * 10) / 10 
      : 0;

    // Count completed appointments
    const completedAppointments = appointments.filter(
      a => a.status === 'completed'
    ).length;

    // Category distribution (top 5)
    const categoryCount: { [key: string]: number } = {};
    services.forEach(service => {
      categoryCount[service.category] = (categoryCount[service.category] || 0) + 1;
    });
    const topCategories = Object.entries(categoryCount)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 5)
      .map(([category, count]) => ({ category, count }));

    // Total GMV (Gross Merchandise Value) - optional, can be omitted if too sensitive
    const totalGMV = payments.reduce((sum, p) => sum + p.amount, 0);

    // Geographic coverage (unique cities/regions from provider addresses)
    const uniqueLocations = new Set<string>();
    providers.forEach(provider => {
      if (provider.address) {
        // Extract city from address (simple approach - can be improved)
        const addressParts = provider.address.split(',');
        if (addressParts.length > 0) {
          const city = addressParts[addressParts.length - 2]?.trim();
          if (city) {
            uniqueLocations.add(city);
          }
        }
      }
    });

    const statsData = {
      platform: {
        totalProviders: providers.length,
        totalCustomers: customers.length,
        totalServices: services.length,
        totalAppointments: completedAppointments,
        totalReviews: reviews.length,
        averageRating: averageRating,
        // totalGMV: totalGMV, // Uncomment if you want to show GMV
      },
      categories: topCategories,
      geographicCoverage: {
        cities: uniqueLocations.size,
        // regions: uniqueLocations.size, // Can add regions if tracked
      },
      lastUpdated: new Date().toISOString(),
    };

    // Cache the result
    cachedStats = {
      data: statsData,
      expiresAt: Date.now() + CACHE_TTL_MS,
    };

    res.json(statsData);
  } catch (error) {
    console.error('Public stats error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
