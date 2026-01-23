import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layered_card.dart';
import '../../widgets/fade_in_widget.dart';
import '../../config/app_config.dart';
import '../../providers/theme_provider.dart';
import 'chatbot_screen.dart';
import 'cancellation_policy_screen.dart';
import 'contact_support_screen.dart';


class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail() async {
    final email = AppConfig.supportEmail;
    final uri = Uri.parse('mailto:$email?subject=Bookly Support Request');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        title: Text('Help & Support'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.backgroundGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            FadeInWidget(
              child: FloatingCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: colors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'How can we help?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'re here to assist you with any questions or issues',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // AI Chatbot Section
            FadeInWidget(
              duration: const Duration(milliseconds: 150),
              child: FloatingCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(20),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatbotScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: colors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.smart_toy,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chat with AI Assistant',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Get instant answers to your questions',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // FAQ Section
            FadeInWidget(
              duration: const Duration(milliseconds: 200),
              child: FloatingCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFAQItem(
                      question: 'How do I book an appointment?',
                      answer:
                          'Tap "Book Appointment" on the dashboard, search for a provider, select a service, choose a date and time, then confirm your booking.',
                      colors: colors,
                    ),
                    Divider(height: 32),
                    _buildFAQItem(
                      question: 'How do I cancel an appointment?',
                      answer:
                          'Go to "My Appointments", find the appointment you want to cancel, tap on it, and select "Cancel Appointment".',
                      colors: colors,
                    ),
                    Divider(height: 32),
                    _buildFAQItem(
                      question: 'How do I pay for an appointment?',
                      answer:
                          'After booking, you\'ll be redirected to the payment screen. Enter your card details and complete the payment securely.',
                      colors: colors,
                    ),
                    Divider(height: 32),
                    _buildFAQItem(
                      question: 'Can I reschedule an appointment?',
                      answer:
                          'Yes! Go to "My Appointments", select the appointment, and choose "Reschedule" to pick a new date and time.',
                      colors: colors,
                    ),
                    Divider(height: 32),
                    _buildFAQItem(
                      question: 'How do I leave a review?',
                      answer:
                          'After completing an appointment, go to "My Appointments", find the completed appointment, and tap "Review" to rate and comment.',
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Contact Section
            FadeInWidget(
              duration: const Duration(milliseconds: 300),
              child: FloatingCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Us',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildContactTile(
                      icon: Icons.email_outlined,
                      title: 'Email Support',
                      subtitle: AppConfig.supportEmail,
                      onTap: _launchEmail,
                      colors: colors,
                    ),
                    Divider(height: 32),
                    _buildContactTile(
                      icon: Icons.language_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'View our privacy policy',
                      onTap: () => _launchUrl(AppConfig.privacyPolicyUrl),
                      colors: colors,
                    ),
                    Divider(height: 32),
                    _buildContactTile(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      subtitle: 'Read our terms and conditions',
                      onTap: () => _launchUrl(AppConfig.termsOfServiceUrl),
                      colors: colors,
                    ),
                    Divider(height: 32),
                    _buildContactTile(
                      icon: Icons.cancel_outlined,
                      title: 'Cancellation & Refund Policy',
                      subtitle: 'View cancellation and refund terms',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CancellationPolicyScreen(),
                          ),
                        );
                      },
                      colors: colors,
                    ),
                    Divider(height: 32),
                    _buildContactTile(
                      icon: Icons.support_agent,
                      title: 'Contact Support',
                      subtitle: 'Submit a support request',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactSupportScreen(),
                          ),
                        );
                      },
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // App Info
            FadeInWidget(
              duration: const Duration(milliseconds: 400),
              child: FloatingCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'App Version',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppConfig.appName} v${AppConfig.appVersion}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
    required ThemeColors colors,
  }) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
      title: Text(
        question,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      children: [
        Text(
          answer,
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colors.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
