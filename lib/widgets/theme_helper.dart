import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

/// Helper extension to get current theme colors from context
extension ThemeHelper on BuildContext {
  ThemeColors get themeColors {
    final themeProvider = Theme.of(this).brightness == Brightness.dark
        ? AppTheme.darkProfessional
        : AppTheme.lightProfessional;
    
    // This will be enhanced when we have access to ThemeProvider in widgets
    return themeProvider;
  }
}

/// Helper class to get theme colors based on AppThemeMode
class ThemeHelper {
  static ThemeColors getColors(AppThemeMode mode) {
    return AppTheme.getColors(mode);
  }

  static Color getPrimaryColor(AppThemeMode mode) {
    return getColors(mode).primaryColor;
  }

  static Color getBackgroundColor(AppThemeMode mode) {
    return getColors(mode).backgroundColor;
  }

  static LinearGradient getPrimaryGradient(AppThemeMode mode) {
    return getColors(mode).primaryGradient;
  }

  static LinearGradient getBackgroundGradient(AppThemeMode mode) {
    return getColors(mode).backgroundGradient;
  }
}
