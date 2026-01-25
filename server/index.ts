import express, { Request, Response } from 'express';
import cors from 'cors';
import authRoutes from './routes/auth';
import appointmentRoutes from './routes/appointments';
import userRoutes from './routes/users';
import serviceRoutes from './routes/services';
import paymentRoutes from './routes/payments';
import reviewRoutes from './routes/reviews';
import stripeRoutes from './routes/stripe';
import availabilityRoutes from './routes/availability';
import adminRoutes from './routes/admin';
import policyRoutes from './routes/policies';
// Import database to trigger initialization
import './data/database';

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/users', userRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/stripe', stripeRoutes);
app.use('/api/availability', availabilityRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/policies', policyRoutes);

app.get('/api/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
