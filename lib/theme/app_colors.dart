import 'package:flutter/material.dart';

/// AppColors encapsulates the custom color system for the Orion Store app.
///
/// It utilizes a refined, premium light minimalist palette:
/// Warm Off-White Background, Charcoal Primary, Black Labels, and Deep Black buttons.
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // User-specified Color Palette
  static const Color primary = Color(0xFF333333);
  static const Color labelPrimary = Color(0xFF000000);
  static const Color gray = Color(0xFF8E8E93);
  static const Color miscellaneous = Color(0xFF595959);
  static const Color buttonPrimary = Color(0xFF0A0A0A);
  static const Color backgroundColor = Color(0xFFFAF8F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color blue = Color(0xFF155DFC);
  static const Color navigationActive = Color(0xFFFF6900);
  static Color textTetiary = const Color(0xFF3C3C43).withValues(alpha: 0.3);

  // Semantic Status Colors (Highly curated to stay premium)
  static const Color success = Color(0xFF2E6F40); // Soft deep forest green
  static const Color warning = Color(0xFFC27D38); // Soft warm amber
  static const Color error = Color(0xFFB54A44); // Muted terracotta rust
}
