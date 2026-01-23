import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layered_card.dart';
import '../../widgets/fade_in_widget.dart';
import '../../providers/theme_provider.dart';
import '../../services/policy_service.dart';

class CancellationPolicyScreen extends StatefulWidget {
  const CancellationPolicyScreen({super.key});

  @override
  State<CancellationPolicyScreen> createState() => _CancellationPolicyScreenState();
}

class _CancellationPolicyScreenState extends State<CancellationPolicyScreen> {
  final PolicyService _policyService = PolicyService();
  Map<String, dynamic>? _policy;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    try {
      final policy = await _policyService.getCancellationPolicy();
      if (mounted) {
        setState(() {
          _policy = policy;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
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
        title: const Text('Cancellation & Refund Policy'),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: colors.backgroundGradient),
        child: _loading
            ? Center(child: CircularProgressIndicator(color: colors.primaryColor))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: colors.errorColor),
                        const SizedBox(height: 16),
                        Text('Failed to load policy', style: TextStyle(color: colors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPolicy,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _policy == null
                    ? const Center(child: Text('No policy available'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          FadeInWidget(
                            child: FloatingCard(
                              margin: EdgeInsets.zero,
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: colors.primaryGradient,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.cancel_outlined, color: Colors.white),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          'Cancellation & Refund Policy',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  if (_policy!['summary'] != null) ...[
                                    Text(
                                      _policy!['summary'] as String,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: colors.textPrimary,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                  if (_policy!['platformDefault'] != null) ...[
                                    Text(
                                      'Platform Default Policy',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildPolicyItem(
                                      colors,
                                      'Free Cancellation Window',
                                      '${_policy!['platformDefault']['freeCancelHours']} hours before appointment',
                                      Icons.access_time,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildPolicyItem(
                                      colors,
                                      'Late Cancellation Fee',
                                      '${_policy!['platformDefault']['lateCancelFee']}% of service price',
                                      Icons.warning_amber_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildPolicyItem(
                                      colors,
                                      'No-Show Fee',
                                      '${_policy!['platformDefault']['noShowFee']}% of service price',
                                      Icons.event_busy,
                                    ),
                                    const SizedBox(height: 24),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colors.accentColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline, color: colors.accentColor, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Providers may set stricter policies. Check individual provider/service policies when booking.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildPolicyItem(colors, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: colors.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
