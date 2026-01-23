import express, { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { db } from '../data/database';
import { authenticate, AuthRequest } from '../middleware/auth';
<<<<<<< HEAD
import { authRateLimit } from '../middleware/rateLimit';
import { validate, schemas } from '../middleware/validation';
=======
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

<<<<<<< HEAD
// Store for password reset tokens (in production, use Redis or database)
const passwordResetTokens = new Map<string, { userId: string; expiresAt: number }>();

router.post('/register', validate(schemas.register), async (req: Request, res: Response) => {
  try {
    const { email, password, name, role, phone } = req.body;

    const existingUser = db.getUserByEmail(email);
=======
router.post('/register', async (req: Request, res: Response) => {
  try {
    const { email, password, name, role, phone } = req.body;

    if (!email || !password || !name || !role) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    if (role !== 'customer' && role !== 'provider') {
      return res.status(400).json({ error: 'Invalid role' });
    }

    const existingUser = await db.getUserByEmail(email);
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
    if (existingUser) {
      return res.status(400).json({ error: 'User already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
<<<<<<< HEAD
    const user = db.createUser({
=======
    const user = await db.createUser({
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
      email,
      password: hashedPassword,
      name,
      role,
      phone,
    });

    const token = jwt.sign(
      { userId: user.id, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        phone: user.phone,
<<<<<<< HEAD
        profilePicture: user.profilePicture,
=======
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

<<<<<<< HEAD
router.post('/login', authRateLimit, validate(schemas.login), async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    const user = db.getUserByEmail(email);
=======
router.post('/login', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const user = await db.getUserByEmail(email);
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { userId: user.id, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        phone: user.phone,
<<<<<<< HEAD
        profilePicture: user.profilePicture,
=======
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

<<<<<<< HEAD
router.post('/forgot-password', authRateLimit, async (req: Request, res: Response) => {
  try {
    const { email } = req.body;
=======
router.post('/google', async (req: Request, res: Response) => {
  try {
    const { idToken, accessToken, email, name, photoUrl } = req.body;
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

<<<<<<< HEAD
    const user = db.getUserByEmail(email);
    if (!user) {
      // Don't reveal if user exists for security
      return res.json({ message: 'If the email exists, a reset link has been sent' });
    }

    // Generate reset token
    const resetToken = jwt.sign(
      { userId: user.id, type: 'password-reset' },
      JWT_SECRET,
      { expiresIn: '1h' }
    );

    // Store token (in production, store in database)
    passwordResetTokens.set(resetToken, {
      userId: user.id,
      expiresAt: Date.now() + 3600000, // 1 hour
    });

    // In production, send email with reset link
    // For now, just return the token (in production, send via email)
    console.log(`Password reset token for ${email}: ${resetToken}`);
    console.log(`Reset link: https://yourapp.com/reset-password?token=${resetToken}`);

    res.json({ 
      message: 'If the email exists, a reset link has been sent',
      // In development, return token. Remove in production!
      token: process.env.NODE_ENV === 'development' ? resetToken : undefined,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/reset-password', async (req: Request, res: Response) => {
  try {
    const { token, newPassword } = req.body;

    if (!token || !newPassword) {
      return res.status(400).json({ error: 'Token and new password are required' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    // Verify token
    let decoded: any;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch (error) {
      return res.status(400).json({ error: 'Invalid or expired token' });
    }

    // Check if token is in store
    const tokenData = passwordResetTokens.get(token);
    if (!tokenData || tokenData.expiresAt < Date.now()) {
      return res.status(400).json({ error: 'Invalid or expired token' });
    }

    // Update password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    const updated = db.updateUser(tokenData.userId, { password: hashedPassword });

    if (!updated) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Remove used token
    passwordResetTokens.delete(token);

    res.json({ message: 'Password reset successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/google', async (req: Request, res: Response) => {
  try {
    const { idToken, email, name, photoUrl } = req.body;

    if (!email || !name) {
      return res.status(400).json({ error: 'Email and name are required' });
    }

    // In production, verify idToken with Google
    // For now, check if user exists or create new one
    let user = db.getUserByEmail(email);

    if (!user) {
      // Create new user with Google account
      user = db.createUser({
        email,
        password: '', // No password for Google users
        name,
        role: 'customer', // Default role
        profilePicture: photoUrl,
      });
    } else {
      // Update profile picture if provided
      if (photoUrl && !user.profilePicture) {
        db.updateUser(user.id, { profilePicture: photoUrl });
        user = db.getUserById(user.id);
      }
    }

    // Defensive: db.getUserById can return undefined; ensure we always have a user object.
    if (!user) {
      return res.status(500).json({ error: 'Failed to load user after Google sign-in' });
    }

=======
    // Check if user exists
    let user = await db.getUserByEmail(email);

    if (!user) {
      // Create new user from Google account
      // Default role to 'customer', can be changed later
      user = await db.createUser({
        email,
        password: '', // Google users don't have a password
        name: name || 'Google User',
        role: 'customer', // Default role
        phone: undefined,
        profilePicture: photoUrl || undefined,
      });
    } else {
      // Update profile picture if provided and different
      if (photoUrl && user.profilePicture !== photoUrl) {
        // Note: You might want to add an updateProfilePicture method to db
        // For now, we'll just use the existing user
      }
    }

    // Generate JWT token
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        phone: user.phone,
<<<<<<< HEAD
        profilePicture: user.profilePicture,
      },
    });
  } catch (error) {
=======
        profilePicture: user.profilePicture || photoUrl,
      },
    });
  } catch (error) {
    console.error('Google auth error:', error);
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
    res.status(500).json({ error: 'Server error' });
  }
});

<<<<<<< HEAD
router.get('/me', authenticate, (req: AuthRequest, res: Response) => {
  const user = db.getUserById(req.userId!);
=======
router.get('/me', authenticate, async (req: AuthRequest, res: Response) => {
  const user = await db.getUserById(req.userId!);
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }

  res.json({
    id: user.id,
    email: user.email,
    name: user.name,
    role: user.role,
    phone: user.phone,
    profilePicture: user.profilePicture,
  });
});

export default router;
