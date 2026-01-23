import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/customer/dashboard_screen.dart';
import 'screens/customer/book_appointment_screen.dart';
import 'screens/customer/my_appointments_screen.dart';
import 'screens/provider/provider_dashboard_screen.dart';
import 'screens/provider/manage_services_screen.dart';
import 'screens/provider/provider_location_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/customer/search_screen.dart';
import 'screens/customer/map_screen.dart';
import 'screens/customer/payment_screen.dart';
import 'screens/customer/payment_history_screen.dart';
import 'screens/customer/review_screen.dart';
import 'screens/settings/edit_profile_screen.dart';
import 'screens/settings/help_support_screen.dart';
import 'screens/settings/chatbot_screen.dart';
import 'screens/settings/cancellation_policy_screen.dart';
import 'screens/settings/contact_support_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/customer/favorites_screen.dart';
import 'widgets/app_logo.dart';
import 'widgets/animated_route.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Bookly',
            theme: AppTheme.getTheme(themeProvider.currentTheme),
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
            onGenerateRoute: (settings) {
              // Global premium transitions for named routes.
              switch (settings.name) {
                case '/login':
                  return FadePageRoute(page: const LoginScreen());
                case '/register':
                  return SlidePageRoute(page: const RegisterScreen());
                case '/dashboard':
                  return FadePageRoute(page: const DashboardScreen());
                case '/book':
                  return SlidePageRoute(page: const BookAppointmentScreen());
                case '/appointments':
                  return SlidePageRoute(page: const MyAppointmentsScreen());
                case '/provider/dashboard':
                  return FadePageRoute(page: const ProviderDashboardScreen());
                case '/provider/services':
                  return SlidePageRoute(page: const ManageServicesScreen());
                case '/provider/location':
                  return SlidePageRoute(page: const ProviderLocationScreen());
                case '/settings':
                  return SlidePageRoute(page: const SettingsScreen());
                case '/edit-profile':
                  return SlidePageRoute(page: const EditProfileScreen());
                case '/forgot-password':
                  return SlidePageRoute(page: const ForgotPasswordScreen());
                case '/search':
                  return SlidePageRoute(page: const SearchScreen());
                case '/map':
                  return SlidePageRoute(page: const MapScreen());
                case '/favorites':
                  return SlidePageRoute(page: const FavoritesScreen());
                case '/help-support':
                  return SlidePageRoute(page: const HelpSupportScreen());
                case '/chatbot':
                  return SlidePageRoute(page: const ChatbotScreen());
                case '/payment-history':
                  return SlidePageRoute(page: const PaymentHistoryScreen());
                case '/cancellation-policy':
                  return SlidePageRoute(page: const CancellationPolicyScreen());
                case '/contact-support':
                  return SlidePageRoute(page: const ContactSupportScreen());
                default:
                  return null; // fallback to routes table
              }
            },
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/book': (context) => const BookAppointmentScreen(),
              '/appointments': (context) => const MyAppointmentsScreen(),
              '/provider/dashboard': (context) =>
                  const ProviderDashboardScreen(),
              '/provider/services': (context) => const ManageServicesScreen(),
              '/provider/location': (context) => const ProviderLocationScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/edit-profile': (context) => const EditProfileScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/search': (context) => const SearchScreen(),
              '/map': (context) => const MapScreen(),
              '/help-support': (context) => const HelpSupportScreen(),
              '/chatbot': (context) => const ChatbotScreen(),
              '/cancellation-policy': (context) => const CancellationPolicyScreen(),
              '/contact-support': (context) => const ContactSupportScreen(),
              '/payment-history': (context) => const PaymentHistoryScreen(),
              '/favorites': (context) => const FavoritesScreen(),
            },
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (mounted) {
      if (onboardingCompleted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colors = AppTheme.getColors(themeProvider.currentTheme);
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: colors.backgroundGradient,
            ),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: const AppLogo(
                    size: 120,
                    showText: true,
                    fontSize: 32,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.loading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          final user = authProvider.user;
          if (user?.isProvider == true) {
            return const ProviderDashboardScreen();
          } else {
            return const DashboardScreen();
          }
        }

        return const LoginScreen();
      },
    );
  }
}
