import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  darkProfessional, // Current green theme
  darkElegant, // Purple/Blue elegant
  lightProfessional, // Blue/Gray clean
  lightWarm, // Teal/Amber warm
}

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _currentTheme = AppThemeMode.darkProfessional;
  
  AppThemeMode get currentTheme => _currentTheme;
  
  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('selected_theme') ?? 0;
    _currentTheme = AppThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_theme', theme.index);
    notifyListeners();
  }

  String getThemeName(AppThemeMode theme) {
    switch (theme) {
      case AppThemeMode.darkProfessional:
        return 'Dark Professional';
      case AppThemeMode.darkElegant:
        return 'Dark Elegant';
      case AppThemeMode.lightProfessional:
        return 'Light Professional';
      case AppThemeMode.lightWarm:
        return 'Light Warm';
    }
  }

  String getThemeDescription(AppThemeMode theme) {
    switch (theme) {
      case AppThemeMode.darkProfessional:
        return 'Green accent, modern & vibrant';
      case AppThemeMode.darkElegant:
        return 'Purple & blue, sophisticated';
      case AppThemeMode.lightProfessional:
        return 'Blue & gray, clean & crisp';
      case AppThemeMode.lightWarm:
        return 'Teal & amber, friendly & warm';
    }
  }
}
