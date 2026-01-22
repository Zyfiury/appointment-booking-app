import express, { Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';
import { validate, validateQuery, schemas } from '../middleware/validation';
import { searchServices } from '../utils/search';
import { paginate, parsePagination, PaginatedResponse } from '../utils/pagination';
import { Service } from '../data/database';

const router = express.Router();

router.get('/', (req, res: Response) => {
  try {
    const providerId = req.query.providerId as string | undefined;
    const services = db.getServices(providerId);
    res.json(services);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/categories', (req, res: Response) => {
  try {
    const services = db.getServices();
    const categories = [...new Set(services.map(s => s.category))].filter(Boolean);
    res.json(categories);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/search', validateQuery(schemas.searchQuery), (req, res: Response) => {
  try {
    const allServices = db.getServices();
    const { q, category, subcategory, minPrice, maxPrice, providerId, isActive } = req.query;

    // Use improved search function
    const searchResults = searchServices(allServices, {
      query: q as string | undefined,
      category: category as string | undefined,
      subcategory: subcategory as string | undefined,
      minPrice: minPrice ? parseFloat(minPrice as string) : undefined,
      maxPrice: maxPrice ? parseFloat(maxPrice as string) : undefined,
      providerId: providerId as string | undefined,
      isActive: isActive === 'false' ? false : true,
    });

    // Add pagination
    const pagination = parsePagination(req.query);
    const paginated = paginate(searchResults, pagination);

    res.json(paginated);
  } catch (error) {
    console.error('Search error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/:id', (req, res: Response) => {
  try {
    const service = db.getServiceById(req.params.id);
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }
    res.json(service);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/', authenticate, validate(schemas.createService), (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can create services' });
    }

    const { name, description, duration, price, category, subcategory, tags, capacity } = req.body;

    const service = db.createService({
      providerId: req.userId!,
      name,
      description,
      duration: parseInt(duration),
      price: parseFloat(price),
      category,
      subcategory: subcategory || undefined,
      tags: Array.isArray(tags) ? tags : undefined,
      capacity: capacity ? parseInt(capacity) : 1,
      isActive: true,
    });

    res.status(201).json(service);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.patch('/:id', authenticate, validate(schemas.updateService), (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can update services' });
    }

    const service = db.getServiceById(req.params.id);
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }

    // CRITICAL: Ensure service belongs to the authenticated provider
    if (service.providerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied: Service does not belong to you' });
    }

    const { name, description, duration, price, category, subcategory, tags, capacity, isActive } = req.body;
    const updates: any = {};
    if (name) updates.name = name;
    if (description) updates.description = description;
    if (duration) updates.duration = parseInt(duration);
    if (price !== undefined) updates.price = parseFloat(price);
    if (category) updates.category = category;
    if (subcategory !== undefined) updates.subcategory = subcategory;
    if (tags !== undefined) updates.tags = Array.isArray(tags) ? tags : undefined;
    if (capacity !== undefined) updates.capacity = parseInt(capacity);
    if (isActive !== undefined) updates.isActive = isActive === true || isActive === 'true';

    const updated = db.updateService(req.params.id, updates);
    if (!updated) {
      return res.status(404).json({ error: 'Service not found' });
    }

    res.json(updated);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.delete('/:id', authenticate, (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can delete services' });
    }

    const service = db.getServiceById(req.params.id);
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }

    // CRITICAL: Ensure service belongs to the authenticated provider
    if (service.providerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied: Service does not belong to you' });
    }

    db.deleteService(req.params.id);
    res.json({ message: 'Service deleted' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
