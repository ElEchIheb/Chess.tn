import 'package:flutter/material.dart';

/// Brand palette: Tunisian red and white on a dark game surface, with a
/// warm gold accent. Every colour used by the UI comes from here or from a
/// board / piece theme.
abstract final class AppColors {
  static const Color red = Color(0xFFE31B23);
  static const Color redDark = Color(0xFF8E151B);
  static const Color redDeep = Color(0xFF5C0E13);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cream = Color(0xFFF6EBD8);
  static const Color gold = Color(0xFFF2C94C);
  static const Color goldDark = Color(0xFFC79A2B);

  static const Color background = Color(0xFF0F1115);
  static const Color surface = Color(0xFF181B22);
  static const Color surfaceHigh = Color(0xFF222630);
  static const Color outline = Color(0xFF2E3340);

  static const Color textPrimary = Color(0xFFF5F2EC);
  static const Color textSecondary = Color(0xFFA9AEBB);
  static const Color textMuted = Color(0xFF6E7482);

  static const Color success = Color(0xFF3FB27F);
  static const Color danger = Color(0xFFFF5A5F);
}
