import express, { Request, Response } from 'express';
import cors from 'cors';
import authRoutes from './routes/auth';
import appointmentRoutes from './routes/appointments';
import userRoutes from './routes/users';
import serviceRoutes from './routes/services';
import paymentRoutes from './routes/payments';
import reviewRoutes from './routes/reviews';
import availabilityRoutes from './routes/availability';
import favoritesRoutes from './routes/favorites';
import providerImagesRoutes from './routes/provider_images';
import analyticsRoutes from './routes/analytics';
import { generalRateLimit } from './middleware/rateLimit';

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());
// Apply general rate limiting to all routes
app.use(generalRateLimit);

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/users', userRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/availability', availabilityRoutes);
app.use('/api/favorites', favoritesRoutes);
app.use('/api/provider-images', providerImagesRoutes);
app.use('/api/analytics', analyticsRoutes);

app.get('/api/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
