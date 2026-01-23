import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

/// Extension to easily access current theme colors
extension ThemeColorsExtension on BuildContext {
  ThemeColors get themeColors {
    final themeProvider = Provider.of<ThemeProvider>(this, listen: false);
    return AppTheme.getColors(themeProvider.currentTheme);
  }
}

/// Helper widget that provides theme colors to child widgets
class ThemeColorsBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ThemeColors colors) builder;

  const ThemeColorsBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colors = AppTheme.getColors(themeProvider.currentTheme);
        return builder(context, colors);
      },
    );
  }
}
