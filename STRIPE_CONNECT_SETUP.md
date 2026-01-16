# 💳 Stripe Connect Setup - Automatic Payment Splitting

## Current State vs. What You Need

### ❌ Current State
- Commission is **calculated and tracked** in database
- But money is **NOT actually split**
- Payments are just recorded, not transferred

### ✅ What You Need
- **Stripe Connect** (marketplace payments)
- Providers connect their bank accounts
- Money automatically splits:
  - 15% → Your platform account
  - 85% → Provider's connected account

---

## How Stripe Connect Works

### 1. Provider Account Setup
Providers need to:
- Connect their Stripe account (or create one)
- Provide bank account details
- Get verified by Stripe

### 2. Payment Flow
1. Customer pays $100
2. Stripe automatically splits:
   - $15 → Your platform account
   - $85 → Provider's connected account
3. Both transfers happen automatically
4. No manual intervention needed

---

## Implementation Steps

### Step 1: Set Up Stripe Connect

1. **Create Stripe Account**
   - Go to https://stripe.com
   - Sign up for a Connect account (marketplace)
   - Get your API keys

2. **Install Stripe SDK**
   ```bash
   cd server
   npm install stripe
   ```

3. **Add Stripe Keys to Railway**
   - `STRIPE_SECRET_KEY` - Your Stripe secret key
   - `STRIPE_PUBLISHABLE_KEY` - Your Stripe publishable key

### Step 2: Add Provider Account Fields

Providers need to store their Stripe account ID:

**Database Schema:**
```sql
ALTER TABLE users ADD COLUMN stripe_account_id VARCHAR(255);
```

### Step 3: Provider Onboarding Flow

Providers need to:
1. Click "Connect Bank Account" in settings
2. Redirect to Stripe Connect onboarding
3. Complete verification
4. Store their `stripe_account_id` in database

### Step 4: Update Payment Processing

Use Stripe Connect to split payments automatically.

---

## Code Implementation

I'll implement this for you. Here's what needs to be done:

1. ✅ Add Stripe SDK to backend
2. ✅ Add provider Stripe account connection
3. ✅ Update payment processing to use Stripe Connect
4. ✅ Add provider onboarding screen
5. ✅ Handle automatic transfers

---

## Stripe Connect Pricing

- **Standard Connect**: 2.9% + $0.30 per transaction (you pay)
- **Express Connect**: Provider pays fees, you get your commission
- **Custom Connect**: Full control, more complex

**Recommended**: Express Connect (providers pay fees, you get 15% commission)

---

## Next Steps

I'll implement the full Stripe Connect integration for you. This includes:

1. Provider account connection flow
2. Automatic payment splitting
3. Transfer management
4. Error handling

Ready to implement? Let me know and I'll add it all!
