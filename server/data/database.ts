import { writeFileSync, readFileSync, existsSync, mkdirSync } from 'fs';
import { join } from 'path';

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

interface Database {
  users: User[];
  services: Service[];
  appointments: Appointment[];
  payments: Payment[];
  reviews: Review[];
}

// Ensure the data directory exists
const DATA_DIR = join(__dirname);
const DB_PATH = join(DATA_DIR, 'db.json');

// Create data directory if it doesn't exist
if (!existsSync(DATA_DIR)) {
  mkdirSync(DATA_DIR, { recursive: true });
}

function loadDatabase(): Database {
  if (existsSync(DB_PATH)) {
    const data = readFileSync(DB_PATH, 'utf-8');
    const parsed = JSON.parse(data);
    // Ensure all arrays exist
    return {
      users: parsed.users || [],
      services: parsed.services || [],
      appointments: parsed.appointments || [],
      payments: parsed.payments || [],
      reviews: parsed.reviews || [],
    };
  }
  return { users: [], services: [], appointments: [], payments: [], reviews: [] };
}

function saveDatabase(db: Database): void {
  writeFileSync(DB_PATH, JSON.stringify(db, null, 2));
}

export const db = {
  getUsers: (): User[] => loadDatabase().users,
  getUserById: (id: string): User | undefined => {
    return loadDatabase().users.find(u => u.id === id);
  },
  getUserByEmail: (email: string): User | undefined => {
    return loadDatabase().users.find(u => u.email === email);
  },
  createUser: (user: Omit<User, 'id' | 'createdAt'>): User => {
    const db = loadDatabase();
    const newUser: User = {
      ...user,
      id: Date.now().toString(),
      createdAt: new Date().toISOString(),
    };
    db.users.push(newUser);
    saveDatabase(db);
    return newUser;
  },
  updateUser: (id: string, updates: Partial<User>): User | null => {
    const db = loadDatabase();
    const index = db.users.findIndex(u => u.id === id);
    if (index === -1) return null;
    db.users[index] = { ...db.users[index], ...updates };
    saveDatabase(db);
    return db.users[index];
  },
  getServices: (providerId?: string): Service[] => {
    const db = loadDatabase();
    if (providerId) {
      return db.services.filter(s => s.providerId === providerId);
    }
    return db.services;
  },
  getServiceById: (id: string): Service | undefined => {
    return loadDatabase().services.find(s => s.id === id);
  },
  createService: (service: Omit<Service, 'id'>): Service => {
    const db = loadDatabase();
    const newService: Service = {
      ...service,
      id: Date.now().toString(),
    };
    db.services.push(newService);
    saveDatabase(db);
    return newService;
  },
  updateService: (id: string, updates: Partial<Service>): Service | null => {
    const db = loadDatabase();
    const index = db.services.findIndex(s => s.id === id);
    if (index === -1) return null;
    db.services[index] = { ...db.services[index], ...updates };
    saveDatabase(db);
    return db.services[index];
  },
  deleteService: (id: string): boolean => {
    const db = loadDatabase();
    const index = db.services.findIndex(s => s.id === id);
    if (index === -1) return false;
    db.services.splice(index, 1);
    saveDatabase(db);
    return true;
  },
  getAppointments: (userId?: string, role?: 'customer' | 'provider'): Appointment[] => {
    const db = loadDatabase();
    if (userId && role === 'customer') {
      return db.appointments.filter(a => a.customerId === userId);
    }
    if (userId && role === 'provider') {
      return db.appointments.filter(a => a.providerId === userId);
    }
    return db.appointments;
  },
  getAppointmentById: (id: string): Appointment | undefined => {
    return loadDatabase().appointments.find(a => a.id === id);
  },
  createAppointment: (appointment: Omit<Appointment, 'id' | 'createdAt'>): Appointment => {
    const db = loadDatabase();
    const newAppointment: Appointment = {
      ...appointment,
      id: Date.now().toString(),
      createdAt: new Date().toISOString(),
    };
    db.appointments.push(newAppointment);
    saveDatabase(db);
    return newAppointment;
  },
  updateAppointment: (id: string, updates: Partial<Appointment>): Appointment | null => {
    const db = loadDatabase();
    const index = db.appointments.findIndex(a => a.id === id);
    if (index === -1) return null;
    db.appointments[index] = { ...db.appointments[index], ...updates };
    saveDatabase(db);
    return db.appointments[index];
  },
  deleteAppointment: (id: string): boolean => {
    const db = loadDatabase();
    const index = db.appointments.findIndex(a => a.id === id);
    if (index === -1) return false;
    db.appointments.splice(index, 1);
    saveDatabase(db);
    return true;
  },
  // Payment methods
  getPayments: (): Payment[] => loadDatabase().payments,
  getPaymentById: (id: string): Payment | undefined => {
    return loadDatabase().payments.find(p => p.id === id);
  },
  createPayment: (payment: Omit<Payment, 'id' | 'createdAt'>): Payment => {
    const db = loadDatabase();
    const newPayment: Payment = {
      ...payment,
      id: Date.now().toString(),
      createdAt: new Date().toISOString(),
    };
    db.payments.push(newPayment);
    saveDatabase(db);
    return newPayment;
  },
  updatePayment: (id: string, updates: Partial<Payment>): Payment | null => {
    const db = loadDatabase();
    const index = db.payments.findIndex(p => p.id === id);
    if (index === -1) return null;
    db.payments[index] = { ...db.payments[index], ...updates };
    saveDatabase(db);
    return db.payments[index];
  },
  // Review methods
  getReviews: (): Review[] => loadDatabase().reviews,
  getReviewById: (id: string): Review | undefined => {
    return loadDatabase().reviews.find(r => r.id === id);
  },
  createReview: (review: Omit<Review, 'id' | 'createdAt'>): Review => {
    const db = loadDatabase();
    const newReview: Review = {
      ...review,
      id: Date.now().toString(),
      createdAt: new Date().toISOString(),
    };
    db.reviews.push(newReview);
    saveDatabase(db);
    return newReview;
  },
  updateReview: (id: string, updates: Partial<Review>): Review | null => {
    const db = loadDatabase();
    const index = db.reviews.findIndex(r => r.id === id);
    if (index === -1) return null;
    db.reviews[index] = { ...db.reviews[index], ...updates };
    saveDatabase(db);
    return db.reviews[index];
  },
  deleteReview: (id: string): boolean => {
    const db = loadDatabase();
    const index = db.reviews.findIndex(r => r.id === id);
    if (index === -1) return false;
    db.reviews.splice(index, 1);
    saveDatabase(db);
    return true;
  },
  // Provider rating methods
  updateProviderRating: (providerId: string): void => {
    const db = loadDatabase();
    const reviews = db.reviews.filter(r => r.providerId === providerId);
    if (reviews.length === 0) return;

    const totalRating = reviews.reduce((sum, r) => sum + r.rating, 0);
    const averageRating = totalRating / reviews.length;
    const reviewCount = reviews.length;

    // Update user with rating (we'll store it in a metadata field)
    // For now, we'll calculate it on the fly in the API
  },
};
