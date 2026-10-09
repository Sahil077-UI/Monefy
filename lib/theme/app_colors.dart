import 'package:flutter/material.dart';

class AppColors {
  // --------------------------------
  // BRAND — Arctic Blue
  // --------------------------------
  static const Color primary = Color(0xFF4FC3F7);
  static const Color primaryDark = Color(0xFF0288D1);
  static const Color primaryLight = Color(0xFF80D8FF);

  // --------------------------------
  // BACKGROUNDS
  // --------------------------------
  static const Color background = Color(0xFF0A1014);
  static const Color surface = Color(0xFF141D24);
  static const Color surfaceElevated = Color(0xFF1A2730);
  static const Color divider = Color(0xFF243440);

  // --------------------------------
  // TEXT
  // --------------------------------
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF9BA9B4);
  static const Color textMuted = Color(0xFF6B7A85);

  // --------------------------------
  // SEMANTIC — fixed across the app
  // --------------------------------
  static const Color income = Color(0xFF22C55E);
  static const Color incomeDark = Color(0xFF15803D);
  static const Color expense = Color(0xFFEF4444);
  static const Color expenseDark = Color(0xFFB91C1C);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0x33F59E0B);

  // --------------------------------
  // GRADIENTS
  // --------------------------------
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6), Color(0xFF0288D1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient incomeGradient = const LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF15803D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient expenseGradient = const LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --------------------------------
  // CHART COLORS
  // --------------------------------
  static const List<Color> chartPalette = [
    Color(0xFF4FC3F7),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFFA855F7),
    Color(0xFF06B6D4),
    Color(0xFF84CC16),
    Color(0xFFF97316),
  ];
}