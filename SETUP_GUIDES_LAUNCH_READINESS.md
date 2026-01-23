# Setup Guides for Launch Readiness

Quick setup guides for remaining launch readiness items.

---

## 1. Sentry Error Tracking

### Backend Setup

1. **Install Sentry:**
   ```bash
   cd server
   npm install @sentry/node
   ```

2. **Add to `server/index.ts`:**
   ```typescript
   import * as Sentry from '@sentry/node';

   Sentry.init({
     dsn: process.env.SENTRY_DSN,
     environment: process.env.NODE_ENV || 'development',
     tracesSampleRate: 1.0,
   });

   // Add before routes
   app.use(Sentry.Handlers.requestHandler());
   app.use(Sentry.Handlers.tracingHandler());

   // Add after routes, before error handler
   app.use(Sentry.Handlers.errorHandler());
   ```

3. **Set Environment Variable:**
   - Railway: Add `SENTRY_DSN` (get from sentry.io)

### Flutter Setup

1. **Add to `pubspec.yaml`:**
   ```yaml
   dependencies:
     sentry_flutter: ^7.0.0
   ```

2. **Initialize in `main.dart`:**
   ```dart
   import 'package:sentry_flutter/sentry_flutter.dart';

   void main() async {
     await SentryFlutter.init(
       (options) {
         options.dsn = 'YOUR_SENTRY_DSN';
         options.environment = 'production';
       },
       appRunner: () => runApp(const MyApp()),
     );
   }
   ```

---

## 2. Uptime Monitoring

### Option A: UptimeRobot (Free)

1. Go to https://uptimerobot.com
2. Add Monitor:
   - Type: HTTP(s)
   - URL: `https://accurate-solace-app22.up.railway.app/api/health`
   - Interval: 5 minutes
3. Get email alerts on downtime

### Option B: Pingdom

1. Sign up at https://www.pingdom.com
2. Add HTTP check to `/api/health`
3. Set alerting

---

## 3. PostgreSQL Migration

### Railway PostgreSQL

1. **Add PostgreSQL Service:**
   - Railway Dashboard → New → Database → PostgreSQL
   - Copy connection string

2. **Install Dependencies:**
   ```bash
   cd server
   npm install pg
   npm install --save-dev @types/pg
   ```

3. **Create `server/data/postgres.ts`:**
   ```typescript
   import { Pool } from 'pg';

   const pool = new Pool({
     connectionString: process.env.DATABASE_URL,
     ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
   });

   export default pool;
   ```

4. **Migration Script:**
   - Create `server/migrations/001_initial.sql` with schema from `BOOKLY_COMPLETE_BUSINESS_PLAN_AND_TECHNICAL_DOCUMENTATION.md`
   - Run migrations before switching

5. **Update `server/data/database.ts`:**
   - Replace JSON file operations with PostgreSQL queries
   - Use connection pool

6. **Set Environment Variable:**
   - Railway: `DATABASE_URL` (auto-set by Railway PostgreSQL)

---

## 4. Automated Backups

### Railway PostgreSQL

Railway PostgreSQL includes automatic daily backups. Verify in Railway dashboard:
- Settings → Backups
- Retention: 7-30 days (configurable)

### Manual Backup Script

Create `server/scripts/backup.sh`:
```bash
#!/bin/bash
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql
```

---

## 5. Load Testing

### Using k6

1. **Install k6:**
   ```bash
   # Windows: choco install k6
   # Mac: brew install k6
   ```

2. **Create `load-test.js`:**
   ```javascript
   import http from 'k6/http';
   import { check } from 'k6';

   export const options = {
     stages: [
       { duration: '30s', target: 20 },
       { duration: '1m', target: 50 },
       { duration: '30s', target: 0 },
     ],
   };

   const BASE_URL = 'https://accurate-solace-app22.up.railway.app/api';

   export default function () {
     // Health check
     let res = http.get(`${BASE_URL}/health`);
     check(res, { 'health status 200': (r) => r.status === 200 });

     // Search
     res = http.get(`${BASE_URL}/services/search?q=haircut`);
     check(res, { 'search status 200': (r) => r.status === 200 });
   }
   ```

3. **Run:**
   ```bash
   k6 run load-test.js
   ```

---

## 6. Legal Documents

### Privacy Policy Template

Create `docs/PRIVACY_POLICY.md`:
- What data you collect (email, name, phone, location, payment IDs)
- How you use it (booking, payments, analytics)
- Data retention (7 years for payments, until account deletion)
- User rights (access, deletion, portability)
- GDPR compliance statement

### Terms of Service Template

Create `docs/TERMS_OF_SERVICE.md`:
- User responsibilities
- Platform rules
- Payment terms
- Cancellation/refund policy reference
- Liability limitations
- Governing law

### Refund Policy

Create `docs/REFUND_POLICY.md`:
- Align with `PLATFORM_DEFAULT_POLICY` (24h free, 25% late, 50% no-show)
- Stripe refund process
- Chargeback policy

### Publish & Link

1. Host on GitHub Pages or your domain
2. Set `TERMS_URL` and `PRIVACY_URL` in Railway env vars
3. Update `GET /api/policies/terms` and `/privacy` to return URLs

---

## 7. App Store Assets

### iOS (App Store Connect)

1. **App Icons:**
   - 1024x1024px (required)
   - Use design tool or export from Flutter

2. **Screenshots:**
   - iPhone 6.7" (1290x2796)
   - iPhone 6.5" (1284x2778)
   - At least 3 screenshots

3. **Description:**
   - Short: 170 chars max
   - Full: Detailed features, benefits

4. **Age Rating:**
   - 4+ (no objectionable content)

### Android (Google Play Console)

1. **App Icons:**
   - 512x512px (required)
   - Adaptive icons (foreground + background)

2. **Screenshots:**
   - Phone: 16:9 or 9:16
   - Tablet: 16:9 or 9:16 (if supported)
   - At least 2 screenshots

3. **Description:**
   - Short: 80 chars max
   - Full: 4000 chars max

---

## 8. Support Email Setup

### Option A: Gmail/Outlook

1. Create `support@bookly.com` (or your domain)
2. Forward to your personal email
3. Use in app: `AppConfig.supportEmail`

### Option B: Zendesk (Free tier)

1. Sign up at https://www.zendesk.com
2. Create support email
3. Integrate webhook or email forwarding

---

## Quick Checklist

- [ ] Sentry DSN set in Railway + Flutter
- [ ] UptimeRobot monitoring `/api/health`
- [ ] PostgreSQL added to Railway
- [ ] Database migration script ready
- [ ] Backup retention verified
- [ ] Load test baseline documented
- [ ] Privacy Policy published
- [ ] Terms of Service published
- [ ] Refund Policy published
- [ ] App icons created (iOS + Android)
- [ ] Screenshots captured
- [ ] Store descriptions written
- [ ] Support email configured

---

**Note:** These are setup guides. Actual implementation of PostgreSQL migration and Sentry integration requires code changes beyond this document.
