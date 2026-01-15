import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/layered_card.dart';
import '../../widgets/app_logo.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final user = authProvider.user;
      if (user?.isProvider == true) {
        Navigator.pushReplacementNamed(context, '/provider/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      final errorMessage =
          authProvider.lastError ?? 'Login failed. Please check your credentials.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Animated Logo
                  FadeInWidget(
                    duration: const Duration(milliseconds: 800),
                    child: Center(
                      child: ScaleTransition(
                        scale: _logoAnimation,
                        child: const AppLogo(
                          size: 100,
                          showText: true,
                          fontSize: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Title Card (Layered)
                  FloatingCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Welcome Back',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sign in to continue to your account',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 15,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Form Card (Layered)
                  FloatingCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email Field
                        SlideInWidget(
                          duration: const Duration(milliseconds: 700),
                          offset: const Offset(0, 0.3),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Password Field
                        SlideInWidget(
                          duration: const Duration(milliseconds: 800),
                          offset: const Offset(0, 0.3),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.lock_outlined,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Login Button
                        SlideInWidget(
                          duration: const Duration(milliseconds: 900),
                          offset: const Offset(0, 0.3),
                          child: Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              return AnimatedButton(
                                text: 'Sign In',
                                icon: Icons.login_rounded,
                                isLoading: authProvider.loading,
                                onPressed: authProvider.loading ? null : _handleLogin,
                                backgroundColor: AppTheme.primaryColor,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Register Link
                  FadeInWidget(
                    duration: const Duration(milliseconds: 1000),
                    child: LayeredCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      const RegisterScreen(),
                                  transitionsBuilder:
                                      (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
