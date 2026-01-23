# Email Verification Guide

## Overview

The app now includes email verification functionality. When users sign up, they receive a 6-digit verification code via email and must verify their email before accessing all features.

## How It Works

1. **Registration**: When a user registers, they receive a 6-digit verification code via email
2. **Verification**: User enters the code in the app to verify their email
3. **Resend**: Users can request a new code if the original expires or is lost
4. **Login**: Users can still login without verification, but will see a warning

## API Endpoints

### 1. Register (Modified)
**POST** `/api/auth/register`

Now sends a verification code and sets `emailVerified: false` by default.

**Response:**
```json
{
  "token": "jwt-token",
  "user": {
    "id": "user-id",
    "email": "user@example.com",
    "name": "User Name",
    "emailVerified": false
  },
  "verificationCode": "123456",  // Only in development mode
  "message": "Registration successful! Please check your email for the verification code."
}
```

### 2. Verify Email
**POST** `/api/auth/verify-email`

**Headers:**
```
Authorization: Bearer <token>
```

**Body:**
```json
{
  "code": "123456"
}
```

**Response:**
```json
{
  "message": "Email verified successfully",
  "token": "new-jwt-token",  // Updated token with emailVerified: true
  "user": {
    "id": "user-id",
    "email": "user@example.com",
    "emailVerified": true
  }
}
```

### 3. Resend Verification Code
**POST** `/api/auth/resend-verification`

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "message": "Verification code sent successfully",
  "verificationCode": "123456"  // Only in development mode
}
```

### 4. Login (Modified)
**POST** `/api/auth/login`

Now includes `emailVerified` status in response and shows a warning if not verified.

**Response:**
```json
{
  "token": "jwt-token",
  "user": {
    "id": "user-id",
    "email": "user@example.com",
    "emailVerified": false
  },
  "warning": "Please verify your email address to access all features."
}
```

## Verification Code Details

- **Format**: 6-digit numeric code (e.g., `123456`)
- **Expiration**: 15 minutes
- **Storage**: In-memory Map (use Redis/database in production)
- **Single Use**: Code is deleted after successful verification

## Google Sign-In

Users who sign in with Google are automatically marked as verified (`emailVerified: true`) since Google already verifies email addresses.

## Development Mode

In development (`NODE_ENV=development`):
- Verification codes are logged to console
- Codes are returned in API responses for testing
- Email sending is optional (logs to console if not configured)

## Production Considerations

1. **Storage**: Replace in-memory Maps with Redis or database
2. **Rate Limiting**: Already applied via `authRateLimit` middleware
3. **Email Service**: Configure SMTP (see `EMAIL_SETUP.md`)
4. **Security**: Consider adding:
   - Maximum verification attempts per hour
   - IP-based rate limiting
   - Code complexity requirements

## Frontend Integration

The Flutter app should:
1. Show verification screen after registration
2. Allow users to enter the 6-digit code
3. Handle verification success/failure
4. Show "Resend Code" option
5. Display warning banner if email not verified
6. Optionally restrict certain features until verified

## Testing

1. **Without Email Setup:**
   - Register a new user
   - Check console logs for verification code
   - Use code to verify email

2. **With Email Setup:**
   - Register a new user
   - Check email for verification code
   - Enter code in app to verify

## Security Notes

- Codes expire after 15 minutes
- Codes are single-use (deleted after verification)
- Rate limiting prevents code spam
- Invalid codes don't reveal if user exists
- JWT tokens include `emailVerified` status
