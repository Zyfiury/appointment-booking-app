import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/layered_card.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import '../../providers/theme_provider.dart';


class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;
  bool _success = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    setState(() {
      _loading = true;
    });

    try {
      final success = await _authService.resetPassword(
        token: widget.token,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _success = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset password. The link may have expired.'),
            backgroundColor: colors.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: colors.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('Reset Password'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.backgroundGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeInWidget(
              child: FloatingCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(24),
                child: _success
                    ? _buildSuccessView(colors)
                    : _buildFormView(colors),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(ThemeColors colors) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: colors.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your new password below.',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: colors.textPrimary),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'New Password',
              labelStyle: TextStyle(color: colors.textSecondary),
              prefixIcon: Icon(Icons.lock_outline, color: colors.primaryColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: colors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: colors.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: TextStyle(color: colors.textPrimary),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              labelStyle: TextStyle(color: colors.textSecondary),
              prefixIcon: Icon(Icons.lock_outline, color: colors.primaryColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: colors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              filled: true,
              fillColor: colors.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedButton(
            text: 'Reset Password',
            onPressed: _loading ? null : _resetPassword,
            isLoading: _loading,
            backgroundColor: colors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(ThemeColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          size: 64,
          color: colors.accentColor,
        ),
        const SizedBox(height: 24),
        Text(
          'Password Reset!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your password has been successfully reset. Redirecting to login...',
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
