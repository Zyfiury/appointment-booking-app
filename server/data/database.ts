import { Pool, QueryResult } from 'pg';
import { initializeDatabase } from './migrations';

// Database interfaces
export interface Customer {
  id: string;
  email: string;
  password: string;
  name: string;
  phone?: string;
  profilePicture?: string;
  createdAt: string;
}

export interface Provider {
  id: string;
  email: string;
  password: string;
  name: string;
  phone?: string;
  latitude?: number;
  longitude?: number;
  address?: string;
  profilePicture?: string;
  stripeAccountId?: string; // Stripe Connect account ID for providers
  createdAt: string;
}

// Legacy User interface for backward compatibility (used in auth)
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
  stripeAccountId?: string;
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
  capacity: number; // Number of concurrent appointments allowed (default: 1)
}

export interface Availability {
  id: string;
  providerId: string;
  dayOfWeek: string; // 'monday', 'tuesday', etc.
  startTime: string; // '09:00'
  endTime: string; // '17:00'
  breaks: string[]; // ['12:00-13:00'] - lunch breaks
  isAvailable: boolean;
}

export interface AvailabilityException {
  id: string;
  providerId: string;
  date: string; // yyyy-mm-dd
  startTime?: string; // '09:00' (optional if day off)
  endTime?: string; // '17:00'
  breaks: string[];
  isAvailable: boolean; // false = day off
  note?: string;
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

// Helper function to map database rows to Customer objects
function mapCustomer(row: any): Customer {
  return {
    id: row.id,
    email: row.email,
    password: row.password,
    name: row.name,
    phone: row.phone || undefined,
    profilePicture: row.profile_picture || undefined,
    createdAt: row.created_at.toISOString(),
  };
}

// Helper function to map database rows to Provider objects
function mapProvider(row: any): Provider {
  return {
    id: row.id,
    email: row.email,
    password: row.password,
    name: row.name,
    phone: row.phone || undefined,
    latitude: row.latitude ? parseFloat(row.latitude) : undefined,
    longitude: row.longitude ? parseFloat(row.longitude) : undefined,
    address: row.address || undefined,
    profilePicture: row.profile_picture || undefined,
    stripeAccountId: row.stripe_account_id || undefined,
    createdAt: row.created_at.toISOString(),
  };
}

// Helper function to map Customer/Provider to User (for backward compatibility)
function customerToUser(customer: Customer, role: 'customer' | 'provider' = 'customer'): User {
  return {
    ...customer,
    role,
    latitude: undefined,
    longitude: undefined,
    address: undefined,
    stripeAccountId: undefined,
  };
}

function providerToUser(provider: Provider, role: 'customer' | 'provider' = 'provider'): User {
  return {
    ...provider,
    role,
  };
}

// Helper function to map database rows to User objects (for backward compatibility)
// Checks both customers and providers tables
function mapUser(row: any, role?: 'customer' | 'provider'): User {
  if (role === 'provider' || row.latitude !== undefined || row.stripe_account_id !== undefined) {
    return providerToUser(mapProvider(row), 'provider');
  }
  return customerToUser(mapCustomer(row), 'customer');
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
    capacity: row.capacity ? parseInt(row.capacity) : 1,
  };
}

function mapAvailability(row: any): Availability {
  return {
    id: row.id,
    providerId: row.provider_id,
    dayOfWeek: row.day_of_week,
    startTime: row.start_time,
    endTime: row.end_time,
    breaks: row.breaks || [],
    isAvailable: row.is_available !== false,
  };
}

function mapAvailabilityException(row: any): AvailabilityException {
  return {
    id: row.id,
    providerId: row.provider_id,
    date: row.date,
    startTime: row.start_time || undefined,
    endTime: row.end_time || undefined,
    breaks: row.breaks || [],
    isAvailable: row.is_available !== false,
    note: row.note || undefined,
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
  // Customer methods
  getCustomers: async (): Promise<Customer[]> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM customers ORDER BY created_at DESC');
    return result.rows.map(mapCustomer);
  },

  getCustomerById: async (id: string): Promise<Customer | undefined> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM customers WHERE id = $1', [id]);
    return result.rows.length > 0 ? mapCustomer(result.rows[0]) : undefined;
  },

  getCustomerByEmail: async (email: string): Promise<Customer | undefined> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM customers WHERE email = $1', [email]);
    return result.rows.length > 0 ? mapCustomer(result.rows[0]) : undefined;
  },

  createCustomer: async (customer: Omit<Customer, 'id' | 'createdAt'>): Promise<Customer> => {
    await ensureInitialized();
    const id = Date.now().toString();
    const result = await pool.query(
      `INSERT INTO customers (id, email, password, name, phone, profile_picture)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        id,
        customer.email,
        customer.password,
        customer.name,
        customer.phone || null,
        customer.profilePicture || null,
      ]
    );
    return mapCustomer(result.rows[0]);
  },

  updateCustomer: async (id: string, updates: Partial<Customer>): Promise<Customer | null> => {
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
    if (updates.phone !== undefined) {
      fields.push(`phone = $${paramCount++}`);
      values.push(updates.phone || null);
    }
    if (updates.profilePicture !== undefined) {
      fields.push(`profile_picture = $${paramCount++}`);
      values.push(updates.profilePicture || null);
    }

    if (fields.length === 0) {
      return await db.getCustomerById(id) || null;
    }

    values.push(id);
    const result = await pool.query(
      `UPDATE customers SET ${fields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
      values
    );
    return result.rows.length > 0 ? mapCustomer(result.rows[0]) : null;
  },

  // Provider methods
  getProviders: async (): Promise<Provider[]> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM providers ORDER BY created_at DESC');
    return result.rows.map(mapProvider);
  },

  getProviderById: async (id: string): Promise<Provider | undefined> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM providers WHERE id = $1', [id]);
    return result.rows.length > 0 ? mapProvider(result.rows[0]) : undefined;
  },

  getProviderByEmail: async (email: string): Promise<Provider | undefined> => {
    await ensureInitialized();
    const result = await pool.query('SELECT * FROM providers WHERE email = $1', [email]);
    return result.rows.length > 0 ? mapProvider(result.rows[0]) : undefined;
  },

  createProvider: async (provider: Omit<Provider, 'id' | 'createdAt'>): Promise<Provider> => {
    await ensureInitialized();
    const id = Date.now().toString();
    const result = await pool.query(
      `INSERT INTO providers (id, email, password, name, phone, latitude, longitude, address, profile_picture, stripe_account_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [
        id,
        provider.email,
        provider.password,
        provider.name,
        provider.phone || null,
        provider.latitude || null,
        provider.longitude || null,
        provider.address || null,
        provider.profilePicture || null,
        provider.stripeAccountId || null,
      ]
    );
    return mapProvider(result.rows[0]);
  },

  updateProvider: async (id: string, updates: Partial<Provider>): Promise<Provider | null> => {
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
    if (updates.stripeAccountId !== undefined) {
      fields.push(`stripe_account_id = $${paramCount++}`);
      values.push(updates.stripeAccountId || null);
    }

    if (fields.length === 0) {
      return await db.getProviderById(id) || null;
    }

    values.push(id);
    const result = await pool.query(
      `UPDATE providers SET ${fields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
      values
    );
    return result.rows.length > 0 ? mapProvider(result.rows[0]) : null;
  },

  // User methods (backward compatibility - checks both tables)
  getUsers: async (): Promise<User[]> => {
    await ensureInitialized();
    const customers = await pool.query('SELECT * FROM customers');
    const providers = await pool.query('SELECT * FROM providers');
    return [
      ...customers.rows.map(row => customerToUser(mapCustomer(row), 'customer')),
      ...providers.rows.map(row => providerToUser(mapProvider(row), 'provider')),
    ];
  },

  getUserById: async (id: string): Promise<User | undefined> => {
    await ensureInitialized();
    // Check customers first
    let result = await pool.query('SELECT * FROM customers WHERE id = $1', [id]);
    if (result.rows.length > 0) {
      return customerToUser(mapCustomer(result.rows[0]), 'customer');
    }
    // Check providers
    result = await pool.query('SELECT * FROM providers WHERE id = $1', [id]);
    if (result.rows.length > 0) {
      return providerToUser(mapProvider(result.rows[0]), 'provider');
    }
    return undefined;
  },

  getUserByEmail: async (email: string): Promise<User | undefined> => {
    await ensureInitialized();
    // Check customers first
    let result = await pool.query('SELECT * FROM customers WHERE email = $1', [email]);
    if (result.rows.length > 0) {
      return customerToUser(mapCustomer(result.rows[0]), 'customer');
    }
    // Check providers
    result = await pool.query('SELECT * FROM providers WHERE email = $1', [email]);
    if (result.rows.length > 0) {
      return providerToUser(mapProvider(result.rows[0]), 'provider');
    }
    return undefined;
  },

  createUser: async (user: Omit<User, 'id' | 'createdAt'>): Promise<User> => {
    await ensureInitialized();
    if (user.role === 'customer') {
      const customer = await db.createCustomer({
        email: user.email,
        password: user.password,
        name: user.name,
        phone: user.phone,
        profilePicture: user.profilePicture,
      });
      return customerToUser(customer, 'customer');
    } else {
      const provider = await db.createProvider({
        email: user.email,
        password: user.password,
        name: user.name,
        phone: user.phone,
        latitude: user.latitude,
        longitude: user.longitude,
        address: user.address,
        profilePicture: user.profilePicture,
        stripeAccountId: user.stripeAccountId,
      });
      return providerToUser(provider, 'provider');
    }
  },

  updateUser: async (id: string, updates: Partial<User>): Promise<User | null> => {
    await ensureInitialized();
    // First, check if user exists and determine their type
    const existingUser = await db.getUserById(id);
    if (!existingUser) {
      return null;
    }

    // Handle role change (not supported - user stays in their table)
    if (updates.role !== undefined && updates.role !== existingUser.role) {
      throw new Error('Cannot change user role. User must remain in their original table.');
    }

    // Update in the appropriate table
    if (existingUser.role === 'customer') {
      const customerUpdates: Partial<Customer> = {};
      if (updates.email !== undefined) customerUpdates.email = updates.email;
      if (updates.password !== undefined) customerUpdates.password = updates.password;
      if (updates.name !== undefined) customerUpdates.name = updates.name;
      if (updates.phone !== undefined) customerUpdates.phone = updates.phone;
      if (updates.profilePicture !== undefined) customerUpdates.profilePicture = updates.profilePicture;

      const updated = await db.updateCustomer(id, customerUpdates);
      return updated ? customerToUser(updated, 'customer') : null;
    } else {
      const providerUpdates: Partial<Provider> = {};
      if (updates.email !== undefined) providerUpdates.email = updates.email;
      if (updates.password !== undefined) providerUpdates.password = updates.password;
      if (updates.name !== undefined) providerUpdates.name = updates.name;
      if (updates.phone !== undefined) providerUpdates.phone = updates.phone;
      if (updates.latitude !== undefined) providerUpdates.latitude = updates.latitude;
      if (updates.longitude !== undefined) providerUpdates.longitude = updates.longitude;
      if (updates.address !== undefined) providerUpdates.address = updates.address;
      if (updates.profilePicture !== undefined) providerUpdates.profilePicture = updates.profilePicture;
      if (updates.stripeAccountId !== undefined) providerUpdates.stripeAccountId = updates.stripeAccountId;

      const updated = await db.updateProvider(id, providerUpdates);
      return updated ? providerToUser(updated, 'provider') : null;
    }
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
    const capacity = service.capacity || 1;
    const result = await pool.query(
      `INSERT INTO services (id, provider_id, name, description, duration, price, category, capacity)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [id, service.providerId, service.name, service.description, service.duration, service.price, service.category, capacity]
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
    if (updates.capacity !== undefined) {
      fields.push(`capacity = $${paramCount++}`);
      values.push(updates.capacity);
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

  // Availability methods
  getAvailability: async (providerId: string): Promise<Availability[]> => {
    await ensureInitialized();
    const result = await pool.query(
      'SELECT * FROM availability WHERE provider_id = $1 ORDER BY day_of_week',
      [providerId]
    );
    return result.rows.map(mapAvailability);
  },

  getAvailabilityByDay: async (providerId: string, dayOfWeek: string): Promise<Availability | undefined> => {
    await ensureInitialized();
    const result = await pool.query(
      'SELECT * FROM availability WHERE provider_id = $1 AND day_of_week = $2',
      [providerId, dayOfWeek.toLowerCase()]
    );
    return result.rows.length > 0 ? mapAvailability(result.rows[0]) : undefined;
  },

  createOrUpdateAvailability: async (availability: Omit<Availability, 'id'>): Promise<Availability> => {
    await ensureInitialized();
    // Check if exists
    const existing = await pool.query(
      'SELECT id FROM availability WHERE provider_id = $1 AND day_of_week = $2',
      [availability.providerId, availability.dayOfWeek.toLowerCase()]
    );

    if (existing.rows.length > 0) {
      // Update existing
      const id = existing.rows[0].id;
      const result = await pool.query(
        `UPDATE availability 
         SET start_time = $1, end_time = $2, breaks = $3, is_available = $4
         WHERE id = $5
         RETURNING *`,
        [availability.startTime, availability.endTime, availability.breaks, availability.isAvailable, id]
      );
      return mapAvailability(result.rows[0]);
    } else {
      // Create new
      const id = Date.now().toString();
      const result = await pool.query(
        `INSERT INTO availability (id, provider_id, day_of_week, start_time, end_time, breaks, is_available)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [id, availability.providerId, availability.dayOfWeek.toLowerCase(), availability.startTime, availability.endTime, availability.breaks, availability.isAvailable]
      );
      return mapAvailability(result.rows[0]);
    }
  },

  deleteAvailability: async (id: string): Promise<boolean> => {
    await ensureInitialized();
    const result = await pool.query('DELETE FROM availability WHERE id = $1', [id]);
    return result.rowCount !== null && result.rowCount > 0;
  },

  // Availability exception methods (date-specific overrides)
  getAvailabilityExceptions: async (providerId: string): Promise<AvailabilityException[]> => {
    await ensureInitialized();
    const result = await pool.query(
      'SELECT * FROM availability_exceptions WHERE provider_id = $1 ORDER BY date DESC',
      [providerId]
    );
    return result.rows.map(mapAvailabilityException);
  },

  getAvailabilityExceptionByDate: async (
    providerId: string,
    date: string
  ): Promise<AvailabilityException | undefined> => {
    await ensureInitialized();
    const result = await pool.query(
      'SELECT * FROM availability_exceptions WHERE provider_id = $1 AND date = $2',
      [providerId, date]
    );
    return result.rows.length > 0 ? mapAvailabilityException(result.rows[0]) : undefined;
  },

  createOrUpdateAvailabilityException: async (
    ex: Omit<AvailabilityException, 'id'>
  ): Promise<AvailabilityException> => {
    await ensureInitialized();
    const existing = await pool.query(
      'SELECT id FROM availability_exceptions WHERE provider_id = $1 AND date = $2',
      [ex.providerId, ex.date]
    );

    if (existing.rows.length > 0) {
      const id = existing.rows[0].id;
      const result = await pool.query(
        `UPDATE availability_exceptions
         SET start_time = $1, end_time = $2, breaks = $3, is_available = $4, note = $5
         WHERE id = $6
         RETURNING *`,
        [ex.startTime || null, ex.endTime || null, ex.breaks, ex.isAvailable, ex.note || null, id]
      );
      return mapAvailabilityException(result.rows[0]);
    }

    const id = Date.now().toString();
    const result = await pool.query(
      `INSERT INTO availability_exceptions (id, provider_id, date, start_time, end_time, breaks, is_available, note)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [id, ex.providerId, ex.date, ex.startTime || null, ex.endTime || null, ex.breaks, ex.isAvailable, ex.note || null]
    );
    return mapAvailabilityException(result.rows[0]);
  },

  deleteAvailabilityException: async (id: string): Promise<boolean> => {
    await ensureInitialized();
    const result = await pool.query('DELETE FROM availability_exceptions WHERE id = $1', [id]);
    return result.rowCount !== null && result.rowCount > 0;
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
