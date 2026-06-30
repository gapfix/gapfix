import 'package:flutter/material.dart';

class AppTheme {
  // Light Mode Colors
  static const Color primaryLight = Color(0xFF008253);
  static const Color backgroundLight = Color(0xFFF2F7F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color textPrimaryLight = Color(0xFF1A1C1B);
  static const Color textSecondaryLight = Color(0xFF5A5F5D);
  static const Color accentBgLight = Color(0xFFEBF4FF);
  static const Color warningLight = Color(0xFFD97706);
  static const Color slateLightL = Color(0xFFF3F4F6);
  static const Color slateMediumLight = Color(0xFFE5E7EB);
  static const Color slateDarkLight = Color(0xFFD1D5DB);
  static const Color iconBgGreenLight = Color(0xFFE8F5E9);

  // Dark Mode Colors
  static const Color primaryDark = Color(0xFF00B574);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color borderDark = Color(0xFF2A2C2B);
  static const Color textPrimaryDark = Color(0xFFE2E8F0);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color accentBgDark = Color(0xFF1E293B);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color slateLightD = Color(0xFF1A1A1A);
  static const Color slateMediumDark = Color(0xFF2E2E2E);
  static const Color slateDarkD = Color(0xFF3E3E3E);
  static const Color iconBgGreenDark = Color(0xFF388E3C);

  // Helper getters for backward compatibility (using Light by default for consts, but better to use context.theme)
  static const Color primary = primaryLight;
  static const Color textDark = textPrimaryLight;
  static const Color textLight = textPrimaryDark;
  static const Color textSecondary = textSecondaryLight;
  static const Color slateDark = slateDarkLight;

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    
    final Color bgColor = isDark ? backgroundDark : backgroundLight;
    final Color textColor = isDark ? textPrimaryDark : textPrimaryLight;
    final Color surfaceColor = isDark ? surfaceDark : surfaceLight;
    final Color primaryColor = isDark ? primaryDark : primaryLight;
    final Color borderColor = isDark ? borderDark : borderLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: surfaceColor,
        onSurface: textColor,
        brightness: brightness,
      ).copyWith(
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: bgColor,
      dividerColor: borderColor,
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDark ? slateMediumDark : slateMediumLight, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(double.infinity, 56),
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF323232) : const Color(0xFF1A1C1B),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
    );
  }
}
