# 💰 Automatic Payment Splitting - Complete Guide

## ✅ What's Implemented

I've implemented **Stripe Connect** for automatic payment splitting. Here's how it works:

---

## 🔄 How Payment Splitting Works

### The Flow

1. **Provider connects their bank account**
   - Provider goes to settings
   - Clicks "Connect Payment Account"
   - Completes Stripe onboarding
   - Their Stripe account ID is saved

2. **Customer pays for service**
   - Customer pays $100 for a service
   - Payment goes through Stripe

3. **Automatic split happens**
   - **$15 (15%)** → Goes to **your platform account** automatically
   - **$85 (85%)** → Goes to **provider's connected account** automatically
   - Both transfers happen instantly
   - No manual work needed!

---

## 📋 Setup Required

### 1. Stripe Account Setup

1. **Create Stripe Account**
   - Go to https://stripe.com
   - Sign up for a **Connect** account (marketplace)
   - Complete business verification

2. **Get API Keys**
   - Go to Stripe Dashboard → Developers → API keys
   - Copy your **Secret Key** and **Publishable Key**

3. **Add to Railway Environment Variables**
   - Go to Railway → Your backend service → Variables
   - Add:
     - `STRIPE_SECRET_KEY` = `sk_live_...` (or `sk_test_...` for testing)
     - `STRIPE_PUBLISHABLE_KEY` = `pk_live_...` (or `pk_test_...` for testing)
   - Also add to your Flutter app config

4. **Set Frontend URL** (for Stripe redirects)
   - Add: `FRONTEND_URL` = `https://your-app-url.com` (or localhost for dev)

---

## 🎯 How Providers Connect Their Accounts

### Backend Endpoints Created

1. **Create Connect Account**
   ```
   POST /api/stripe/connect/create
   ```
   - Creates Stripe Connect account for provider
   - Returns onboarding URL
   - Provider completes onboarding on Stripe

2. **Check Account Status**
   ```
   GET /api/stripe/connect/status
   ```
   - Checks if provider's account is ready
   - Returns: `chargesEnabled`, `payoutsEnabled`, etc.

3. **Get Dashboard Link**
   ```
   GET /api/stripe/connect/login
   ```
   - Provider can access their Stripe dashboard
   - View payments, payouts, etc.

---

## 💳 Payment Processing

### When Customer Pays

1. **Payment Intent Created**
   - Uses Stripe Connect
   - Automatically splits: 15% to you, 85% to provider
   - Both amounts calculated automatically

2. **Payment Confirmed**
   - Money is split instantly
   - Platform gets commission
   - Provider gets their share
   - All tracked in database

---

## 📱 What Providers Need to Do

### Step 1: Connect Account

1. Provider logs into app
2. Goes to Settings
3. Clicks "Connect Payment Account"
4. Redirected to Stripe onboarding
5. Enters bank account details
6. Completes verification
7. Account is connected!

### Step 2: Receive Payments

- Once connected, all future payments automatically go to their account
- They can view payments in Stripe dashboard
- Money transfers to their bank automatically (usually 2-7 days)

---

## 🔧 Technical Details

### Database Changes

- Added `stripe_account_id` to `users` table
- Stores provider's Stripe Connect account ID
- Used for automatic transfers

### Payment Flow

```typescript
// When customer pays $100:
1. Create payment intent with:
   - Total: $100
   - Application fee: $15 (your commission)
   - Transfer: $85 to provider

2. Stripe automatically:
   - Charges customer $100
   - Keeps $15 in your account
   - Transfers $85 to provider's account
```

---

## ⚠️ Important Notes

### For Testing

- Use **Stripe Test Mode** first
- Test keys start with `sk_test_` and `pk_test_`
- Use test card: `4242 4242 4242 4242`
- No real money is transferred

### For Production

- Switch to **Live Mode**
- Use keys starting with `sk_live_` and `pk_live_`
- Complete Stripe account verification
- Real money will be transferred

### Provider Requirements

- Providers MUST connect their account before receiving payments
- If not connected, payment will fail with error message
- They can connect anytime from settings

---

## 🚨 Error Handling

### Provider Not Connected

If provider hasn't connected their account:
```json
{
  "error": "Provider has not connected their payment account. Please contact the provider."
}
```

### Stripe Not Configured

If `STRIPE_SECRET_KEY` is not set:
- System falls back to mock payments
- Commission is still calculated and tracked
- But no actual money transfer happens

---

## 📊 Monitoring

### Check Provider Account Status

```bash
GET /api/stripe/connect/status
```

Response:
```json
{
  "connected": true,
  "accountId": "acct_...",
  "chargesEnabled": true,
  "payoutsEnabled": true,
  "detailsSubmitted": true,
  "ready": true
}
```

### View Payments in Stripe Dashboard

- Platform dashboard: All payments, your commission
- Provider dashboard: Their payments, their earnings

---

## 🎯 Next Steps

### 1. Set Up Stripe Account
- [ ] Create Stripe account
- [ ] Enable Connect
- [ ] Get API keys
- [ ] Add to Railway environment variables

### 2. Test Payment Flow
- [ ] Create test provider account
- [ ] Connect Stripe test account
- [ ] Make test payment
- [ ] Verify split works

### 3. Add Provider UI (Optional)
- [ ] Add "Connect Payment Account" button in settings
- [ ] Show connection status
- [ ] Add link to Stripe dashboard

---

## 💡 How It Works Behind the Scenes

### Stripe Connect Marketplace Model

```
Customer pays $100
    ↓
Stripe charges $100
    ↓
    ├─→ $15 (application_fee) → Your Stripe account
    └─→ $85 (transfer) → Provider's connected account
```

### Database Tracking

Every payment stores:
- `amount`: $100 (total)
- `platform_commission`: $15 (your share)
- `provider_amount`: $85 (provider's share)
- `commission_rate`: 15.00%

---

## ✅ Summary

**What you have now:**
- ✅ Stripe Connect integration
- ✅ Automatic payment splitting (15% / 85%)
- ✅ Provider account connection
- ✅ Commission tracking
- ✅ Error handling

**What you need to do:**
1. Set up Stripe account
2. Add API keys to Railway
3. Test the flow
4. (Optional) Add provider UI for connecting accounts

**Result:**
- Money automatically splits on every payment
- You get 15% instantly
- Provider gets 85% instantly
- All tracked in database

---

The system is ready! Just add your Stripe keys and it will work automatically. 🎉
