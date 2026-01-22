import { Request, Response, NextFunction } from 'express';
import { z, ZodError } from 'zod';

export function validate(schema: z.ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      schema.parse(req.body);
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const errors = error.errors.map((err) => ({
          path: err.path.join('.'),
          message: err.message,
        }));
        return res.status(400).json({
          error: 'Validation failed',
          details: errors,
        });
      }
      return res.status(400).json({ error: 'Invalid request data' });
    }
  };
}

export function validateQuery(schema: z.ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      schema.parse(req.query);
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const errors = error.errors.map((err) => ({
          path: err.path.join('.'),
          message: err.message,
        }));
        return res.status(400).json({
          error: 'Invalid query parameters',
          details: errors,
        });
      }
      return res.status(400).json({ error: 'Invalid query parameters' });
    }
  };
}

// Common validation schemas
export const schemas = {
  register: z.object({
    email: z.string().email('Invalid email address'),
    password: z.string().min(6, 'Password must be at least 6 characters'),
    name: z.string().min(2, 'Name must be at least 2 characters'),
    role: z.enum(['customer', 'provider'], {
      errorMap: () => ({ message: 'Role must be either customer or provider' }),
    }),
    phone: z.string().optional(),
  }),

  login: z.object({
    email: z.string().email('Invalid email address'),
    password: z.string().min(1, 'Password is required'),
  }),

  createService: z.object({
    name: z.string().min(1, 'Service name is required'),
    description: z.string().min(10, 'Description must be at least 10 characters'),
    duration: z.number().int().positive('Duration must be a positive number'),
    price: z.number().positive('Price must be positive'),
    category: z.string().min(1, 'Category is required'),
    subcategory: z.string().optional(),
    tags: z.array(z.string()).optional(),
    capacity: z.number().int().positive().default(1),
  }),

  updateService: z.object({
    name: z.string().min(1).optional(),
    description: z.string().min(10).optional(),
    duration: z.number().int().positive().optional(),
    price: z.number().positive().optional(),
    category: z.string().min(1).optional(),
    subcategory: z.string().optional(),
    tags: z.array(z.string()).optional(),
    capacity: z.number().int().positive().optional(),
    isActive: z.boolean().optional(),
  }),

  createAppointment: z.object({
    providerId: z.string().uuid('Invalid provider ID'),
    serviceId: z.string().uuid('Invalid service ID'),
    date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be in YYYY-MM-DD format'),
    time: z.string().regex(/^\d{2}:\d{2}$/, 'Time must be in HH:MM format'),
    notes: z.string().optional(),
    holdId: z.string().uuid().optional(),
  }),

  updateAppointment: z.object({
    status: z.enum(['pending', 'confirmed', 'cancelled', 'completed']).optional(),
    notes: z.string().optional(),
  }),

  createReview: z.object({
    appointmentId: z.string().uuid('Invalid appointment ID'),
    providerId: z.string().uuid('Invalid provider ID'),
    rating: z.number().int().min(1).max(5, 'Rating must be between 1 and 5'),
    comment: z.string().min(10, 'Comment must be at least 10 characters'),
    photos: z.array(z.string().url()).optional(),
  }),

  searchQuery: z.object({
    q: z.string().optional(),
    category: z.string().optional(),
    subcategory: z.string().optional(),
    minPrice: z.string().regex(/^\d+(\.\d+)?$/).optional(),
    maxPrice: z.string().regex(/^\d+(\.\d+)?$/).optional(),
    providerId: z.string().uuid().optional(),
    isActive: z.string().optional(),
    page: z.string().regex(/^\d+$/).optional(),
    limit: z.string().regex(/^\d+$/).optional(),
  }),

  pagination: z.object({
    page: z.string().regex(/^\d+$/).transform(Number).default('1'),
    limit: z.string().regex(/^\d+$/).transform(Number).default('20'),
  }),
};
