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
  profilePicture?: string;
  cancellationPolicy?: CancellationPolicy; // Provider-level default policy
  emailVerified?: boolean; // Email verification status
  createdAt: string;
}

export interface CancellationPolicy {
  freeCancelHours: number; // Free cancellation until X hours before appointment
  lateCancelFee?: number; // Fee for late cancellation (percentage of price)
  noShowFee?: number; // Fee for no-show (percentage of price)
  requireDeposit?: boolean; // Whether deposit is required
  depositAmount?: number; // Deposit amount (percentage of price)
}

export interface Service {
  id: string;
  providerId: string;
  name: string;
  description: string;
  duration: number; // in minutes
  price: number;
  category: string;
  subcategory?: string; // Subcategory (e.g., "Haircut", "Nails")
  tags?: string[]; // Searchable tags (e.g., ["fade", "beard", "taper"])
  capacity?: number; // Number of concurrent appointments (default: 1)
  isActive?: boolean; // Service availability status (default: true)
  cancellationPolicy?: CancellationPolicy; // Service-specific cancellation policy
}

export interface Availability {
  id: string;
  providerId: string;
  dayOfWeek: string; // 'monday', ...
  startTime: string; // '09:00'
  endTime: string; // '17:00'
  breaks: string[]; // ['12:00-13:00']
  isAvailable: boolean;
}

export interface AvailabilityException {
  id: string;
  providerId: string;
  date: string; // yyyy-mm-dd
  startTime?: string;
  endTime?: string;
  breaks: string[];
  isAvailable: boolean;
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
  platformCommission?: number; // Platform's commission (15%)
  providerAmount?: number; // Amount provider receives (85%)
  commissionRate?: number; // Commission rate percentage
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

export interface Favorite {
  id: string;
  customerId: string;
  providerId: string;
  createdAt: string;
}

export interface ProviderImage {
  id: string;
  providerId: string;
  url: string;
  caption?: string;
  type: 'gallery' | 'portfolio' | 'before_after';
  order: number;
  createdAt: string;
}

export interface ReservationHold {
  id: string;
  providerId: string;
  serviceId: string;
  date: string; // yyyy-mm-dd
  time: string; // HH:MM
  customerId: string;
  expiresAt: string; // ISO timestamp (typically 5-10 minutes from creation)
  createdAt: string;
}

interface Database {
  users: User[];
  services: Service[];
  appointments: Appointment[];
  payments: Payment[];
  reviews: Review[];
  availability: Availability[];
  availabilityExceptions: AvailabilityException[];
  favorites: Favorite[];
  providerImages: ProviderImage[];
  reservationHolds: ReservationHold[];
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
      availability: parsed.availability || [],
      availabilityExceptions: parsed.availabilityExceptions || [],
      favorites: parsed.favorites || [],
      providerImages: parsed.providerImages || [],
      reservationHolds: parsed.reservationHolds || [],
    };
  }
  return {
    users: [],
    services: [],
    appointments: [],
    payments: [],
    reviews: [],
    availability: [],
    availabilityExceptions: [],
    favorites: [],
    providerImages: [],
    reservationHolds: [],
  };
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

  // Availability methods
  getAvailability: (providerId: string): Availability[] => {
    const db = loadDatabase();
    return db.availability.filter((a) => a.providerId === providerId);
  },
  createOrUpdateAvailability: (input: Omit<Availability, 'id'>): Availability => {
    const dbData = loadDatabase();
    const day = input.dayOfWeek.toLowerCase();
    const existingIndex = dbData.availability.findIndex(
      (a) => a.providerId === input.providerId && a.dayOfWeek === day,
    );
    if (existingIndex !== -1) {
      dbData.availability[existingIndex] = {
        ...dbData.availability[existingIndex],
        ...input,
        dayOfWeek: day,
      };
      saveDatabase(dbData);
      return dbData.availability[existingIndex];
    }

    const newRow: Availability = {
      ...input,
      dayOfWeek: day,
      id: Date.now().toString(),
    };
    dbData.availability.push(newRow);
    saveDatabase(dbData);
    return newRow;
  },
  deleteAvailability: (id: string): boolean => {
    const dbData = loadDatabase();
    const index = dbData.availability.findIndex((a) => a.id === id);
    if (index === -1) return false;
    dbData.availability.splice(index, 1);
    saveDatabase(dbData);
    return true;
  },

  // Availability exception methods
  getAvailabilityExceptions: (providerId: string): AvailabilityException[] => {
    const dbData = loadDatabase();
    return dbData.availabilityExceptions.filter((e) => e.providerId === providerId);
  },
  createOrUpdateAvailabilityException: (
    input: Omit<AvailabilityException, 'id'>,
  ): AvailabilityException => {
    const dbData = loadDatabase();
    const existingIndex = dbData.availabilityExceptions.findIndex(
      (e) => e.providerId === input.providerId && e.date === input.date,
    );
    if (existingIndex !== -1) {
      dbData.availabilityExceptions[existingIndex] = {
        ...dbData.availabilityExceptions[existingIndex],
        ...input,
      };
      saveDatabase(dbData);
      return dbData.availabilityExceptions[existingIndex];
    }

    const newRow: AvailabilityException = {
      ...input,
      id: Date.now().toString(),
    };
    dbData.availabilityExceptions.push(newRow);
    saveDatabase(dbData);
    return newRow;
  },
  deleteAvailabilityException: (id: string): boolean => {
    const dbData = loadDatabase();
    const index = dbData.availabilityExceptions.findIndex((e) => e.id === id);
    if (index === -1) return false;
    dbData.availabilityExceptions.splice(index, 1);
    saveDatabase(dbData);
    return true;
  },

  // Favorite methods
  getFavorites: (customerId: string): Favorite[] => {
    const dbData = loadDatabase();
    return dbData.favorites.filter(f => f.customerId === customerId);
  },
  isFavorite: (customerId: string, providerId: string): boolean => {
    const dbData = loadDatabase();
    return dbData.favorites.some(f => f.customerId === customerId && f.providerId === providerId);
  },
  addFavorite: (customerId: string, providerId: string): Favorite => {
    const dbData = loadDatabase();
    // Check if already favorited
    const existing = dbData.favorites.find(f => f.customerId === customerId && f.providerId === providerId);
    if (existing) return existing;
    
    const newFavorite: Favorite = {
      id: Date.now().toString(),
      customerId,
      providerId,
      createdAt: new Date().toISOString(),
    };
    dbData.favorites.push(newFavorite);
    saveDatabase(dbData);
    return newFavorite;
  },
  removeFavorite: (customerId: string, providerId: string): boolean => {
    const dbData = loadDatabase();
    const index = dbData.favorites.findIndex(f => f.customerId === customerId && f.providerId === providerId);
    if (index === -1) return false;
    dbData.favorites.splice(index, 1);
    saveDatabase(dbData);
    return true;
  },

  // Provider Image methods
  getProviderImages: (providerId: string): ProviderImage[] => {
    const dbData = loadDatabase();
    return dbData.providerImages
      .filter(img => img.providerId === providerId)
      .sort((a, b) => a.order - b.order);
  },
  getProviderImageById: (id: string): ProviderImage | undefined => {
    const dbData = loadDatabase();
    return dbData.providerImages.find(img => img.id === id);
  },
  addProviderImage: (image: Omit<ProviderImage, 'id' | 'createdAt'>): ProviderImage => {
    const dbData = loadDatabase();
    const newImage: ProviderImage = {
      ...image,
      id: Date.now().toString(),
      createdAt: new Date().toISOString(),
    };
    dbData.providerImages.push(newImage);
    saveDatabase(dbData);
    return newImage;
  },
  updateProviderImage: (id: string, updates: Partial<ProviderImage>): ProviderImage | null => {
    const dbData = loadDatabase();
    const index = dbData.providerImages.findIndex(img => img.id === id);
    if (index === -1) return null;
    dbData.providerImages[index] = { ...dbData.providerImages[index], ...updates };
    saveDatabase(dbData);
    return dbData.providerImages[index];
  },
  deleteProviderImage: (id: string): boolean => {
    const dbData = loadDatabase();
    const index = dbData.providerImages.findIndex(img => img.id === id);
    if (index === -1) return false;
    dbData.providerImages.splice(index, 1);
    saveDatabase(dbData);
    return true;
  },

  // Reservation Hold methods (prevent double bookings)
  createReservationHold: (hold: Omit<ReservationHold, 'id' | 'createdAt'>): ReservationHold => {
    const dbData = loadDatabase();
    // Clean up expired holds first
    const now = new Date().toISOString();
    dbData.reservationHolds = dbData.reservationHolds.filter(h => h.expiresAt > now);
    
    const newHold: ReservationHold = {
      ...hold,
      id: Date.now().toString(),
      createdAt: new Date().toISOString(),
    };
    dbData.reservationHolds.push(newHold);
    saveDatabase(dbData);
    return newHold;
  },
  getReservationHolds: (providerId: string, date: string, time: string): ReservationHold[] => {
    const dbData = loadDatabase();
    const now = new Date().toISOString();
    // Clean up expired holds
    dbData.reservationHolds = dbData.reservationHolds.filter(h => h.expiresAt > now);
    saveDatabase(dbData);
    
    return dbData.reservationHolds.filter(
      h => h.providerId === providerId && h.date === date && h.time === time && h.expiresAt > now
    );
  },
  deleteReservationHold: (id: string): boolean => {
    const dbData = loadDatabase();
    const index = dbData.reservationHolds.findIndex(h => h.id === id);
    if (index === -1) return false;
    dbData.reservationHolds.splice(index, 1);
    saveDatabase(dbData);
    return true;
  },
  cleanupExpiredHolds: (): number => {
    const dbData = loadDatabase();
    const now = new Date().toISOString();
    const before = dbData.reservationHolds.length;
    dbData.reservationHolds = dbData.reservationHolds.filter(h => h.expiresAt > now);
    const after = dbData.reservationHolds.length;
    if (before !== after) {
      saveDatabase(dbData);
    }
    return before - after;
  },
};
