import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/fade_in_widget.dart';
import '../auth/login_screen.dart';
import '../../providers/theme_provider.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingPage> _getPages(ThemeColors colors) {
    return [
      OnboardingPage(
        icon: Icons.calendar_today_rounded,
        title: 'Book Appointments Easily',
        description: 'Find and book appointments with service providers in just a few taps. Simple, fast, and convenient.',
        color: colors.primaryColor,
      ),
      OnboardingPage(
        icon: Icons.notifications_active_rounded,
        title: 'Never Miss an Appointment',
        description: 'Get smart reminders before your appointments. Stay organized and never be late again.',
        color: colors.accentColor,
      ),
      OnboardingPage(
        icon: Icons.star_rounded,
        title: 'Trusted Providers',
        description: 'Browse reviews and ratings to find the best service providers. Quality guaranteed.',
        color: colors.accentColor,
      ),
      OnboardingPage(
        icon: Icons.payment_rounded,
        title: 'Secure Payments',
        description: 'Pay securely through the app. Multiple payment options available for your convenience.',
        color: colors.primaryColor,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _nextPage() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    if (_currentPage < _getPages(colors).length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip Button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _getPages(colors).length,
                  itemBuilder: (context, index) {
                    return _OnboardingPageWidget(
                      page: _getPages(colors)[index],
                      index: index,
                    );
                  },
                ),
              ),
              // Page Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _getPages(colors).length,
                  (index) => _PageIndicator(
                    isActive: index == _currentPage,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Next/Get Started Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedButton(
                  text: _currentPage == _getPages(colors).length - 1
                      ? 'Get Started'
                      : 'Next',
                  icon: _currentPage == _getPages(colors).length - 1
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_forward_ios_rounded,
                  onPressed: _nextPage,
                  backgroundColor: colors.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  final int index;

  const _OnboardingPageWidget({
    required this.page,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Icon with Animation
          FadeInWidget(
            duration: Duration(milliseconds: 600 + (index * 200)),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: page.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                page.icon,
                size: 100,
                color: page.color,
              ),
            ),
          ),
          const SizedBox(height: 60),
          // Title
          FadeInWidget(
            duration: Duration(milliseconds: 800 + (index * 200)),
            child: Text(
              page.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          // Description
          FadeInWidget(
            duration: Duration(milliseconds: 1000 + (index * 200)),
            child: Text(
              page.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                    fontSize: 16,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final bool isActive;

  const _PageIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? colors.primaryColor : colors.borderColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
