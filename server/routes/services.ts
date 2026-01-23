import express, { Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';

const router = express.Router();

router.get('/', async (req, res: Response) => {
  try {
    const providerId = req.query.providerId as string | undefined;
    const services = await db.getServices(providerId);
    res.json(services || []);
  } catch (error) {
    console.error('Error fetching services:', error);
    res.status(500).json({ error: 'Failed to fetch services. Please try again.' });
  }
});

router.get('/categories', async (req, res: Response) => {
  try {
    const services = await db.getServices();
    const categories = [...new Set(services.map(s => s.category).filter(Boolean))];
    res.json(categories || []);
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({ error: 'Failed to fetch categories. Please try again.' });
  }
});

router.get('/search', async (req, res: Response) => {
  try {
    let services = await db.getServices();
    const { q, category, minPrice, maxPrice, providerId } = req.query;

    if (!services || services.length === 0) {
      return res.json([]);
    }

    if (q && typeof q === 'string') {
      const query = q.toLowerCase().trim();
      services = services.filter(s => 
        s.name?.toLowerCase().includes(query) ||
        s.description?.toLowerCase().includes(query)
      );
    }

    if (category && typeof category === 'string') {
      services = services.filter(s => s.category === category);
    }

    if (minPrice) {
      const min = parseFloat(minPrice as string);
      if (!isNaN(min)) {
        services = services.filter(s => s.price >= min);
      }
    }

    if (maxPrice) {
      const max = parseFloat(maxPrice as string);
      if (!isNaN(max)) {
        services = services.filter(s => s.price <= max);
      }
    }

    if (providerId && typeof providerId === 'string') {
      services = services.filter(s => s.providerId === providerId);
    }

    res.json(services || []);
  } catch (error) {
    console.error('Error searching services:', error);
    res.status(500).json({ error: 'Failed to search services. Please try again.' });
  }
});

router.get('/:id', async (req, res: Response) => {
  try {
    if (!req.params.id) {
      return res.status(400).json({ error: 'Service ID is required' });
    }

    const service = await db.getServiceById(req.params.id);
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }
    res.json(service);
  } catch (error) {
    console.error('Error fetching service:', error);
    res.status(500).json({ error: 'Failed to fetch service. Please try again.' });
  }
});

router.post('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can create services' });
    }

    const { name, description, duration, price, category } = req.body;

    // Validate required fields
    if (!name || !description || !duration || price === undefined || !category) {
      return res.status(400).json({ error: 'Missing required fields: name, description, duration, price, and category are required' });
    }

    // Validate name length
    if (typeof name !== 'string' || name.trim().length < 2 || name.trim().length > 100) {
      return res.status(400).json({ error: 'Service name must be between 2 and 100 characters' });
    }

    // Validate description length
    if (typeof description !== 'string' || description.trim().length < 10 || description.trim().length > 500) {
      return res.status(400).json({ error: 'Description must be between 10 and 500 characters' });
    }

    // Validate duration
    const durationNum = parseInt(duration);
    if (isNaN(durationNum) || durationNum < 15 || durationNum > 480) {
      return res.status(400).json({ error: 'Duration must be between 15 and 480 minutes (8 hours)' });
    }

    // Validate price
    const priceNum = parseFloat(price);
    if (isNaN(priceNum) || priceNum < 0 || priceNum > 10000) {
      return res.status(400).json({ error: 'Price must be between $0 and $10,000' });
    }

    // Validate category
    if (typeof category !== 'string' || category.trim().length < 2 || category.trim().length > 50) {
      return res.status(400).json({ error: 'Category must be between 2 and 50 characters' });
    }

    // Validate capacity
    const capacity = req.body.capacity ? parseInt(req.body.capacity) : 1;
    if (isNaN(capacity) || capacity < 1 || capacity > 100) {
      return res.status(400).json({ error: 'Capacity must be between 1 and 100' });
    }

    const service = await db.createService({
      providerId: req.userId!,
      name: name.trim(),
      description: description.trim(),
      duration: durationNum,
      price: priceNum,
      category: category.trim(),
      capacity,
    });

    res.status(201).json(service);
  } catch (error) {
    console.error('Error creating service:', error);
    res.status(500).json({ error: 'Failed to create service. Please try again.' });
  }
});

router.patch('/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const service = await db.getServiceById(req.params.id);
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }

    // Security check: Only the service owner can update
    if (service.providerId !== req.userId) {
      return res.status(403).json({ error: 'You can only update your own services' });
    }

    const { name, description, duration, price, category } = req.body;
    const updates: any = {};

    // Validate and add updates
    if (name !== undefined) {
      if (typeof name !== 'string' || name.trim().length < 2 || name.trim().length > 100) {
        return res.status(400).json({ error: 'Service name must be between 2 and 100 characters' });
      }
      updates.name = name.trim();
    }

    if (description !== undefined) {
      if (typeof description !== 'string' || description.trim().length < 10 || description.trim().length > 500) {
        return res.status(400).json({ error: 'Description must be between 10 and 500 characters' });
      }
      updates.description = description.trim();
    }

    if (duration !== undefined) {
      const durationNum = parseInt(duration);
      if (isNaN(durationNum) || durationNum < 15 || durationNum > 480) {
        return res.status(400).json({ error: 'Duration must be between 15 and 480 minutes (8 hours)' });
      }
      updates.duration = durationNum;
    }

    if (price !== undefined) {
      const priceNum = parseFloat(price);
      if (isNaN(priceNum) || priceNum < 0 || priceNum > 10000) {
        return res.status(400).json({ error: 'Price must be between $0 and $10,000' });
      }
      updates.price = priceNum;
    }

    if (category !== undefined) {
      if (typeof category !== 'string' || category.trim().length < 2 || category.trim().length > 50) {
        return res.status(400).json({ error: 'Category must be between 2 and 50 characters' });
      }
      updates.category = category.trim();
    }

    // Check if there are any updates
    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    const updated = await db.updateService(req.params.id, updates);
    if (!updated) {
      return res.status(404).json({ error: 'Service not found' });
    }

    res.json(updated);
  } catch (error) {
    console.error('Error updating service:', error);
    res.status(500).json({ error: 'Failed to update service. Please try again.' });
  }
});

router.delete('/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const service = await db.getServiceById(req.params.id);
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }

    if (service.providerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await db.deleteService(req.params.id);
    res.json({ message: 'Service deleted' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
