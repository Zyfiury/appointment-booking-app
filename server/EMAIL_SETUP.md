# Email Configuration Guide

## Password Reset Email Setup

The forgot password feature now sends actual emails to users. Here's how to configure it:

## Environment Variables

Add these to your `.env` file or Railway environment variables:

```bash
# SMTP Configuration (for sending emails)
SMTP_HOST=smtp.gmail.com          # Your SMTP server
SMTP_PORT=587                     # Port (587 for TLS, 465 for SSL)
SMTP_USER=your-email@gmail.com    # Your email address
SMTP_PASSWORD=your-app-password   # Your email password or app password
SMTP_FROM=noreply@bookly.app      # From address (optional, defaults to SMTP_USER)

# Frontend URL (for reset password links)
FRONTEND_URL=https://yourapp.com  # Your frontend URL where users reset passwords
```

## Email Provider Examples

### Gmail

```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password  # Use App Password, not regular password
SMTP_FROM=noreply@bookly.app
```

**Note:** For Gmail, you need to:
1. Enable 2-Factor Authentication
2. Generate an "App Password" (not your regular password)
3. Use the App Password in `SMTP_PASSWORD`

### SendGrid

```bash
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASSWORD=your-sendgrid-api-key
SMTP_FROM=noreply@bookly.app
```

### Mailgun

```bash
SMTP_HOST=smtp.mailgun.org
SMTP_PORT=587
SMTP_USER=your-mailgun-username
SMTP_PASSWORD=your-mailgun-password
SMTP_FROM=noreply@bookly.app
```

### Outlook/Hotmail

```bash
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_USER=your-email@outlook.com
SMTP_PASSWORD=your-password
SMTP_FROM=noreply@bookly.app
```

## Development Mode

If email is **not configured**, the system will:
- Still generate reset tokens
- Log the reset link to console (for testing)
- Return the token in the API response (development only)

This allows you to test password reset without setting up email.

## Testing

1. **Without Email Setup (Development):**
   - Request password reset: `POST /api/auth/forgot-password`
   - Check console logs for reset token
   - Or check API response (in development mode)

2. **With Email Setup (Production):**
   - Request password reset: `POST /api/auth/forgot-password`
   - User receives email with reset link
   - User clicks link and resets password

## Email Template

The password reset email includes:
- Professional HTML design
- Reset button
- Plain text link
- 1-hour expiration notice
- Security message

## Security Notes

- Reset tokens expire after 1 hour
- Tokens are single-use (deleted after password reset)
- Email addresses are not revealed if user doesn't exist
- Rate limiting applies to prevent abuse
