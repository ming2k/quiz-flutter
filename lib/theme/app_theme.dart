import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF90CAF9);

  static const Color successLight = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF81C784);

  static const Color errorLight = Color(0xFFF44336);
  static const Color errorDark = Color(0xFFEF5350);

  static const Color warningLight = Color(0xFFFFC107);
  static const Color warningDark = Color(0xFFFFD54F);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryLight,
      secondary: const Color(0xFF03A9F4),
      surface: Colors.white,
      error: errorLight,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryLight,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryLight,
      unselectedItemColor: Colors.grey,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primaryDark,
      secondary: const Color(0xFF4FC3F7),
      surface: const Color(0xFF1E1E1E),
      error: errorDark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: const Color(0xFF2D2D2D),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: primaryDark,
      unselectedItemColor: Colors.grey,
    ),
  );

  // Option colors
  static Color getOptionColor(
    BuildContext context, {
    required bool isSelected,
    required bool showResult,
    required bool isCorrect,
    required bool isThisCorrectAnswer,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!showResult) {
      if (isSelected) {
        return isDark ? primaryDark.withValues(alpha: 0.3) : primaryLight.withValues(alpha: 0.2);
      }
      return Colors.transparent;
    }

    if (isThisCorrectAnswer) {
      return isDark ? successDark.withValues(alpha: 0.3) : successLight.withValues(alpha: 0.2);
    }

    if (isSelected && !isCorrect) {
      return isDark ? errorDark.withValues(alpha: 0.3) : errorLight.withValues(alpha: 0.2);
    }

    return Colors.transparent;
  }

  static Color getOptionBorderColor(
    BuildContext context, {
    required bool isSelected,
    required bool showResult,
    required bool isCorrect,
    required bool isThisCorrectAnswer,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!showResult) {
      if (isSelected) {
        return isDark ? primaryDark : primaryLight;
      }
      return isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    }

    if (isThisCorrectAnswer) {
      return isDark ? successDark : successLight;
    }

    if (isSelected && !isCorrect) {
      return isDark ? errorDark : errorLight;
    }

    return isDark ? Colors.grey.shade700 : Colors.grey.shade300;
  }
}
