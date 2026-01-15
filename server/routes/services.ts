import express, { Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';

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

router.get('/search', (req, res: Response) => {
  try {
    let services = db.getServices();
    const { q, category, minPrice, maxPrice, providerId } = req.query;

    if (q) {
      const query = (q as string).toLowerCase();
      services = services.filter(s => 
        s.name.toLowerCase().includes(query) ||
        s.description.toLowerCase().includes(query)
      );
    }

    if (category) {
      services = services.filter(s => s.category === category);
    }

    if (minPrice) {
      services = services.filter(s => s.price >= parseFloat(minPrice as string));
    }

    if (maxPrice) {
      services = services.filter(s => s.price <= parseFloat(maxPrice as string));
    }

    if (providerId) {
      services = services.filter(s => s.providerId === providerId);
    }

    res.json(services);
  } catch (error) {
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

router.post('/', authenticate, (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can create services' });
    }

    const { name, description, duration, price, category } = req.body;

    if (!name || !description || !duration || price === undefined || !category) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const service = db.createService({
      providerId: req.userId!,
      name,
      description,
      duration: parseInt(duration),
      price: parseFloat(price),
      category,
    });

    res.status(201).json(service);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.patch('/:id', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const service = db.getServiceById(req.params.id);
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }

    if (service.providerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const { name, description, duration, price, category } = req.body;
    const updates: any = {};
    if (name) updates.name = name;
    if (description) updates.description = description;
    if (duration) updates.duration = parseInt(duration);
    if (price !== undefined) updates.price = parseFloat(price);
    if (category) updates.category = category;

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
    const service = db.getServiceById(req.params.id);
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }

    if (service.providerId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    db.deleteService(req.params.id);
    res.json({ message: 'Service deleted' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
