import 'package:flutter/material.dart';

class AppTheme {
  // Seed color
  static const Color seedColor = Color(0xFF1976D2);

  // Custom semantic colors (if needed beyond standard scheme)
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);

  static ThemeData lightTheme = _buildTheme(Brightness.light);
  static ThemeData darkTheme = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      
      // Components
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1, // M3 default is lower
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
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: colorScheme.primary.withValues(alpha: 0.3),
        selectionHandleColor: colorScheme.primary,
        cursorColor: colorScheme.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),
    );
  }

  // Option colors - using ColorScheme roles
  static Color getOptionColor(
    BuildContext context, {
    required bool isSelected,
    required bool showResult,
    required bool isCorrect,
    required bool isThisCorrectAnswer,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!showResult) {
      if (isSelected) {
        return colorScheme.primaryContainer.withValues(alpha: 0.5);
      }
      return Colors.transparent;
    }

    if (isThisCorrectAnswer) {
      // Success is not standard, use green or a custom extension in real world.
      // For now, mapping to a "success-like" color if available, or just keeping the green constant but adapting opacity.
      // Better: Use a tertiary or just the hardcoded success/green for specific semantics that Material doesn't cover strictly.
      return success.withValues(alpha: 0.25);
    }

    if (isSelected && !isCorrect) {
      return colorScheme.errorContainer;
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
    final colorScheme = Theme.of(context).colorScheme;

    if (!showResult) {
      if (isSelected) {
        return colorScheme.primary;
      }
      return colorScheme.outline;
    }

    if (isThisCorrectAnswer) {
      return success;
    }

    if (isSelected && !isCorrect) {
      return colorScheme.error;
    }

    return colorScheme.outlineVariant;
  }
  
  // Helpers for legacy access if needed, but prefer Theme.of(context)
  static Color get primaryLight => seedColor;
  static Color get primaryDark => const Color(0xFF90CAF9); // Approximation
  static Color get successLight => success;
  static Color get warningLight => warning;
  static Color get errorLight => Colors.red;
}
