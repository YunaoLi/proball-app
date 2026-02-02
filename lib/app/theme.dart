import 'package:flutter/material.dart';

/// App-wide theme configuration for Wicked Rolling Ball Pro.
/// Investor-ready design with a distinctive pet-tech aesthetic.
class AppTheme {
  AppTheme._();

  static const Color _primary = Color(0xFF6366F1); // Indigo
  static const Color _secondary = Color(0xFF10B981); // Emerald
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _surfaceDark = Color(0xFF0F172A);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        primary: _primary,
        secondary: _secondary,
        surface: _surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: _surface,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _surface,
        foregroundColor: Color(0xFF1E293B),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 64,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        primary: _primary,
        secondary: _secondary,
        surface: _surfaceDark,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: _surfaceDark,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _surfaceDark,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E293B),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 64,
      ),
    );
  }
}
