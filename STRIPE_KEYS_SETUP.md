# 🔑 Stripe Keys Setup - Quick Reference

## ✅ Publishable Key (Already Added)

The publishable key has been added to your Flutter app config:
- File: `lib/config/app_config.dart`
- Key: `pk_test_51SqAuM6iKaCjKdK7YUop4uN3MgIMBVmoGG5rgDxs8339SBKFkrQDjyX8yNUaRRu0C2dmNOhp3jpL9UxA8tCjFruU00pGh45zqQ`

✅ **This is done!** Publishable keys are safe to include in code.

---

## ⚠️ Secret Key (Add to Railway)

**IMPORTANT:** The secret key must be added to Railway environment variables, NOT in code!

### Steps to Add Secret Key to Railway:

1. **Go to Railway Dashboard**
   - Visit https://railway.app
   - Open your project
   - Click on your **backend service** (accurate-solace)

2. **Add Environment Variable**
   - Click **"Variables"** tab
   - Click **"+ New Variable"**
   - Key: `STRIPE_SECRET_KEY`
   - Value: `sk_test_...` (your secret key - starts with `sk_test_` for test mode)
   - Click **"Add"**
   
   **⚠️ Important:** Never commit secret keys to code! Only add them to Railway environment variables.

3. **Add Frontend URL** (for Stripe redirects)
   - Click **"+ New Variable"** again
   - Key: `FRONTEND_URL`
   - Value: `https://your-app-url.com` (or `http://localhost:3000` for local testing)
   - Click **"Add"**

4. **Redeploy**
   - Railway will automatically redeploy when you add variables
   - Or manually trigger a new deployment

---

## ✅ Verification Checklist

- [ ] `STRIPE_SECRET_KEY` added to Railway
- [ ] `FRONTEND_URL` added to Railway
- [ ] Backend service redeployed
- [ ] Test payment flow works

---

## 🧪 Testing

### Test Card Numbers (Stripe Test Mode)

- **Success**: `4242 4242 4242 4242`
- **Decline**: `4000 0000 0000 0002`
- **3D Secure**: `4000 0025 0000 3155`

**Any future expiry date and any 3-digit CVC will work.**

---

## 🔄 After Adding Keys

1. **Test Provider Account Connection**
   - Create a test provider account
   - Call: `POST /api/stripe/connect/create`
   - Complete Stripe onboarding
   - Verify account is connected

2. **Test Payment**
   - Book an appointment
   - Pay with test card: `4242 4242 4242 4242`
   - Verify payment splits correctly

---

## 🚨 Security Notes

- ✅ **Publishable Key**: Safe in code (already added)
- ⚠️ **Secret Key**: Must be in Railway only, never commit to code
- ✅ **Test Keys**: Safe to use for development
- ⚠️ **Production**: Get live keys from Stripe when ready for production

---

## 📝 Next Steps

1. Add `STRIPE_SECRET_KEY` to Railway (see steps above)
2. Add `FRONTEND_URL` to Railway
3. Test the payment flow
4. When ready for production, get live keys from Stripe

---

**Your Stripe keys are configured!** Just add the secret key to Railway and you're ready to test. 🎉
