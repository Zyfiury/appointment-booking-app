import express, { Response, NextFunction } from 'express';
import bcrypt from 'bcryptjs';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';
import { auditLog } from '../utils/audit';

const router = express.Router();

// Simple admin check (in production, use role-based auth with 'admin' role)
const isAdmin = (req: AuthRequest): boolean => {
  // For now, check if user email is admin (configure via env)
  const adminEmail = process.env.ADMIN_EMAIL || '';
  const user = db.getUserById(req.userId!);
  return user?.email === adminEmail || process.env.NODE_ENV !== 'production';
};

// Admin middleware
const requireAdmin = (req: express.Request, res: Response, next: NextFunction) => {
  const authReq = req as AuthRequest;
  if (!isAdmin(authReq)) {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

// Get all users (admin only)
router.get('/users', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const users = db.getUsers().map(u => ({
      id: u.id,
      email: u.email,
      name: u.name,
      role: u.role,
      createdAt: u.createdAt,
    }));
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get all providers (admin only)
router.get('/providers', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const providers = db.getUsers().filter(u => u.role === 'provider');
    res.json(providers);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get all appointments (admin only)
router.get('/appointments', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const appointments = db.getAppointments();
    const withDetails = appointments.map(apt => {
      const customer = db.getUserById(apt.customerId);
      const provider = db.getUserById(apt.providerId);
      const service = db.getServiceById(apt.serviceId);
      return {
        ...apt,
        customer: customer ? { id: customer.id, name: customer.name, email: customer.email } : null,
        provider: provider ? { id: provider.id, name: provider.name, email: provider.email } : null,
        service: service || null,
      };
    });
    res.json(withDetails);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get all payments (admin only)
router.get('/payments', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const payments = db.getPayments();
    const withDetails = payments.map(payment => {
      const appointment = db.getAppointmentById(payment.appointmentId);
      return {
        ...payment,
        appointment: appointment || null,
      };
    });
    res.json(withDetails);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Issue refund (admin only)
router.post('/payments/:id/refund', authenticate, requireAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const payment = db.getPaymentById(req.params.id);
    if (!payment) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    if (payment.status !== 'completed') {
      return res.status(400).json({ error: 'Only completed payments can be refunded' });
    }

    // Update payment status
    db.updatePayment(payment.id, { status: 'refunded' });

    auditLog({
      action: 'payment.refunded',
      entity: 'payment',
      entityId: payment.id,
      userId: req.userId!,
      meta: { adminRefund: true, amount: payment.amount },
    });

    res.json({ success: true, payment: db.getPaymentById(payment.id) });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Remove review (admin only)
router.delete('/reviews/:id', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const review = db.getReviewById(req.params.id);
    if (!review) {
      return res.status(404).json({ error: 'Review not found' });
    }

    db.deleteReview(req.params.id);
    db.updateProviderRating(review.providerId);

    auditLog({
      action: 'review.removed',
      entity: 'review',
      entityId: review.id,
      userId: req.userId!,
      meta: { adminAction: true, providerId: review.providerId },
    });

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Remove provider image (admin only)
router.delete('/provider-images/:id', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const image = db.getProviderImageById(req.params.id);
    if (!image) {
      return res.status(404).json({ error: 'Image not found' });
    }

    db.deleteProviderImage(req.params.id);

    auditLog({
      action: 'image.removed',
      entity: 'provider_image',
      entityId: image.id,
      userId: req.userId!,
      meta: { adminAction: true, providerId: image.providerId },
    });

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get audit logs (admin only)
router.get('/audit-logs', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const { getAuditLog } = require('../utils/audit');
    const limit = parseInt((req.query.limit as string) || '100');
    const logs = getAuditLog(limit);
    res.json(logs);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get reports (admin only)
router.get('/reports', authenticate, requireAdmin, (req: AuthRequest, res: Response) => {
  try {
    const { getReports } = require('../utils/reports');
    const limit = parseInt((req.query.limit as string) || '500');
    const reports = getReports(limit);
    res.json(reports);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Create test providers (public endpoint with secret key for easy testing)
// POST /api/admin/create-test-providers?secret=YOUR_SECRET_KEY
router.post('/create-test-providers', async (req: express.Request, res: Response) => {
  try {
    // Simple secret key check (set in Railway env: TEST_PROVIDERS_SECRET)
    const secret = req.query.secret as string || req.body.secret;
    const expectedSecret = process.env.TEST_PROVIDERS_SECRET || 'test-secret-key-change-in-production';
    
    if (secret !== expectedSecret) {
      return res.status(403).json({ error: 'Invalid secret key' });
    }

    // Test provider data
    const testProviders = [
      {
        category: 'Barber',
        name: 'Elite Barbershop',
        email: 'barber@test.bookly.app',
        password: 'Test123!@#',
        phone: '+1-555-0101',
        address: '123 Main Street, Downtown',
        latitude: 40.7128,
        longitude: -74.0060,
        services: [
          { name: 'Classic Haircut', subcategory: 'Haircut', duration: 30, price: 25, description: 'Professional haircut with styling' },
          { name: 'Skin Fade', subcategory: 'Skin Fade', duration: 45, price: 35, description: 'Modern skin fade haircut' },
          { name: 'Beard Trim', subcategory: 'Beard Trim', duration: 20, price: 15, description: 'Professional beard trimming and shaping' },
        ],
      },
      {
        category: 'Hair',
        name: 'Glamour Hair Salon',
        email: 'hair@test.bookly.app',
        password: 'Test123!@#',
        phone: '+1-555-0102',
        address: '456 Fashion Avenue, Uptown',
        latitude: 40.7589,
        longitude: -73.9851,
        services: [
          { name: 'Women\'s Haircut', subcategory: 'Haircut', duration: 60, price: 55, description: 'Professional women\'s haircut and styling' },
          { name: 'Hair Color', subcategory: 'Color', duration: 120, price: 120, description: 'Full hair coloring service' },
          { name: 'Highlights', subcategory: 'Highlights', duration: 150, price: 150, description: 'Professional hair highlighting' },
        ],
      },
      {
        category: 'Beauty',
        name: 'Luxury Beauty Spa',
        email: 'beauty@test.bookly.app',
        password: 'Test123!@#',
        phone: '+1-555-0103',
        address: '789 Beauty Lane, Midtown',
        latitude: 40.7505,
        longitude: -73.9934,
        services: [
          { name: 'Manicure & Pedicure', subcategory: 'Nails', duration: 90, price: 65, description: 'Full nail care service' },
          { name: 'Facial Treatment', subcategory: 'Facial', duration: 60, price: 80, description: 'Deep cleansing facial treatment' },
          { name: 'Eyelash Extensions', subcategory: 'Lashes', duration: 120, price: 150, description: 'Professional eyelash extensions' },
        ],
      },
      {
        category: 'Massage',
        name: 'Tranquil Massage Therapy',
        email: 'massage@test.bookly.app',
        password: 'Test123!@#',
        phone: '+1-555-0104',
        address: '321 Wellness Boulevard, East Side',
        latitude: 40.7282,
        longitude: -73.9942,
        services: [
          { name: 'Swedish Massage', subcategory: 'Swedish', duration: 60, price: 80, description: 'Relaxing Swedish massage' },
          { name: 'Deep Tissue Massage', subcategory: 'Deep Tissue', duration: 90, price: 120, description: 'Therapeutic deep tissue massage' },
          { name: 'Hot Stone Massage', subcategory: 'Hot Stone', duration: 90, price: 130, description: 'Relaxing hot stone therapy' },
        ],
      },
      {
        category: 'Fitness',
        name: 'FitZone Personal Training',
        email: 'fitness@test.bookly.app',
        password: 'Test123!@#',
        phone: '+1-555-0105',
        address: '654 Fitness Street, West Side',
        latitude: 40.7614,
        longitude: -74.0016,
        services: [
          { name: 'Personal Training Session', subcategory: 'Personal Training', duration: 60, price: 75, description: 'One-on-one personal training' },
          { name: 'Yoga Class', subcategory: 'Yoga', duration: 60, price: 25, description: 'Group yoga class', capacity: 15 },
          { name: 'Nutrition Consultation', subcategory: 'Nutrition', duration: 45, price: 60, description: 'Personalized nutrition planning' },
        ],
      },
      {
        category: 'Dental',
        name: 'Bright Smile Dental',
        email: 'dental@test.bookly.app',
        password: 'Test123!@#',
        phone: '+1-555-0106',
        address: '987 Health Plaza, North Side',
        latitude: 40.7831,
        longitude: -73.9712,
        services: [
          { name: 'Teeth Cleaning', subcategory: 'Cleaning', duration: 45, price: 120, description: 'Professional dental cleaning' },
          { name: 'Teeth Whitening', subcategory: 'Teeth Whitening', duration: 90, price: 300, description: 'Professional teeth whitening treatment' },
          { name: 'Dental Checkup', subcategory: 'Checkup', duration: 30, price: 100, description: 'Comprehensive dental examination' },
        ],
      },
      {
        category: 'Therapy',
        name: 'Mindful Therapy Center',
        email: 'therapy@test.bookly.app',
        password: 'Test123!@#',
        phone: '+1-555-0107',
        address: '147 Wellness Way, South Side',
        latitude: 40.6892,
        longitude: -74.0445,
        services: [
          { name: 'Individual Therapy', subcategory: 'Individual', duration: 60, price: 120, description: 'One-on-one therapy session' },
          { name: 'Couples Therapy', subcategory: 'Couples', duration: 90, price: 150, description: 'Couples counseling session' },
          { name: 'Initial Consultation', subcategory: 'Consultation', duration: 45, price: 80, description: 'Initial therapy consultation' },
        ],
      },
      {
        category: 'Medical',
        name: 'City Medical Clinic',
        email: 'medical@test.bookly.app',
        password: 'Test123!@#',
        phone: '+1-555-0108',
        address: '258 Medical Center Drive, Central',
        latitude: 40.7505,
        longitude: -73.9934,
        services: [
          { name: 'General Checkup', subcategory: 'General Checkup', duration: 30, price: 150, description: 'Comprehensive health checkup' },
          { name: 'Consultation', subcategory: 'Consultation', duration: 30, price: 120, description: 'Medical consultation with doctor' },
          { name: 'Vaccination', subcategory: 'Vaccination', duration: 15, price: 50, description: 'Vaccination service' },
        ],
      },
      {
        category: 'Home Services',
        name: 'Pro Home Services',
        email: 'homeservices@test.bookly.app',
        password: 'Test123!@#',
        phone: '+1-555-0109',
        address: '369 Service Road, Suburbs',
        latitude: 40.7580,
        longitude: -73.9855,
        services: [
          { name: 'Plumbing Service', subcategory: 'Plumbing', duration: 120, price: 150, description: 'Professional plumbing repair and installation' },
          { name: 'Electrical Service', subcategory: 'Electrical', duration: 120, price: 180, description: 'Electrical repair and installation' },
          { name: 'Deep Cleaning', subcategory: 'Cleaning', duration: 180, price: 200, description: 'Comprehensive home deep cleaning' },
        ],
      },
    ];

    let created = 0;
    let skipped = 0;
    const results: any[] = [];

    for (const providerData of testProviders) {
      try {
        // Check if provider already exists
        const existing = db.getUserByEmail(providerData.email);
        if (existing) {
          results.push({ status: 'skipped', provider: providerData.name, email: providerData.email });
          skipped++;
          continue;
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(providerData.password, 10);

        // Create provider user
        const provider = db.createUser({
          email: providerData.email,
          password: hashedPassword,
          name: providerData.name,
          role: 'provider',
          phone: providerData.phone,
          address: providerData.address,
          latitude: providerData.latitude,
          longitude: providerData.longitude,
          emailVerified: true,
        });

        // Create services
        const services = [];
        for (const serviceData of providerData.services) {
          const service = db.createService({
            providerId: provider.id,
            name: serviceData.name,
            description: serviceData.description,
            duration: serviceData.duration,
            price: serviceData.price,
            category: providerData.category,
            subcategory: serviceData.subcategory,
            capacity: serviceData.capacity || 1,
            isActive: true,
          });
          services.push(service.name);
        }

        // Set availability (Monday-Friday, 9 AM - 5 PM)
        const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
        for (const day of days) {
          db.createOrUpdateAvailability({
            providerId: provider.id,
            dayOfWeek: day,
            startTime: '09:00',
            endTime: '17:00',
            breaks: ['12:00-13:00'],
            isAvailable: true,
          });
        }

        // Add sample photos for each provider (using placeholder images)
        const categoryImages: { [key: string]: string[] } = {
          'Barber': [
            'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=800',
            'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=800',
            'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800',
          ],
          'Hair': [
            'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=800',
            'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=800',
            'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=800',
          ],
          'Beauty': [
            'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=800',
            'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800',
            'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=800',
          ],
          'Massage': [
            'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=800',
            'https://images.unsplash.com/photo-1600334129128-685c5582fd35?w=800',
            'https://images.unsplash.com/photo-1600334097273-4947fc4e0f50?w=800',
          ],
          'Fitness': [
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
            'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
            'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800',
          ],
          'Dental': [
            'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=800',
            'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800',
            'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800',
          ],
          'Therapy': [
            'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800',
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=800',
            'https://images.unsplash.com/photo-1559757175-0eb30cd8c063?w=800',
          ],
          'Medical': [
            'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=800',
            'https://images.unsplash.com/photo-1559757175-0eb30cd8c063?w=800',
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=800',
          ],
          'Home Services': [
            'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800',
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
            'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=800',
          ],
        };

        const images = categoryImages[providerData.category] || categoryImages['Beauty'];
        for (let i = 0; i < images.length; i++) {
          db.addProviderImage({
            providerId: provider.id,
            url: images[i],
            caption: `${providerData.name} - ${providerData.category} Service`,
            type: 'gallery',
            order: i,
          });
        }

        results.push({
          status: 'created',
          provider: providerData.name,
          email: providerData.email,
          services: services,
          images: images.length,
        });
        created++;
      } catch (error: any) {
        results.push({
          status: 'error',
          provider: providerData.name,
          error: error.message,
        });
      }
    }

    res.json({
      success: true,
      summary: {
        created,
        skipped,
        total: testProviders.length,
      },
      results,
      message: `Created ${created} test providers. ${skipped} already existed.`,
    });
  } catch (error: any) {
    res.status(500).json({ error: 'Server error', message: error.message });
  }
});

export default router;
