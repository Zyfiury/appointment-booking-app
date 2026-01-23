import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'animated_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? lottieAsset; // e.g. 'assets/lottie/empty_state.json'
  final IconData? fallbackIcon;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.lottieAsset,
    this.fallbackIcon,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    final media = MediaQuery.of(context);
    final maxAnim = media.size.height * 0.22;

    Widget visual;
    if (lottieAsset != null) {
      visual = SizedBox(
        height: maxAnim.clamp(140, 220),
        child: Lottie.asset(
          lottieAsset!,
          repeat: true,
          fit: BoxFit.contain,
        ),
      );
    } else {
      visual = Container(
        height: 160,
        width: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: colors.primaryGradient,
        ),
        child: Icon(
          fallbackIcon ?? Icons.inbox_outlined,
          color: Colors.white,
          size: 64,
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            visual,
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 18),
              AnimatedButton(
                text: actionText!,
                icon: Icons.refresh,
                onPressed: onAction,
                backgroundColor: colors.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

