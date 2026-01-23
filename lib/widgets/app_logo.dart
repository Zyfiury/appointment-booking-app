import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double? fontSize;

  const AppLogo({
    super.key,
    this.size = 60,
    this.showText = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: colors.primaryGradient,
            borderRadius: BorderRadius.circular(size * 0.3),
            boxShadow: [
              BoxShadow(
                color: colors.primaryColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.calendar_today_rounded,
            color: Colors.white,
            size: 35,
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            'Bookly',
            style: TextStyle(
              fontSize: fontSize ?? 24,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class AppLogoSmall extends StatelessWidget {
  final double size;

  const AppLogoSmall({
    super.key,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: colors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(
        Icons.calendar_today_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
