# Bookly — Launch Readiness Checklist

**Purpose:** Ensure the app is safe for real bookings and money, legally compliant, and operationally ready before public launch.

**Status legend:** ✅ Done | 🟡 In progress | ⏳ Planned | ❌ Blocked

---

## 1. Safe to take real bookings + money (must-do)

### 1.1 Database & scale
| Task | Status | Notes |
|------|--------|-------|
| Migrate from JSON file DB to PostgreSQL | ⏳ | Required before public launch. See `server/SETUP_GUIDES.md` or PostgreSQL migration plan. |
| Run DB migrations for schema (appointments, payments, holds, audit_logs) | ⏳ | After Postgres migration. |

### 1.2 Booking holds (prevent double-booking)
| Task | Status | Notes |
|------|--------|-------|
| Reservation holds (5–10 min) before payment | ✅ | `POST /api/appointments/hold`, 10 min expiry. |
| Exclude held slots from `GET /api/appointments/available-slots` | ✅ | Slots with active reservation holds are filtered out. |
| Hold creation checks conflicts (appointments + other holds) | ✅ | In `POST /api/appointments/hold`. |
| Webhook confirms appointment only after payment | ✅ | `payment_intent.succeeded` → confirm appointment; `payment_failed` → release hold. |

### 1.3 Payments
| Task | Status | Notes |
|------|--------|-------|
| Payments confirmed by Stripe webhooks (not client-only) | ✅ | Webhook updates payment + appointment. Client must not trust local state alone. |
| Stripe webhook signature verification | ✅ | Enabled when `STRIPE_WEBHOOK_SECRET` set. |
| Idempotency for `POST /api/appointments` | ✅ | `Idempotency-Key` header; in-memory cache; duplicate key returns cached 201. |
| Idempotency for `POST /api/payments/create-intent` | ✅ | Same. |

### 1.4 Cancellation / refund policy
| Task | Status | Notes |
|------|--------|-------|
| Define platform default: free cancel window, late fee, no-show fee, refund rules | ✅ | `PLATFORM_DEFAULT_POLICY` in `utils/cancellation.ts`; used when no provider/service policy. |
| Provider/service-level overrides (optional) | ✅ | `Service.cancellationPolicy`, `User.cancellationPolicy`. |
| `calculateCancellationFee` used on cancel | ✅ | `server/utils/cancellation.ts`. |
| Policy visible in-app (booking flow, help/settings) | 🟡 | Add “Cancellation & refund policy” screen + link from booking. |
| Publish Refund/Cancellation policy (web/app) | ⏳ | Legal doc; link from app and footer. |

---

## 2. Search & categories — launch-quality UX

### 2.1 Taxonomy
| Task | Status | Notes |
|------|--------|-------|
| Single category list (locked) | 🟡 | Define canonical list: e.g. Barber, Hair, Beauty, Massage, Fitness, Dental, Therapy, Medical, Home Services, Other. |
| Subcategories per category | 🟡 | e.g. Beauty → Nails, Lashes, Brows, Facial, Makeup. Store as `category` + `subcategory`. |
| Categories/subcategories as IDs (not free-text) | ⏳ | Backend validation; FK or enum. |

### 2.2 Search UX
| Task | Status | Notes |
|------|--------|-------|
| Search results tabs: **Services \| Providers** | ⏳ | Flutter: TabBar; separate API or combined with `type` param. |
| Default tab: Services | ⏳ | So “fade”, “nails” work naturally. |
| Filters: price, rating, distance | 🟡 | Backend: `minPrice`, `maxPrice`, `minRating`, `latitude`, `longitude`, `radius`. |
| Sort: relevance, rating, distance, price | 🟡 | `sortBy` in search. |
| Filters in bottom sheet (mobile) | ⏳ | Flutter UI. |

### 2.3 Provider onboarding
| Task | Status | Notes |
|------|--------|-------|
| Location required (address or lat/lng) | 🟡 | Validate on provider profile save. |
| At least 1 active service | 🟡 | Check before “complete onboarding”. |
| At least 1 availability rule | 🟡 | Check before “complete onboarding”. |
| Only show in search when onboarding complete | ✅ | `isOnboardingComplete()` filters in `GET /users/providers` and `GET /users/providers/search`. |

---

## 3. Security & abuse protection

### 3.1 Auth & storage
| Task | Status | Notes |
|------|--------|-------|
| Auth tokens in secure storage (mobile) | ✅ | `flutter_secure_storage` for tokens. |
| JWT expiry & refresh (or short-lived tokens) | 🟡 | Document; add refresh flow if needed. |

### 3.2 Rate limiting
| Task | Status | Notes |
|------|--------|-------|
| General API rate limit | ✅ | 100 req/15 min. |
| Auth (login/register) rate limit | ✅ | 5 req/15 min. |
| Search rate limit | ✅ | 50 req/15 min on `/services/search` and `/users/providers/search`. |
| Payment/create-intent rate limit | ✅ | 20 req/15 min on `POST /payments/create-intent` (after auth). |

### 3.3 Validation & hardening
| Task | Status | Notes |
|------|--------|-------|
| Zod validation on all relevant endpoints | 🟡 | Auth, services, appointments, reviews. Expand to users, availability, payments. |
| Sanitize inputs (XSS, injection) | 🟡 | Validate + sanitize; use parameterized queries with Postgres. |

### 3.4 Audit logs
| Task | Status | Notes |
|------|--------|-------|
| Log critical actions: payment confirm/fail/refund | ✅ | `utils/audit.ts`; logged in webhook handlers. |
| Log appointment create, confirm, cancel, complete | ✅ | Same; logged in appointment routes. |
| Admin-only access to audit logs | ⏳ | With admin role. |

### 3.5 Moderation
| Task | Status | Notes |
|------|--------|-------|
| Report review (flag/report) | ✅ | `POST /api/reviews/:id/report` (auth required); `utils/reports.ts`. |
| Report provider image | ✅ | `POST /api/provider-images/:id/report` (auth required). |
| Admin: remove abusive review/image | ⏳ | Admin endpoints. |

---

## 4. Stability & monitoring

### 4.1 Error tracking
| Task | Status | Notes |
|------|--------|-------|
| Sentry (or similar) on backend | ⏳ | Capture unhandled errors, failed requests. |
| Sentry on Flutter app | ⏳ | Capture client-side errors. |

### 4.2 Uptime & health
| Task | Status | Notes |
|------|--------|-------|
| Health check endpoint | ✅ | `GET /api/health`. |
| Uptime monitoring (UptimeRobot / Pingdom) | ⏳ | Ping `/api/health` every 5 min. |

### 4.3 Backups
| Task | Status | Notes |
|------|--------|-------|
| Postgres automated backups | ⏳ | Daily; retain 7–30 days. Use DB provider (Railway, etc.). |
| Backup restore tested | ⏳ | Document + periodic test. |

### 4.4 Load testing
| Task | Status | Notes |
|------|--------|-------|
| Load test: login, search, available-slots, booking, payment flow | ⏳ | k6 or Artillery. |
| Document baseline (RPS, p95 latency) | ⏳ | Before launch. |

---

## 5. Legal & compliance

### 5.1 Policies (publish & link)
| Task | Status | Notes |
|------|--------|-------|
| Privacy Policy | ⏳ | What data you collect, store, retain; GDPR basics. |
| Terms of Service | ⏳ | Usage rules, liability, governing law. |
| Refund / Cancellation policy | ⏳ | Align with in-app logic; Stripe-compatible. |
| Links in app (e.g. Settings, footer, booking) | ⏳ | |

### 5.2 GDPR basics
| Task | Status | Notes |
|------|--------|-------|
| Data deletion request flow | ⏳ | e.g. “Delete my account” → remove/anonymize user data. |
| Retention: define how long you keep data | ⏳ | In Privacy Policy. |
| Document: location, phone, payment data stored | ⏳ | Privacy Policy. |

### 5.3 Payments
| Task | Status | Notes |
|------|--------|-------|
| Stripe handles PCI | ✅ | No raw card data on your server. |
| Policies clear on fees, refunds, chargebacks | ⏳ | ToS + Refund policy. |

---

## 6. App Store / Play Store readiness

### 6.1 Assets & listing
| Task | Status | Notes |
|------|--------|-------|
| App icons (all required sizes) | ⏳ | iOS + Android. |
| Screenshots (phone + tablet if supported) | ⏳ | |
| Short + full description | ⏳ | |
| Age rating | ⏳ | |
| Support URL + support email | ⏳ | |

### 6.2 Build & release
| Task | Status | Notes |
|------|--------|-------|
| Apple: signing, bundle ID, versioning | ⏳ | |
| Google: signing, package name, versioning | ⏳ | |
| Location permission strings (why you need it) | ⏳ | iOS `Info.plist`, Android manifest. |

### 6.3 Testing & rollout
| Task | Status | Notes |
|------|--------|-------|
| TestFlight (iOS) closed testing | ⏳ | |
| Play Console internal/closed testing | ⏳ | |
| Staged rollout (e.g. 10% → 50% → 100%) | ⏳ | |

---

## 7. Operational readiness

### 7.1 Admin capabilities
| Task | Status | Notes |
|------|--------|-------|
| Admin panel or admin API | ⏳ | Even minimal (CRUD users, providers, appointments). |
| View users / providers / appointments / payments | ⏳ | |
| Issue refunds (Stripe + internal state) | ⏳ | |
| Remove abusive reviews / images | ⏳ | |

### 7.2 Support
| Task | Status | Notes |
|------|--------|-------|
| “Contact support” form in app | ⏳ | |
| Support emails → ticket/conversation | ⏳ | Manual or tool (e.g. Zendesk, email). |
| Support URL + email in store listing & app | ⏳ | |

---

## Quick reference: API additions

- `GET /api/policies/cancellation` — platform cancellation & refund policy (for in-app).
- `GET /api/policies/terms` — Terms of Service (or redirect to URL).
- `GET /api/policies/privacy` — Privacy Policy (or redirect to URL).
- `POST /api/reviews/:id/report` — report review.
- `POST /api/provider-images/:id/report` — report image. ✅
- `POST /api/support/contact` — submit support request. ⏳
- Idempotency: `Idempotency-Key` header on `POST /api/appointments`, `POST /api/payments/create-intent`. ✅
- Audit: `utils/audit.ts` logs payment + appointment events. ✅

---

## Suggested order of implementation

1. **Week 1:** Booking safety — holds in available-slots, idempotency, platform cancellation policy + in-app.
2. **Week 2:** Search — canonical categories/subcategories, tabs (Services | Providers), filters, provider onboarding filter.
3. **Week 3:** Security — rate limits (search, payments), audit logs, report review/image.
4. **Week 4:** Operations — admin endpoints (or minimal admin UI), support contact form.
5. **Ongoing:** Postgres migration, Sentry, uptime, backups, load tests, legal policies, store readiness.

Use this checklist to track progress and ensure nothing is missed before launch.
