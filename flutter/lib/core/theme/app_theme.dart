import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlack = Color(0xFF0F172A);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color greyText = Color(0xFF64748B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        onPrimary: primaryWhite,
        secondary: primaryBlue,
        onSecondary: primaryWhite,
        surface: primaryWhite,
        onSurface: primaryBlack,
        error: errorRed,
        onError: primaryWhite,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: primaryWhite,
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed),
        ),
        labelStyle: const TextStyle(color: primaryBlack),
        hintStyle: const TextStyle(color: greyText),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: primaryBlack, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: primaryBlack, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: primaryBlack, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: primaryBlack),
        bodyMedium: TextStyle(color: primaryBlack),
      ),
    );
  }
}
