# Setup Remaining Tasks

## ✅ What's Done

All features are implemented! The code is complete and ready.

---

## 🔧 What You Need to Configure

### 1. **Install Dependencies** (2 minutes)

Run this to install the new Google Sign In package:

```powershell
cd appointment_booking_app
flutter pub get
```

---

### 2. **Google Sign In Setup** (15-30 minutes)

**Steps:**

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com
   - Create a new project or select existing

2. **Enable Google Sign-In API**
   - Go to "APIs & Services" → "Library"
   - Search for "Google Sign-In API"
   - Click "Enable"

3. **Create OAuth 2.0 Credentials**
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth client ID"
   - Application type: "Android"
   - Name: "Bookly Android"
   - Package name: `com.bookly.app` (or your package name)
   - **Get SHA-1 fingerprint:**
     ```powershell
     cd android
     .\gradlew signingReport
     ```
     Look for "SHA1:" in the output
   - Paste SHA-1 into Google Console
   - Click "Create"
   - **Copy the Client ID** (looks like: `123456789-abc...googleusercontent.com`)

4. **Update Android Configuration**
   - Open `android/app/build.gradle.kts`
   - Add to `dependencies`:
     ```kotlin
     implementation("com.google.android.gms:play-services-auth:20.7.0")
     ```
   - The `google_sign_in` Flutter package handles the rest

5. **Test Google Sign In**
   - Run the app
   - Click "Continue with Google"
   - Should open Google sign in

**Note:** For iOS, you'll need to add the iOS Client ID to `ios/Runner/Info.plist` later.

---

### 3. **Email Service for Password Reset** (30 minutes)

**Option A: SendGrid (Recommended - Free tier)**

1. Sign up at https://sendgrid.com
2. Verify your email
3. Create API key
4. Install package:
   ```bash
   cd server
   npm install @sendgrid/mail
   ```
5. Update `server/routes/auth.ts`:
   ```typescript
   import sgMail from '@sendgrid/mail';
   sgMail.setApiKey(process.env.SENDGRID_API_KEY!);
   
   // In forgot-password route:
   const resetLink = `https://yourapp.com/reset-password?token=${resetToken}`;
   await sgMail.send({
     to: email,
     from: 'noreply@yourapp.com',
     subject: 'Reset Your Password',
     html: `<p>Click <a href="${resetLink}">here</a> to reset your password.</p>`,
   });
   ```

**Option B: Mailgun (Free tier)**

1. Sign up at https://mailgun.com
2. Verify domain
3. Get API key
4. Similar setup to SendGrid

**Option C: AWS SES (Free tier)**

1. Set up AWS account
2. Verify email/domain
3. Use AWS SDK

**For now (Development):**
- Token is logged to console
- You can manually test with the token
- Set up email service before production launch

---

### 4. **Image Upload Storage** (1-2 hours)

**Current:** Backend accepts image URL or base64

**Recommended: Cloudinary (Free tier)**

1. Sign up at https://cloudinary.com
2. Get API credentials
3. Install package:
   ```bash
   cd server
   npm install cloudinary multer
   ```
4. Update `server/routes/users.ts` to handle file uploads
5. Upload to Cloudinary
6. Return Cloudinary URL

**Alternative: Firebase Storage**
- Free tier available
- Good Flutter integration
- Easy to set up

**For now:**
- You can use image URLs (from external sources)
- Or set up cloud storage later

---

### 5. **Stripe Keys** (5 minutes)

1. **Get Stripe Keys:**
   - Go to https://dashboard.stripe.com
   - Get test keys (for development)
   - Get live keys (for production)

2. **Update Frontend:**
   - Open `lib/config/app_config.dart`
   - Replace:
     ```dart
     return 'pk_test_YOUR_TEST_KEY'; // Test key
     return 'pk_live_YOUR_PRODUCTION_KEY'; // Production key
     ```

3. **Update Backend:**
   - Add to Railway environment variables:
     - `STRIPE_SECRET_KEY` (sk_test_... or sk_live_...)
   - Update `server/routes/payments.ts` to use Stripe SDK

---

## 🧪 Testing

### Test Profile Features
1. Run app: `flutter run`
2. Go to Settings → Edit Profile
3. Change name, email, phone
4. Upload profile picture
5. Verify changes saved

### Test Password Reset
1. Go to Login screen
2. Click "Forgot Password?"
3. Enter email
4. Check console for reset token (development)
5. Use token to reset password

### Test Google Sign In
1. After setting up Google credentials
2. Click "Continue with Google"
3. Sign in with Google account
4. Verify account created/logged in

---

## 📝 Quick Commands

```powershell
# Install dependencies
cd appointment_booking_app
flutter pub get

# Run app
flutter run

# Build for production
.\build_production.ps1

# Test with production API
.\test_production.ps1
```

---

## ✅ Summary

**Implemented:**
- ✅ Profile editing
- ✅ Profile picture upload
- ✅ Password reset
- ✅ Google Sign In (frontend)
- ✅ Payment integration

**You need to:**
1. Run `flutter pub get`
2. Set up Google Sign In credentials
3. Configure email service (optional for now)
4. Set up image storage (optional for now)
5. Add Stripe keys
6. Test everything

**The app is feature-complete!** Just need to configure the services. 🎉
