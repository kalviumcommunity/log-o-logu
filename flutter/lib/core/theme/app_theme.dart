import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlack = Color(0xFF000000);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color greyText = Color(0xFF757575);
  static const Color errorRed = Color(0xFFB00020);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlack,
      scaffoldBackgroundColor: primaryWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryBlack,
        onPrimary: primaryWhite,
        secondary: primaryBlack,
        onSecondary: primaryWhite,
        surface: primaryWhite,
        onSurface: primaryBlack,
        error: errorRed,
        onError: primaryWhite,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlack,
          foregroundColor: primaryWhite,
          minimumSize: const Size(double.infinity, 56),
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
          borderSide: const BorderSide(color: primaryBlack),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlack.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlack, width: 2),
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
