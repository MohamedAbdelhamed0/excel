import 'package:flutter/material.dart';

/// Available theme color palettes for application-wide customization.
enum AppColorPalette {
  blue('Classic Blue', Color(0xFF0F62FE)),
  green('Emerald Green', Color(0xFF10B981)),
  purple('Royal Purple', Color(0xFF8B5CF6)),
  orange('Sunset Orange', Color(0xFFF97316)),
  rose('Crimson Rose', Color(0xFFE11D48)),
  teal('Teal Cyan', Color(0xFF06B6D4));

  final String label;
  final Color primaryColor;
  const AppColorPalette(this.label, this.primaryColor);
}

/// App-wide theme configuration supporting Light/Dark modes and dynamic Color Palettes.
class AppTheme {
  AppTheme._();

  static const Color darkBackground = Color(0xFF12161F);
  static const Color darkSurface = Color(0xFF1E2430);

  /// Light Theme Configuration generated from [AppColorPalette]
  static ThemeData getLightTheme(AppColorPalette palette) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1F2937),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
    );
  }

  /// Dark Theme Configuration generated from [AppColorPalette]
  static ThemeData getDarkTheme(AppColorPalette palette) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primaryColor,
        brightness: Brightness.dark,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: darkSurface,
      ),
    );
  }
}
