import { Pool, QueryResult } from 'pg';
import { initializeDatabase } from './migrations';

// Database interfaces
export interface User {
  id: string;
  email: string;
  password: string;
  name: string;
  role: 'customer' | 'provider';
  phone?: string;
  latitude?: number;
  longitude?: number;
  address?: string;
  profilePicture?: string;
  stripeAccountId?: string; // Stripe Connect account ID for providers
  createdAt: string;
}

export interface Service {
  id: string;
  providerId: string;
  name: string;
  description: string;
  duration: number; // in minutes
  price: number;
  category: string;
}

export interface Appointment {
  id: string;
  customerId: string;
  providerId: string;
  serviceId: string;
  date: string;
  time: string;
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed';
  notes?: string;
  createdAt: string;
}

export interface Payment {
  id: string;
  appointmentId: string;
  amount: number;
  currency: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  paymentMethod: string;
  transactionId?: string;
  platformCommission: number;
  providerAmount: number;
  commissionRate: number;
  createdAt: string;
}

export interface Review {
  id: string;
  appointmentId: string;
  providerId: string;
  customerId: string;
  rating: number;
  comment: string;
  photos?: string[];
  createdAt: string;
}

// Initialize PostgreSQL connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Initialize database on first import
let dbInitialized = false;
const initPromise = initializeDatabase(pool).then(() => {
  dbInitialized = true;
}).catch((error) => {
  console.error('Failed to initialize database:', error);
  // In development, if DATABASE_URL is not set, we'll use JSON fallback
  if (!process.env.DATABASE_URL) {
    console.warn('⚠️  DATABASE_URL not set. Database operations will fail. Set DATABASE_URL to use PostgreSQL.');
  }
});

// Helper function to ensure DB is initialized
async function ensureInitialized(): Promise<void> {
  if (!dbInitialized) {
    await initPromise;
  }
}

// Helper function to map database rows to User objects
function mapUser(row: any): User {
  return {
    id: row.id,
    email: row.email,
    password: row.password,
    name: row.name,
    role: row.role,
    phone: row.phone || undefined,
    latitude: row.latitude ? parseFloat(row.latitude) : undefined,
    longitude: row.longitude ? parseFloat(row.longitude) : undefined,
    address: row.address || undefined,
    profilePicture: row.profile_picture || undefined,
    stripeAccountId: row.stripe_account_id || undefined,
    createdAt: row.created_at.toISOString(),
  };
}

// Helper function to map database rows to Service objects
function mapService(row: any): Service {
  return {
    id: row.id,
    providerId: row.provider_id,
    name: row.name,
    description: row.description,
    duration: parseInt(row.duration),
    price: parseFloat(row.price),
    category: row.category,
  };
}

// Helper function to map database rows to Appointment objects
function mapAppointment(row: any): Appointment {
  return {
    id: row.id,
    customerId: row.customer_id,
    providerId: row.provider_id,
    serviceId: row.service_id,
    date: row.date,
    time: row.time,
    status: row.status,
    notes: row.notes || undefined,
    createdAt: row.created_at.toISOString(),
  };
}

// Helper function to map database rows to Payment objects
function mapPayment(row: any): Payment {
  return {
    id: row.id,
    appointmentId: row.appointment_id,
    amount: parseFloat(row.amount),
    currency: row.currency,
    status: row.status,
    paymentMethod: row.payment_method,
    transactionId: row.transaction_id || undefined,
    platformCommission: parseFloat(row.platform_commission || 0),
    providerAmount: parseFloat(row.provider_amount || 0),
    commissionRate: parseFloat(row.commission_rate || 15.00),
    createdAt: row.created_at.toISOString(),
  };
}

// Helper function to map database rows to Review objects
function mapReview(row: any): Review {
  return {
    id: row.id,
    appointmentId: row.appointment_id,
    providerId: row.provider_id,
    customerId: row.customer_id,
    rating: parseInt(row.rating),
    comment: row.comment,
    photos: row.photos || undefined,
    createdAt: row.created_at.toISOString(),
  };
}

export const db = {
  // User methods
  getUsers: async (): Promise<User[]> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
    return result.rows.map(mapUser);
  },

  getUserById: async (id: string): Promise<User | undefined> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
    return result.rows.length > 0 ? mapUser(result.rows[0]) : undefined;
  },

  getUserByEmail: async (email: string): Promise<User | undefined> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    return result.rows.length > 0 ? mapUser(result.rows[0]) : undefined;
  },

  createUser: async (user: Omit<User, 'id' | 'createdAt'>): Promise<User> => {
    await ensureInitialized();
    const id = Date.now().toString();
    const result = await pool.query(
      `INSERT INTO users (id, email, password, name, role, phone, latitude, longitude, address, profile_picture, stripe_account_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       RETURNING *`,
      [
        id,
        user.email,
        user.password,
        user.name,
        user.role,
        user.phone || null,
        user.latitude || null,
        user.longitude || null,
        user.address || null,
        user.profilePicture || null,
        user.stripeAccountId || null,
      ]
    );
    return mapUser(result.rows[0]);
  },

  updateUser: async (id: string, updates: Partial<User>): Promise<User | null> => {
    await ensureInitialized();
    const fields: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    if (updates.email !== undefined) {
      fields.push(`email = $${paramCount++}`);
      values.push(updates.email);
    }
    if (updates.password !== undefined) {
      fields.push(`password = $${paramCount++}`);
      values.push(updates.password);
    }
    if (updates.name !== undefined) {
      fields.push(`name = $${paramCount++}`);
      values.push(updates.name);
    }
    if (updates.role !== undefined) {
      fields.push(`role = $${paramCount++}`);
      values.push(updates.role);
    }
    if (updates.phone !== undefined) {
      fields.push(`phone = $${paramCount++}`);
      values.push(updates.phone || null);
    }
    if (updates.latitude !== undefined) {
      fields.push(`latitude = $${paramCount++}`);
      values.push(updates.latitude || null);
    }
    if (updates.longitude !== undefined) {
      fields.push(`longitude = $${paramCount++}`);
      values.push(updates.longitude || null);
    }
    if (updates.address !== undefined) {
      fields.push(`address = $${paramCount++}`);
      values.push(updates.address || null);
    }
    if (updates.profilePicture !== undefined) {
      fields.push(`profile_picture = $${paramCount++}`);
      values.push(updates.profilePicture || null);
    }

    if (fields.length === 0) {
      return await db.getUserById(id) || null;
    }

    values.push(id);
    const result = await pool.query(
      `UPDATE users SET ${fields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
      values
    );
    return result.rows.length > 0 ? mapUser(result.rows[0]) : null;
  },

  // Service methods
  getServices: async (providerId?: string): Promise<Service[]> => {
    await ensureInitialized();
    if (providerId) {
      const result = await pool.query('SELECT * FROM services WHERE provider_id = $1 ORDER BY name', [providerId]);
      return result.rows.map(mapService);
    }
    const result = await pool.query('SELECT * FROM services ORDER BY name');
    return result.rows.map(mapService);
  },

  getServiceById: async (id: string): Promise<Service | undefined> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM services WHERE id = $1', [id]);
    return result.rows.length > 0 ? mapService(result.rows[0]) : undefined;
  },

  createService: async (service: Omit<Service, 'id'>): Promise<Service> => {
    await ensureInitialized();
    const id = Date.now().toString();
    const result = await pool.query(
      `INSERT INTO services (id, provider_id, name, description, duration, price, category)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [id, service.providerId, service.name, service.description, service.duration, service.price, service.category]
    );
    return mapService(result.rows[0]);
  },

  updateService: async (id: string, updates: Partial<Service>): Promise<Service | null> => {
    await ensureInitialized();
    const fields: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    if (updates.providerId !== undefined) {
      fields.push(`provider_id = $${paramCount++}`);
      values.push(updates.providerId);
    }
    if (updates.name !== undefined) {
      fields.push(`name = $${paramCount++}`);
      values.push(updates.name);
    }
    if (updates.description !== undefined) {
      fields.push(`description = $${paramCount++}`);
      values.push(updates.description);
    }
    if (updates.duration !== undefined) {
      fields.push(`duration = $${paramCount++}`);
      values.push(updates.duration);
    }
    if (updates.price !== undefined) {
      fields.push(`price = $${paramCount++}`);
      values.push(updates.price);
    }
    if (updates.category !== undefined) {
      fields.push(`category = $${paramCount++}`);
      values.push(updates.category);
    }

    if (fields.length === 0) {
      return await db.getServiceById(id) || null;
    }

    values.push(id);
    const result = await pool.query(
      `UPDATE services SET ${fields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
      values
    );
    return result.rows.length > 0 ? mapService(result.rows[0]) : null;
  },

  deleteService: async (id: string): Promise<boolean> => {
    await ensureInitialized();
    const result = await pool.query('DELETE FROM services WHERE id = $1', [id]);
    return result.rowCount !== null && result.rowCount > 0;
  },

  // Appointment methods
  getAppointments: async (userId?: string, role?: 'customer' | 'provider'): Promise<Appointment[]> => {
    await ensureInitialized();
    if (userId && role === 'customer') {
      const result = await pool.query(
        'SELECT * FROM appointments WHERE customer_id = $1 ORDER BY date DESC, time DESC',
        [userId]
      );
      return result.rows.map(mapAppointment);
    }
    if (userId && role === 'provider') {
      const result = await pool.query(
        'SELECT * FROM appointments WHERE provider_id = $1 ORDER BY date DESC, time DESC',
        [userId]
      );
      return result.rows.map(mapAppointment);
    }
    const result = await pool.query('SELECT * FROM appointments ORDER BY date DESC, time DESC');
    return result.rows.map(mapAppointment);
  },

  getAppointmentById: async (id: string): Promise<Appointment | undefined> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM appointments WHERE id = $1', [id]);
    return result.rows.length > 0 ? mapAppointment(result.rows[0]) : undefined;
  },

  createAppointment: async (appointment: Omit<Appointment, 'id' | 'createdAt'>): Promise<Appointment> => {
    await ensureInitialized();
    const id = Date.now().toString();
    const result = await pool.query(
      `INSERT INTO appointments (id, customer_id, provider_id, service_id, date, time, status, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        id,
        appointment.customerId,
        appointment.providerId,
        appointment.serviceId,
        appointment.date,
        appointment.time,
        appointment.status,
        appointment.notes || null,
      ]
    );
    return mapAppointment(result.rows[0]);
  },

  updateAppointment: async (id: string, updates: Partial<Appointment>): Promise<Appointment | null> => {
    await ensureInitialized();
    const fields: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    if (updates.customerId !== undefined) {
      fields.push(`customer_id = $${paramCount++}`);
      values.push(updates.customerId);
    }
    if (updates.providerId !== undefined) {
      fields.push(`provider_id = $${paramCount++}`);
      values.push(updates.providerId);
    }
    if (updates.serviceId !== undefined) {
      fields.push(`service_id = $${paramCount++}`);
      values.push(updates.serviceId);
    }
    if (updates.date !== undefined) {
      fields.push(`date = $${paramCount++}`);
      values.push(updates.date);
    }
    if (updates.time !== undefined) {
      fields.push(`time = $${paramCount++}`);
      values.push(updates.time);
    }
    if (updates.status !== undefined) {
      fields.push(`status = $${paramCount++}`);
      values.push(updates.status);
    }
    if (updates.notes !== undefined) {
      fields.push(`notes = $${paramCount++}`);
      values.push(updates.notes || null);
    }

    if (fields.length === 0) {
      return await db.getAppointmentById(id) || null;
    }

    values.push(id);
    const result = await pool.query(
      `UPDATE appointments SET ${fields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
      values
    );
    return result.rows.length > 0 ? mapAppointment(result.rows[0]) : null;
  },

  deleteAppointment: async (id: string): Promise<boolean> => {
    await ensureInitialized();
    const result = await pool.query('DELETE FROM appointments WHERE id = $1', [id]);
    return result.rowCount !== null && result.rowCount > 0;
  },

  // Payment methods
  getPayments: async (): Promise<Payment[]> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM payments ORDER BY created_at DESC');
    return result.rows.map(mapPayment);
  },

  getPaymentById: async (id: string): Promise<Payment | undefined> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM payments WHERE id = $1', [id]);
    return result.rows.length > 0 ? mapPayment(result.rows[0]) : undefined;
  },

  getPaymentsByUserId: async (userId: string): Promise<Payment[]> => {
    await ensureInitialized();
    const result = await pool.query(
      `SELECT p.* FROM payments p
       INNER JOIN appointments a ON p.appointment_id = a.id
       WHERE a.customer_id = $1
       ORDER BY p.created_at DESC`,
      [userId]
    );
    return result.rows.map(mapPayment);
  },

  createPayment: async (payment: Omit<Payment, 'id' | 'createdAt'>): Promise<Payment> => {
    await ensureInitialized();
    const id = Date.now().toString();
    const commissionRate = payment.commissionRate || 15.00;
    const platformCommission = (payment.amount * commissionRate) / 100;
    const providerAmount = payment.amount - platformCommission;
    
    const result = await pool.query(
      `INSERT INTO payments (id, appointment_id, amount, currency, status, payment_method, transaction_id, platform_commission, provider_amount, commission_rate)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [
        id,
        payment.appointmentId,
        payment.amount,
        payment.currency,
        payment.status,
        payment.paymentMethod,
        payment.transactionId || null,
        platformCommission,
        providerAmount,
        commissionRate,
      ]
    );
    return mapPayment(result.rows[0]);
  },

  updatePayment: async (id: string, updates: Partial<Payment>): Promise<Payment | null> => {
    await ensureInitialized();
    const fields: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    if (updates.appointmentId !== undefined) {
      fields.push(`appointment_id = $${paramCount++}`);
      values.push(updates.appointmentId);
    }
    if (updates.amount !== undefined) {
      fields.push(`amount = $${paramCount++}`);
      values.push(updates.amount);
    }
    if (updates.currency !== undefined) {
      fields.push(`currency = $${paramCount++}`);
      values.push(updates.currency);
    }
    if (updates.status !== undefined) {
      fields.push(`status = $${paramCount++}`);
      values.push(updates.status);
    }
    if (updates.paymentMethod !== undefined) {
      fields.push(`payment_method = $${paramCount++}`);
      values.push(updates.paymentMethod);
    }
    if (updates.transactionId !== undefined) {
      fields.push(`transaction_id = $${paramCount++}`);
      values.push(updates.transactionId || null);
    }
    if (updates.platformCommission !== undefined) {
      fields.push(`platform_commission = $${paramCount++}`);
      values.push(updates.platformCommission);
    }
    if (updates.providerAmount !== undefined) {
      fields.push(`provider_amount = $${paramCount++}`);
      values.push(updates.providerAmount);
    }
    if (updates.commissionRate !== undefined) {
      fields.push(`commission_rate = $${paramCount++}`);
      values.push(updates.commissionRate);
    }
    // If amount changes, recalculate commission
    if (updates.amount !== undefined) {
      const currentPayment = await db.getPaymentById(id);
      if (currentPayment) {
        const commissionRate = currentPayment.commissionRate || 15.00;
        const platformCommission = (updates.amount * commissionRate) / 100;
        const providerAmount = updates.amount - platformCommission;
        fields.push(`platform_commission = $${paramCount++}`);
        values.push(platformCommission);
        fields.push(`provider_amount = $${paramCount++}`);
        values.push(providerAmount);
      }
    }

    if (fields.length === 0) {
      return await db.getPaymentById(id) || null;
    }

    values.push(id);
    const result = await pool.query(
      `UPDATE payments SET ${fields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
      values
    );
    return result.rows.length > 0 ? mapPayment(result.rows[0]) : null;
  },

  // Review methods
  getReviews: async (): Promise<Review[]> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM reviews ORDER BY created_at DESC');
    return result.rows.map(mapReview);
  },

  getReviewById: async (id: string): Promise<Review | undefined> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM reviews WHERE id = $1', [id]);
    return result.rows.length > 0 ? mapReview(result.rows[0]) : undefined;
  },

  getReviewsByProviderId: async (providerId: string): Promise<Review[]> => {
    await ensureInitialized();
    const result = await pool.query(
      'SELECT * FROM reviews WHERE provider_id = $1 ORDER BY created_at DESC',
      [providerId]
    );
    return result.rows.map(mapReview);
  },

  createReview: async (review: Omit<Review, 'id' | 'createdAt'>): Promise<Review> => {
    await ensureInitialized();
    const id = Date.now().toString();
    const result = await pool.query(
      `INSERT INTO reviews (id, appointment_id, provider_id, customer_id, rating, comment, photos)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        id,
        review.appointmentId,
        review.providerId,
        review.customerId,
        review.rating,
        review.comment,
        review.photos || null,
      ]
    );
    return mapReview(result.rows[0]);
  },

  updateReview: async (id: string, updates: Partial<Review>): Promise<Review | null> => {
    await ensureInitialized();
    const fields: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    if (updates.appointmentId !== undefined) {
      fields.push(`appointment_id = $${paramCount++}`);
      values.push(updates.appointmentId);
    }
    if (updates.providerId !== undefined) {
      fields.push(`provider_id = $${paramCount++}`);
      values.push(updates.providerId);
    }
    if (updates.customerId !== undefined) {
      fields.push(`customer_id = $${paramCount++}`);
      values.push(updates.customerId);
    }
    if (updates.rating !== undefined) {
      fields.push(`rating = $${paramCount++}`);
      values.push(updates.rating);
    }
    if (updates.comment !== undefined) {
      fields.push(`comment = $${paramCount++}`);
      values.push(updates.comment);
    }
    if (updates.photos !== undefined) {
      fields.push(`photos = $${paramCount++}`);
      values.push(updates.photos || null);
    }

    if (fields.length === 0) {
      return await db.getReviewById(id) || null;
    }

    values.push(id);
    const result = await pool.query(
      `UPDATE reviews SET ${fields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
      values
    );
    return result.rows.length > 0 ? mapReview(result.rows[0]) : null;
  },

  deleteReview: async (id: string): Promise<boolean> => {
    await ensureInitialized();
    const result = await pool.query('DELETE FROM reviews WHERE id = $1', [id]);
    return result.rowCount !== null && result.rowCount > 0;
  },

  // Provider rating methods
  updateProviderRating: async (providerId: string): Promise<void> => {
    // This is now calculated on the fly in the API, so we don't need to store it
    // But we keep this method for compatibility
    await ensureInitialized();
  },
};

// Graceful shutdown
process.on('SIGINT', async () => {
  await pool.end();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await pool.end();
  process.exit(0);
});
