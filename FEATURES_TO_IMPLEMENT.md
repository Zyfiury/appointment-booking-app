# Features to Implement Before Launch

## ✅ What's Already Working

- ✅ User registration & login
- ✅ Provider search & filters
- ✅ Google Maps integration
- ✅ Appointment booking
- ✅ Reviews & ratings
- ✅ Local notifications
- ✅ Provider dashboard
- ✅ Service management
- ✅ Location setting for providers

---

## 🔴 Critical Missing Features (Must Add Before Launch)

### 1. **Profile Editing** ❌
**Current Status**: Shows "Coming Soon" in settings
**Impact**: HIGH - Users expect to edit their profile
**Estimated Time**: 2-3 hours

**What to implement:**
- Edit profile screen
- Update name, email, phone number
- Backend endpoint integration
- Form validation
- Success/error handling

---

### 2. **Profile Picture Upload** ❌
**Current Status**: Only shows initial letter (no image upload)
**Impact**: HIGH - Standard feature users expect
**Estimated Time**: 3-4 hours

**What to implement:**
- Add `profilePicture` field to User model
- Image picker integration (package already installed)
- Image upload to backend (need backend endpoint)
- Display profile pictures in:
  - Settings screen
  - Provider cards
  - Reviews
- Default avatar when no picture
- Image caching

---

### 3. **Google Sign In** ❌
**Current Status**: Not implemented
**Impact**: MEDIUM-HIGH - Many users prefer social login
**Estimated Time**: 4-5 hours

**What to implement:**
- Add `google_sign_in` package
- Google OAuth setup
- Sign in flow
- Backend endpoint for Google auth
- Link Google account to existing account
- Handle existing users

---

### 4. **Payment Integration Verification** ⚠️
**Current Status**: UI exists but needs full Stripe integration
**Impact**: HIGH - Critical for booking
**Estimated Time**: 3-4 hours

**What to verify/fix:**
- Stripe SDK integration (currently simulated)
- Payment intent creation
- Payment confirmation
- Error handling
- Receipt generation
- Payment history

---

### 5. **Password Reset / Forgot Password** ❌
**Current Status**: Not implemented
**Impact**: MEDIUM - Users will need this
**Estimated Time**: 2-3 hours

**What to implement:**
- Forgot password screen
- Email verification
- Password reset flow
- Backend endpoint
- Reset token handling

---

## 🟡 Important Features (Should Add Soon)

### 6. **Email Verification** ❌
**Impact**: MEDIUM
**Time**: 2-3 hours

### 7. **Change Password** ❌
**Impact**: MEDIUM
**Time**: 1-2 hours

### 8. **Delete Account** ❌
**Impact**: MEDIUM (GDPR requirement)
**Time**: 1-2 hours

---

## 📊 Implementation Priority

### **Phase 1: Before Launch** (1-2 weeks)
1. ✅ Profile Editing
2. ✅ Profile Picture Upload
3. ✅ Payment Integration (verify & complete)
4. ✅ Password Reset

**Total Time**: ~10-14 hours

### **Phase 2: Post-Launch v1.1** (2-3 weeks)
5. ✅ Google Sign In
6. ✅ Email Verification
7. ✅ Change Password
8. ✅ Delete Account

**Total Time**: ~10-12 hours

---

## 🎯 Recommended Approach

### **Option A: Launch with Core Features** ⭐ Recommended
**Add before launch:**
- Profile Editing
- Profile Picture Upload
- Payment Verification
- Password Reset

**Launch timeline**: 1-2 weeks

**Add in v1.1:**
- Google Sign In
- Email Verification
- Change Password
- Delete Account

---

### **Option B: Full Feature Launch**
**Wait and add everything before launch**

**Launch timeline**: 3-4 weeks

---

## 📝 Implementation Checklist

### Profile Editing
- [ ] Create `edit_profile_screen.dart`
- [ ] Add form fields (name, email, phone)
- [ ] Add validation
- [ ] Integrate with backend `/users/profile` PATCH endpoint
- [ ] Update AuthProvider
- [ ] Add navigation from settings
- [ ] Test update flow

### Profile Picture
- [ ] Add `profilePicture` to User model
- [ ] Create image picker service
- [ ] Add image upload endpoint to backend
- [ ] Update settings screen to show image
- [ ] Add image picker button
- [ ] Add image caching
- [ ] Update provider cards to show images
- [ ] Add default avatar

### Google Sign In
- [ ] Add `google_sign_in` package
- [ ] Set up Google OAuth credentials
- [ ] Create Google sign in service
- [ ] Add backend endpoint for Google auth
- [ ] Update login screen with Google button
- [ ] Handle account linking
- [ ] Test sign in flow

### Payment Verification
- [ ] Verify Stripe keys are configured
- [ ] Test payment intent creation
- [ ] Complete Stripe SDK integration
- [ ] Test payment flow end-to-end
- [ ] Add proper error handling
- [ ] Test with test cards
- [ ] Verify payment records are saved

### Password Reset
- [ ] Create forgot password screen
- [ ] Add backend endpoint for password reset
- [ ] Add email sending (or use service)
- [ ] Create reset password screen
- [ ] Add token validation
- [ ] Test reset flow

---

## 🚀 Next Steps

1. **Decide on launch strategy** (Option A or B)
2. **Prioritize features** based on user needs
3. **Implement Phase 1 features**
4. **Test thoroughly**
5. **Launch with core features**
6. **Iterate based on feedback**

---

**My Recommendation**: Implement Phase 1 features (Profile Edit, Profile Picture, Payment Verification, Password Reset) before launch. These are expected by users and won't take long. Add Google Sign In and other features in v1.1 update.
