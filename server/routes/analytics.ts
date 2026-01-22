import express, { Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';

const router = express.Router();

// Provider analytics dashboard
router.get('/provider', authenticate, (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can access analytics' });
    }

    const providerId = req.userId!;
    const appointments = db.getAppointments(providerId, 'provider');
    const services = db.getServices(providerId);
    const payments = db.getPayments().filter(p => {
      const appointment = db.getAppointmentById(p.appointmentId);
      return appointment?.providerId === providerId;
    });

    // Calculate revenue
    const completedPayments = payments.filter(p => p.status === 'completed');
    const totalRevenue = completedPayments.reduce((sum, p) => sum + p.amount, 0);
    const providerEarnings = completedPayments.reduce((sum, p) => sum + (p.providerAmount || 0), 0);
    const platformCommission = completedPayments.reduce((sum, p) => sum + (p.platformCommission || 0), 0);

    // Appointment statistics
    const stats = {
      total: appointments.length,
      pending: appointments.filter(a => a.status === 'pending').length,
      confirmed: appointments.filter(a => a.status === 'confirmed').length,
      completed: appointments.filter(a => a.status === 'completed').length,
      cancelled: appointments.filter(a => a.status === 'cancelled').length,
    };

    // Revenue by month (last 6 months)
    const monthlyRevenue: { [key: string]: number } = {};
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

    completedPayments.forEach(payment => {
      const paymentDate = new Date(payment.createdAt);
      if (paymentDate >= sixMonthsAgo) {
        const monthKey = `${paymentDate.getFullYear()}-${String(paymentDate.getMonth() + 1).padStart(2, '0')}`;
        monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] || 0) + (payment.providerAmount || 0);
      }
    });

    // Popular services
    const serviceBookings: { [serviceId: string]: number } = {};
    appointments.forEach(apt => {
      if (apt.status !== 'cancelled') {
        serviceBookings[apt.serviceId] = (serviceBookings[apt.serviceId] || 0) + 1;
      }
    });

    const popularServices = services
      .map(service => ({
        service: {
          id: service.id,
          name: service.name,
          price: service.price,
        },
        bookings: serviceBookings[service.id] || 0,
        revenue: completedPayments
          .filter(p => {
            const apt = db.getAppointmentById(p.appointmentId);
            return apt?.serviceId === service.id;
          })
          .reduce((sum, p) => sum + (p.providerAmount || 0), 0),
      }))
      .sort((a, b) => b.bookings - a.bookings)
      .slice(0, 10);

    // Average booking value
    const avgBookingValue = completedPayments.length > 0
      ? totalRevenue / completedPayments.length
      : 0;

    // Cancellation rate
    const cancellationRate = appointments.length > 0
      ? (stats.cancelled / appointments.length) * 100
      : 0;

    res.json({
      revenue: {
        total: totalRevenue,
        providerEarnings,
        platformCommission,
        averageBookingValue: avgBookingValue,
      },
      appointments: stats,
      monthlyRevenue,
      popularServices,
      metrics: {
        totalServices: services.length,
        activeServices: services.filter(s => s.isActive).length,
        cancellationRate: Math.round(cancellationRate * 100) / 100,
        completionRate: appointments.length > 0
          ? Math.round((stats.completed / appointments.length) * 100 * 100) / 100
          : 0,
      },
    });
  } catch (error) {
    console.error('Analytics error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Customer analytics
router.get('/customer', authenticate, (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'customer') {
      return res.status(403).json({ error: 'Only customers can access analytics' });
    }

    const customerId = req.userId!;
    const appointments = db.getAppointments(customerId, 'customer');
    const payments = db.getPayments().filter(p => {
      const appointment = db.getAppointmentById(p.appointmentId);
      return appointment?.customerId === customerId;
    });

    const totalSpent = payments
      .filter(p => p.status === 'completed')
      .reduce((sum, p) => sum + p.amount, 0);

    const favoriteCategories: { [category: string]: number } = {};
    appointments.forEach(apt => {
      const service = db.getServiceById(apt.serviceId);
      if (service) {
        favoriteCategories[service.category] = (favoriteCategories[service.category] || 0) + 1;
      }
    });

    const topCategory = Object.entries(favoriteCategories)
      .sort(([, a], [, b]) => b - a)[0]?.[0] || null;

    res.json({
      totalAppointments: appointments.length,
      totalSpent,
      favoriteCategory: topCategory,
      upcomingAppointments: appointments.filter(a => {
        const aptDate = new Date(`${a.date}T${a.time}`);
        return aptDate > new Date() && a.status !== 'cancelled';
      }).length,
    });
  } catch (error) {
    console.error('Analytics error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
