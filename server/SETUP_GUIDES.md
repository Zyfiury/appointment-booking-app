# Setup Guides for Remaining Improvements

## 1. PostgreSQL Migration Guide

### Step 1: Install PostgreSQL
```bash
# macOS
brew install postgresql
brew services start postgresql

# Ubuntu/Debian
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql

# Windows
# Download from https://www.postgresql.org/download/windows/
```

### Step 2: Create Database
```sql
CREATE DATABASE appointment_booking;
CREATE USER app_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE appointment_booking TO app_user;
```

### Step 3: Install Prisma
```bash
cd server
npm install prisma @prisma/client
npx prisma init
```

### Step 4: Create Schema (prisma/schema.prisma)
```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id                String   @id @default(uuid())
  email             String   @unique
  password          String
  name              String
  role              String   // 'customer' | 'provider'
  phone             String?
  latitude          Float?
  longitude         Float?
  address           String?
  profilePicture    String?
  createdAt         DateTime @default(now())
  
  // Relations
  services          Service[]
  appointmentsAsCustomer Appointment[] @relation("CustomerAppointments")
  appointmentsAsProvider Appointment[] @relation("ProviderAppointments")
}

model Service {
  id                String   @id @default(uuid())
  providerId        String
  name              String
  description       String
  duration          Int
  price             Float
  category          String
  subcategory       String?
  tags              String[]
  capacity          Int      @default(1)
  isActive          Boolean  @default(true)
  
  provider          User     @relation(fields: [providerId], references: [id])
  appointments      Appointment[]
  
  @@index([providerId])
  @@index([category])
  @@index([isActive])
}

model Appointment {
  id                String   @id @default(uuid())
  customerId        String
  providerId        String
  serviceId         String
  date              String
  time              String
  status            String   // 'pending' | 'confirmed' | 'cancelled' | 'completed'
  notes             String?
  createdAt         DateTime @default(now())
  
  customer          User     @relation("CustomerAppointments", fields: [customerId], references: [id])
  provider          User     @relation("ProviderAppointments", fields: [providerId], references: [id])
  service           Service  @relation(fields: [serviceId], references: [id])
  
  @@unique([providerId, date, time, serviceId])
  @@index([customerId])
  @@index([providerId])
  @@index([status])
}

// Add other models similarly...
```

### Step 5: Run Migration
```bash
npx prisma migrate dev --name init
npx prisma generate
```

### Step 6: Update .env
```env
DATABASE_URL="postgresql://app_user:your_password@localhost:5432/appointment_booking"
```

---

## 2. Redis Caching Setup

### Step 1: Install Redis
```bash
# macOS
brew install redis
brew services start redis

# Ubuntu/Debian
sudo apt-get install redis-server
sudo systemctl start redis

# Windows
# Download from https://redis.io/download
```

### Step 2: Install Redis Client
```bash
cd server
npm install redis
npm install --save-dev @types/redis
```

### Step 3: Create Cache Service
Create `server/services/cache.ts`:
```typescript
import { createClient } from 'redis';

const client = createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
});

client.on('error', (err) => console.error('Redis Client Error', err));

export async function connectRedis() {
  if (!client.isOpen) {
    await client.connect();
  }
}

export const cache = {
  async get<T>(key: string): Promise<T | null> {
    const value = await client.get(key);
    return value ? JSON.parse(value) : null;
  },

  async set(key: string, value: any, ttlSeconds?: number): Promise<void> {
    const stringValue = JSON.stringify(value);
    if (ttlSeconds) {
      await client.setEx(key, ttlSeconds, stringValue);
    } else {
      await client.set(key, stringValue);
    }
  },

  async del(key: string): Promise<void> {
    await client.del(key);
  },

  async clearPattern(pattern: string): Promise<void> {
    const keys = await client.keys(pattern);
    if (keys.length > 0) {
      await client.del(keys);
    }
  },
};
```

### Step 4: Use in Routes
```typescript
import { cache } from '../services/cache';

// Cache categories for 1 hour
router.get('/categories', async (req, res) => {
  const cacheKey = 'services:categories';
  let categories = await cache.get<string[]>(cacheKey);
  
  if (!categories) {
    categories = db.getCategories();
    await cache.set(cacheKey, categories, 3600); // 1 hour
  }
  
  res.json(categories);
});
```

---

## 3. Firebase Push Notifications Setup

### Step 1: Install Firebase Admin SDK
```bash
cd server
npm install firebase-admin
```

### Step 2: Create Firebase Service
Create `server/services/notifications.ts`:
```typescript
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}

export async function sendPushNotification(
  token: string,
  title: string,
  body: string,
  data?: any
) {
  try {
    await admin.messaging().send({
      token,
      notification: { title, body },
      data: data || {},
    });
  } catch (error) {
    console.error('Push notification error:', error);
  }
}

export async function sendToMultiple(
  tokens: string[],
  title: string,
  body: string,
  data?: any
) {
  try {
    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: data || {},
    });
  } catch (error) {
    console.error('Multicast notification error:', error);
  }
}
```

### Step 3: Add Notification Endpoints
```typescript
// In routes/notifications.ts
router.post('/register-token', authenticate, async (req, res) => {
  const { token } = req.body;
  // Store token in database associated with user
  db.updateUser(req.userId!, { pushToken: token });
  res.json({ success: true });
});
```

---

## 4. Error Logging with Sentry

### Step 1: Install Sentry
```bash
cd server
npm install @sentry/node
```

### Step 2: Initialize Sentry
Create `server/services/errorTracking.ts`:
```typescript
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV || 'development',
  tracesSampleRate: 1.0,
});

export { Sentry };
```

### Step 3: Add to Express
```typescript
// In server/index.ts
import { Sentry } from './services/errorTracking';

app.use(Sentry.Handlers.requestHandler());
app.use(Sentry.Handlers.errorHandler());
```

---

## 5. Environment Variables Template

Create `.env.example`:
```env
# Server
PORT=5000
NODE_ENV=development

# JWT
JWT_SECRET=your-secret-key-change-in-production

# Database (PostgreSQL)
DATABASE_URL=postgresql://user:password@localhost:5432/appointment_booking

# Redis
REDIS_URL=redis://localhost:6379

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@...
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# Sentry
SENTRY_DSN=https://...@sentry.io/...

# Email (for notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

---

## 6. Testing Checklist

After implementing each improvement:

- [ ] **Input Validation**: Test with invalid data, verify error messages
- [ ] **Pagination**: Test with different page/limit values
- [ ] **Search**: Test relevance scoring, verify results are sorted correctly
- [ ] **Cancellation**: Test with different policies, verify fee calculation
- [ ] **Analytics**: Verify calculations match expected values
- [ ] **Webhook**: Test with Stripe test events
- [ ] **Caching**: Verify cache hits/misses, test TTL expiration
- [ ] **Notifications**: Test push notification delivery
- [ ] **Error Tracking**: Verify errors are logged to Sentry

---

## 7. Performance Optimization

### Database Indexes (PostgreSQL)
```sql
CREATE INDEX idx_appointments_provider_date ON appointments(provider_id, date);
CREATE INDEX idx_services_category_active ON services(category, is_active);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_payments_status ON payments(status);
```

### Query Optimization
- Use `SELECT` specific fields instead of `SELECT *`
- Implement connection pooling
- Use prepared statements
- Add database query logging in development

---

## 8. Security Checklist

- [ ] Enable HTTPS in production
- [ ] Set secure cookie flags
- [ ] Implement CSRF protection
- [ ] Add request size limits
- [ ] Enable CORS only for trusted domains
- [ ] Sanitize all user inputs
- [ ] Use parameterized queries (Prisma handles this)
- [ ] Implement rate limiting (already done)
- [ ] Add security headers (Helmet.js)
- [ ] Regular dependency updates

---

## 9. Deployment Checklist

- [ ] Set all environment variables
- [ ] Run database migrations
- [ ] Set up Redis
- [ ] Configure Firebase
- [ ] Set up Sentry
- [ ] Enable webhook signature verification
- [ ] Set up SSL certificates
- [ ] Configure backup strategy
- [ ] Set up monitoring/alerts
- [ ] Load testing
