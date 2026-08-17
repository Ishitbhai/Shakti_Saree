import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Named text styles. Playfair Display for display/headings, Inter for
/// everything else.
///
/// DERIVED, NOT AUTHORITATIVE: the section 3 type table was not available.
/// The families are as instructed; the sizes and weights are read off the
/// literal `font-size` / `font-weight` attributes in `13_admin_dashboard.svg`
/// and rounded onto a consistent scale. Rename or retune freely once the real
/// table exists — every screen references these by name, so a change here
/// propagates.
class AppTypography {
  const AppTypography._();

  // ------------------------------------------- display — Playfair Display
  /// Page-level hero text.
  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textDark,
  );

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textDark,
  );

  /// Header greeting, e.g. "Welcome back, Admin".
  static TextStyle get displaySmall => GoogleFonts.playfairDisplay(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textDark,
  );

  /// The big number on a KPI card, e.g. "1,248".
  static TextStyle get statValue => GoogleFonts.playfairDisplay(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: AppColors.textDark,
  );

  /// The gold brand plate on the dashboard. Heavier and wider-tracked than
  /// any display style, so it gets its own entry rather than a copyWith.
  static TextStyle get brandPlate => GoogleFonts.playfairDisplay(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: 1,
    color: AppColors.textOnAccent,
  );

  /// Section heading above a list, e.g. "Recent Orders".
  static TextStyle get sectionTitle => GoogleFonts.playfairDisplay(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textDark,
  );

  // ------------------------------------------------------- body — Inter
  /// Card headline, e.g. an order id.
  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textDark,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textDark,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textDark,
  );

  /// Card subtitle, e.g. "Priyanshu K. • 3 items".
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textGrey,
  );

  /// Button text. Buttons recolour this to [AppColors.textOnPrimary] — the
  /// base style stays dark so it is legible wherever else it is used.
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textDark,
  );

  /// Inline action, e.g. "View all".
  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AppColors.primary,
  );

  /// KPI caption, e.g. "Total Orders".
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.textGrey,
  );

  /// Letter-spaced eyebrow, e.g. "ADMIN PANEL".
  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.6,
    color: AppColors.accent,
  );

  /// Money. Tabular figures so columns of prices line up.
  static TextStyle get price => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.primary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Status pill text, e.g. "New", "Packed".
  static TextStyle get pill => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.primary,
  );

  /// Bottom navigation label.
  static TextStyle get navLabel => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AppColors.textMuted,
  );

  /// Every style above, for the dev token preview. Keep in sync when adding.
  static Map<String, TextStyle> get all => {
    'displayLarge': displayLarge,
    'displayMedium': displayMedium,
    'displaySmall': displaySmall,
    'brandPlate': brandPlate,
    'statValue': statValue,
    'sectionTitle': sectionTitle,
    'titleMedium': titleMedium,
    'bodyLarge': bodyLarge,
    'bodyMedium': bodyMedium,
    'bodySmall': bodySmall,
    'labelLarge': labelLarge,
    'labelMedium': labelMedium,
    'caption': caption,
    'overline': overline,
    'price': price,
    'pill': pill,
    'navLabel': navLabel,
  };
}
