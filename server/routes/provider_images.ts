import express, { Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';
import { createReport } from '../utils/reports';

const router = express.Router();

// Get provider's own images (authenticated)
router.get('/', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const user = db.getUserById(userId);
    
    if (!user || user.role !== 'provider') {
      return res.status(403).json({ error: 'Only providers can view their images' });
    }

    const images = db.getProviderImages(userId);
    res.json(images);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get provider images (public)
router.get('/provider/:providerId', (req, res: Response) => {
  try {
    const { providerId } = req.params;
    const images = db.getProviderImages(providerId);
    res.json(images);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Add provider image (provider only)
router.post('/', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const user = db.getUserById(userId);
    
    if (!user || user.role !== 'provider') {
      return res.status(403).json({ error: 'Only providers can add images' });
    }

    const { url, caption, type = 'gallery', order = 0 } = req.body;

    if (!url) {
      return res.status(400).json({ error: 'Image URL is required' });
    }

    const image = db.addProviderImage({
      providerId: userId,
      url,
      caption,
      type,
      order,
    });

    res.json(image);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Report provider image (flag for moderation)
router.post('/:id/report', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const image = db.getProviderImageById(req.params.id);
    if (!image) return res.status(404).json({ error: 'Image not found' });
    const { reason } = req.body || {};
    createReport('provider_image', image.id, req.userId!, reason);
    res.status(202).json({ message: 'Report submitted. Thank you.' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update provider image
router.patch('/:id', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const { id } = req.params;
    
    // Verify user owns this image
    const images = db.getProviderImages(userId);
    const image = images.find(img => img.id === id);
    
    if (!image) {
      return res.status(404).json({ error: 'Image not found' });
    }

    const updated = db.updateProviderImage(id, req.body);
    if (!updated) {
      return res.status(404).json({ error: 'Image not found' });
    }

    res.json(updated);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete provider image
router.delete('/:id', authenticate, (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const { id } = req.params;
    
    // Verify user owns this image
    const images = db.getProviderImages(userId);
    const image = images.find(img => img.id === id);
    
    if (!image) {
      return res.status(404).json({ error: 'Image not found' });
    }

    const deleted = db.deleteProviderImage(id);
    if (!deleted) {
      return res.status(404).json({ error: 'Image not found' });
    }

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
