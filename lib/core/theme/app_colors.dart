import 'package:flutter/material.dart';

/// Central colour palette for the whole app.
///
/// Nothing else should hard-code a colour — when the final design lands,
/// changing the values here restyles every screen.
class AppColors {
  const AppColors._();

  // Brand
  static const Color primary = Color(0xFF8E1B3A);
  static const Color primaryDark = Color(0xFF6B1229);
  static const Color accent = Color(0xFFC9A227);

  // Surfaces
  static const Color background = Color(0xFFF5F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE4E7EC);

  // Admin sidebar
  static const Color sidebar = Color(0xFF1C1A21);
  static const Color sidebarHover = Color(0xFF2A2731);
  static const Color sidebarText = Color(0xFFB6B2BF);

  // Text
  static const Color textPrimary = Color(0xFF15171A);
  static const Color textSecondary = Color(0xFF6B7280);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
}
