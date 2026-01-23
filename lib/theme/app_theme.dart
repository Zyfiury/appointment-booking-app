import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

class ThemeColors {
  final Color primaryColor;
  final Color primaryDark;
  final Color primaryLight;
  final Color secondaryColor;
  final Color accentColor;
  final Color errorColor;
  final Color warningColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color cardElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color borderColor;
  final Color dividerColor;

  const ThemeColors({
    required this.primaryColor,
    required this.primaryDark,
    required this.primaryLight,
    required this.secondaryColor,
    required this.accentColor,
    required this.errorColor,
    required this.warningColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.cardElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
    required this.dividerColor,
  });

  LinearGradient get primaryGradient => LinearGradient(
    colors: [primaryColor, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get accentGradient => LinearGradient(
    colors: [secondaryColor, secondaryColor.withOpacity(0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get backgroundGradient => LinearGradient(
    colors: [backgroundColor, surfaceColor],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  // Theme 1: Dark Professional (Green) - Original
  static const ThemeColors darkProfessional = ThemeColors(
    primaryColor: Color(0xFF06C167), // Uber Eats Green
    primaryDark: Color(0xFF05A855),
    primaryLight: Color(0xFF2DD882),
    secondaryColor: Color(0xFFFF6B35), // Orange accent
    accentColor: Color(0xFF06C167),
    errorColor: Color(0xFFE63946),
    warningColor: Color(0xFFFFB800),
    backgroundColor: Color(0xFF0F0F0F), // Almost black
    surfaceColor: Color(0xFF1A1A1A), // Dark gray
    cardColor: Color(0xFF242424), // Card background
    cardElevated: Color(0xFF2A2A2A), // Elevated card
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B0B0),
    textTertiary: Color(0xFF808080),
    borderColor: Color(0xFF333333),
    dividerColor: Color(0xFF2A2A2A),
  );

  // Theme 2: Dark Elegant (Purple/Blue)
  static const ThemeColors darkElegant = ThemeColors(
    primaryColor: Color(0xFF7B68EE), // Medium Slate Blue
    primaryDark: Color(0xFF5F4FCF),
    primaryLight: Color(0xFF9378FF),
    secondaryColor: Color(0xFF4A90E2), // Blue
    accentColor: Color(0xFF9D7FFF),
    errorColor: Color(0xFFE63946),
    warningColor: Color(0xFFFFB800),
    backgroundColor: Color(0xFF0A0A0F),
    surfaceColor: Color(0xFF151520),
    cardColor: Color(0xFF1E1E2E),
    cardElevated: Color(0xFF252538),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB8B8C8),
    textTertiary: Color(0xFF888898),
    borderColor: Color(0xFF2D2D3E),
    dividerColor: Color(0xFF252538),
  );

  // Theme 3: Light Professional (Blue/Gray)
  static const ThemeColors lightProfessional = ThemeColors(
    primaryColor: Color(0xFF2563EB), // Professional Blue
    primaryDark: Color(0xFF1E40AF),
    primaryLight: Color(0xFF3B82F6),
    secondaryColor: Color(0xFF64748B), // Slate Gray
    accentColor: Color(0xFF0EA5E9), // Sky Blue
    errorColor: Color(0xFFDC2626),
    warningColor: Color(0xFFF59E0B),
    backgroundColor: Color(0xFFF8FAFC), // Very light gray
    surfaceColor: Color(0xFFFFFFFF), // White
    cardColor: Color(0xFFFFFFFF),
    cardElevated: Color(0xFFF1F5F9), // Light gray
    textPrimary: Color(0xFF0F172A), // Almost black
    textSecondary: Color(0xFF475569), // Gray
    textTertiary: Color(0xFF94A3B8), // Light gray
    borderColor: Color(0xFFE2E8F0), // Light border
    dividerColor: Color(0xFFE2E8F0),
  );

  // Theme 4: Light Warm (Teal/Amber)
  static const ThemeColors lightWarm = ThemeColors(
    primaryColor: Color(0xFF14B8A6), // Teal
    primaryDark: Color(0xFF0D9488),
    primaryLight: Color(0xFF2DD4BF),
    secondaryColor: Color(0xFFF59E0B), // Amber
    accentColor: Color(0xFF06B6D4), // Cyan
    errorColor: Color(0xFFDC2626),
    warningColor: Color(0xFFF59E0B),
    backgroundColor: Color(0xFFFFFBF5), // Warm white
    surfaceColor: Color(0xFFFFFFFF),
    cardColor: Color(0xFFFFFFFF),
    cardElevated: Color(0xFFFFF8F0), // Warm light
    textPrimary: Color(0xFF1F2937), // Dark gray
    textSecondary: Color(0xFF6B7280), // Medium gray
    textTertiary: Color(0xFF9CA3AF), // Light gray
    borderColor: Color(0xFFE5E7EB), // Light border
    dividerColor: Color(0xFFE5E7EB),
  );

  static ThemeColors getColors(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.darkProfessional:
        return darkProfessional;
      case AppThemeMode.darkElegant:
        return darkElegant;
      case AppThemeMode.lightProfessional:
        return lightProfessional;
      case AppThemeMode.lightWarm:
        return lightWarm;
    }
  }

  static ThemeData getTheme(AppThemeMode mode) {
    final colors = getColors(mode);
    final isDark = mode == AppThemeMode.darkProfessional || mode == AppThemeMode.darkElegant;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: colors.primaryColor,
              secondary: colors.secondaryColor,
              error: colors.errorColor,
              surface: colors.surfaceColor,
              background: colors.backgroundColor,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: colors.textPrimary,
              onBackground: colors.textPrimary,
            )
          : ColorScheme.light(
              primary: colors.primaryColor,
              secondary: colors.secondaryColor,
              error: colors.errorColor,
              surface: colors.surfaceColor,
              background: colors.backgroundColor,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: colors.textPrimary,
              onBackground: colors.textPrimary,
            ),
      scaffoldBackgroundColor: colors.backgroundColor,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
        shadowColor: isDark
            ? Colors.black.withOpacity(0.5)
            : Colors.black.withOpacity(0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: colors.primaryColor,
          foregroundColor: Colors.white,
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: colors.borderColor, width: 1.5),
          foregroundColor: colors.textPrimary,
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textTertiary),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: colors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colors.textSecondary,
        ),
      ),
      dividerColor: colors.dividerColor,
    );
  }

  // Legacy static properties for backward compatibility
  static Color get primaryColor => darkProfessional.primaryColor;
  static Color get primaryDark => darkProfessional.primaryDark;
  static Color get primaryLight => darkProfessional.primaryLight;
  static Color get secondaryColor => darkProfessional.secondaryColor;
  static Color get accentColor => darkProfessional.accentColor;
  static Color get errorColor => darkProfessional.errorColor;
  static Color get warningColor => darkProfessional.warningColor;
  static Color get backgroundColor => darkProfessional.backgroundColor;
  static Color get surfaceColor => darkProfessional.surfaceColor;
  static Color get cardColor => darkProfessional.cardColor;
  static Color get cardElevated => darkProfessional.cardElevated;
  static Color get textPrimary => darkProfessional.textPrimary;
  static Color get textSecondary => darkProfessional.textSecondary;
  static Color get textTertiary => darkProfessional.textTertiary;
  static Color get borderColor => darkProfessional.borderColor;
  static Color get dividerColor => darkProfessional.dividerColor;
  static LinearGradient get primaryGradient => darkProfessional.primaryGradient;
  static LinearGradient get accentGradient => darkProfessional.accentGradient;
  static LinearGradient get darkGradient => darkProfessional.backgroundGradient;
  static ThemeData get darkTheme => getTheme(AppThemeMode.darkProfessional);
}
