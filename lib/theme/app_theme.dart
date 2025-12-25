import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors - Ultramarine theme
  static const Color primary = Color(0xFF0437F2);
  static const Color primaryLight = Color(0xFF3B5FF5);
  static const Color primaryDark = Color(0xFF0328B5);

  static const Color accent = Color(0xFF00D9FF);
  static const Color accentAlt = Color(0xFF00F5A0);

  // Animated background gradient colors
  static const List<Color> gradientColors = [
    Color(0xFF0D0D12),
    Color(0xFF0A1628),
  ];

  // Shape colors for animated background
  static const List<Color> shapeColors = [
    Color(0xFF0437F2),  // Ultramarine
    Color(0xFF3B5FF5),  // Light ultramarine
    Color(0xFF00D9FF),  // Cyan accent
    Color(0xFF0328B5),  // Dark ultramarine
  ];

  // Dark theme colors
  static const Color backgroundDark = Color(0xFF0D0D12);
  static const Color surfaceDark = Color(0xFF16161F);
  static const Color surfaceLight = Color(0xFF1E1E2A);
  static const Color cardDark = Color(0xFF1A1A25);

  // Text colors
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0xFF5C5C66);

  // Status colors
  static const Color success = Color(0xFF00F5A0);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFBE0B);

  // Border & divider
  static const Color border = Color(0xFF2A2A35);
  static const Color divider = Color(0xFF1F1F28);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        primaryContainer: primaryDark,
        secondary: accent,
        secondaryContainer: Color(0xFF1A3A40),
        surface: surfaceDark,
        error: error,
        onPrimary: textPrimary,
        onSecondary: backgroundDark,
        onSurface: textPrimary,
        onError: textPrimary,
        outline: border,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: textMuted,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceLight,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: textSecondary,
      ),
    );
  }
}
