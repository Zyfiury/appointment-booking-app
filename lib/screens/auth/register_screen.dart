import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/layered_card.dart';
import '../../providers/theme_provider.dart';
import '../../utils/validators.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'customer';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final colors = AppTheme.getColors(themeProvider.currentTheme);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Passwords do not match'),
            ],
          ),
          backgroundColor: colors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      role: _selectedRole,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
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
          authProvider.lastError ?? 'Registration failed. Please try again.';
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final colors = AppTheme.getColors(themeProvider.currentTheme);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: colors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildAnimatedField({
    required Widget child,
    required int index,
  }) {
    return SlideInWidget(
      duration: Duration(milliseconds: 600 + (index * 100)),
      offset: const Offset(0, 0.3),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  FadeInWidget(
                    child: FloatingCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Account',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign up to get started',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.textSecondary,
                                  fontSize: 15,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FloatingCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAnimatedField(
                          index: 0,
                          child: TextFormField(
                            controller: _nameController,
                            style: TextStyle(fontSize: 16, color: colors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.person_outlined,
                                  color: colors.primaryColor,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: Validators.name,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAnimatedField(
                          index: 1,
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(fontSize: 16, color: colors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.email_outlined,
                                  color: colors.primaryColor,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: Validators.email,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAnimatedField(
                          index: 2,
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(fontSize: 16, color: colors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Phone (Optional)',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.phone_outlined,
                                  color: colors.primaryColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAnimatedField(
                          index: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colors.borderColor,
                                width: 1.5,
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedRole,
                              dropdownColor: colors.cardColor,
                              style: TextStyle(color: colors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Account Type',
                                prefixIcon: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.account_circle_outlined,
                                    color: colors.primaryColor,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 20,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'customer',
                                  child: Text('Customer'),
                                ),
                                DropdownMenuItem(
                                  value: 'provider',
                                  child: Text('Service Provider'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAnimatedField(
                          index: 4,
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(fontSize: 16, color: colors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.lock_outlined,
                                  color: colors.primaryColor,
                                  size: 20,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: colors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: Validators.simplePassword,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAnimatedField(
                          index: 5,
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: TextStyle(fontSize: 16, color: colors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.lock_outlined,
                                  color: colors.primaryColor,
                                  size: 20,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: colors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) => Validators.passwordMatch(
                              value,
                              _passwordController.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SlideInWidget(
                          duration: const Duration(milliseconds: 1200),
                          offset: const Offset(0, 0.3),
                          child: Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              return AnimatedButton(
                                text: 'Create Account',
                                icon: Icons.person_add_rounded,
                                isLoading: authProvider.loading,
                                onPressed:
                                    authProvider.loading ? null : _handleRegister,
                                backgroundColor: colors.primaryColor,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInWidget(
                    duration: const Duration(milliseconds: 1300),
                    child: LayeredCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: colors.primaryColor,
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
