import express, { Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { db } from '../data/database';

const router = express.Router();

// Get current provider's availability
router.get('/', authenticate, (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can view availability' });
    }
    const availability = db.getAvailability(req.userId!);
    res.json(availability);
  } catch (error) {
    console.error('Error fetching availability:', error);
    res.status(500).json({ error: 'Failed to fetch availability' });
  }
});

// Get availability for a specific provider (public for booking)
router.get('/provider/:providerId', (req: AuthRequest, res: Response) => {
  try {
    const availability = db.getAvailability(req.params.providerId);
    res.json(availability);
  } catch (error) {
    console.error('Error fetching provider availability:', error);
    res.status(500).json({ error: 'Failed to fetch availability' });
  }
});

// Create or update availability (upsert by providerId + dayOfWeek)
router.post('/', authenticate, (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can set availability' });
    }

    const { dayOfWeek, startTime, endTime, breaks, isAvailable } = req.body;
    if (!dayOfWeek || !startTime || !endTime) {
      return res
        .status(400)
        .json({ error: 'Missing required fields: dayOfWeek, startTime, endTime' });
    }

    const validDays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    if (!validDays.includes(String(dayOfWeek).toLowerCase())) {
      return res.status(400).json({ error: 'Invalid day of week' });
    }

    const timeRegex = /^([0-1][0-9]|2[0-3]):[0-5][0-9]$/;
    if (!timeRegex.test(startTime) || !timeRegex.test(endTime)) {
      return res
        .status(400)
        .json({ error: 'Invalid time format. Use HH:MM (24-hour format)' });
    }

    const [startHour, startMin] = startTime.split(':').map(Number);
    const [endHour, endMin] = endTime.split(':').map(Number);
    const startMinutes = startHour * 60 + startMin;
    const endMinutes = endHour * 60 + endMin;
    if (endMinutes <= startMinutes) {
      return res.status(400).json({ error: 'End time must be after start time' });
    }

    const availability = db.createOrUpdateAvailability({
      providerId: req.userId!,
      dayOfWeek: String(dayOfWeek).toLowerCase(),
      startTime,
      endTime,
      breaks: Array.isArray(breaks) ? breaks : [],
      isAvailable: isAvailable !== false,
    });

    res.json(availability);
  } catch (error) {
    console.error('Error creating/updating availability:', error);
    res.status(500).json({ error: 'Failed to save availability' });
  }
});

// Delete availability by id (provider-owned)
router.delete('/:id', authenticate, (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can delete availability' });
    }

    const rows = db.getAvailability(req.userId!);
    const exists = rows.find((a) => a.id === req.params.id);
    if (!exists) return res.status(404).json({ error: 'Availability not found' });

    db.deleteAvailability(req.params.id);
    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting availability:', error);
    res.status(500).json({ error: 'Failed to delete availability' });
  }
});

// Provider date exceptions (days off / special hours)
router.get('/exceptions', authenticate, (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can view exceptions' });
    }
    const rows = db.getAvailabilityExceptions(req.userId!);
    res.json(rows);
  } catch (error) {
    console.error('Error fetching availability exceptions:', error);
    res.status(500).json({ error: 'Failed to fetch exceptions' });
  }
});

router.get('/provider/:providerId/exceptions', (req, res: Response) => {
  try {
    const rows = db.getAvailabilityExceptions(req.params.providerId);
    res.json(rows);
  } catch (error) {
    console.error('Error fetching provider availability exceptions:', error);
    res.status(500).json({ error: 'Failed to fetch exceptions' });
  }
});

router.post('/exceptions', authenticate, (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can set exceptions' });
    }

    const { date, startTime, endTime, breaks, isAvailable, note } = req.body;
    if (!date) {
      return res.status(400).json({ error: 'Missing required field: date (yyyy-mm-dd)' });
    }

    const available = isAvailable !== false;
    const timeRegex = /^([0-1][0-9]|2[0-3]):[0-5][0-9]$/;
    if (available) {
      if (!startTime || !endTime) {
        return res
          .status(400)
          .json({ error: 'startTime and endTime are required when isAvailable=true' });
      }
      if (!timeRegex.test(startTime) || !timeRegex.test(endTime)) {
        return res
          .status(400)
          .json({ error: 'Invalid time format. Use HH:MM (24-hour format)' });
      }
    } else {
      if (startTime && !timeRegex.test(startTime)) {
        return res.status(400).json({ error: 'Invalid startTime format' });
      }
      if (endTime && !timeRegex.test(endTime)) {
        return res.status(400).json({ error: 'Invalid endTime format' });
      }
    }

    const saved = db.createOrUpdateAvailabilityException({
      providerId: req.userId!,
      date,
      startTime: startTime || undefined,
      endTime: endTime || undefined,
      breaks: Array.isArray(breaks) ? breaks : [],
      isAvailable: available,
      note: note || undefined,
    });
    res.json(saved);
  } catch (error) {
    console.error('Error saving availability exception:', error);
    res.status(500).json({ error: 'Failed to save exception' });
  }
});

router.delete('/exceptions/:id', authenticate, (req: AuthRequest, res: Response) => {
  try {
    if (req.userRole !== 'provider') {
      return res.status(403).json({ error: 'Only providers can delete exceptions' });
    }
    const rows = db.getAvailabilityExceptions(req.userId!);
    const exists = rows.find((x) => x.id === req.params.id);
    if (!exists) return res.status(404).json({ error: 'Exception not found' });
    db.deleteAvailabilityException(req.params.id);
    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting availability exception:', error);
    res.status(500).json({ error: 'Failed to delete exception' });
  }
});

export default router;

