import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class RetryButton extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;
  final bool isLoading;

  const RetryButton({
    super.key,
    required this.onRetry,
    this.message,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
        ElevatedButton.icon(
          onPressed: isLoading ? null : () {
            HapticFeedback.mediumImpact();
            onRetry();
          },
          icon: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh, size: 18),
          label: Text(isLoading ? 'Retrying...' : 'Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
