import 'package:flutter/material.dart';

/// The single source of colour for the app.
///
/// No other file may contain a colour literal — everything routes through
/// these constants.
///
/// DERIVED, NOT AUTHORITATIVE: `shakti_saree_admin_dashboard_master_prompt.md`
/// section 3 was not available. These hexes are taken from the design kit's
/// `README_design_spec.md` token table and verified against the literal fill
/// values in `13_admin_dashboard.svg`, which matches the dashboard screenshot.
/// Replace any value that section 3 contradicts.
class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------- brand
  /// Buttons, app bar, active states.
  static const Color primary = Color(0xFF7B1E3B);

  /// Admin header, overlays, shadow tint.
  static const Color primaryDark = Color(0xFF5C1129);

  /// Gradient partner for [primary].
  static const Color primaryLight = Color(0xFF9B3352);

  /// Logo, badges, sale accents.
  static const Color accent = Color(0xFFC9A227);

  /// Motifs and accent borders.
  static const Color accentLight = Color(0xFFE8C86A);

  // ------------------------------------------------------------- surfaces
  /// Screen background.
  static const Color background = Color(0xFFFFF7F1);

  /// Cards, sheets, nav bar.
  static const Color surface = Color(0xFFFFFFFF);

  /// Input field background.
  static const Color field = Color(0xFFFAF5F7);

  /// Dividers and outlines.
  static const Color border = Color(0xFFEFE0E4);

  /// Maroon-tinted chip background (KPI icon tiles, "New" pill).
  static const Color tintMaroon = Color(0xFFF3DDE3);

  // ----------------------------------------------------------------- text
  /// Headings and body.
  static const Color textDark = Color(0xFF2B1B1F);

  /// Secondary text and labels.
  static const Color textGrey = Color(0xFF8E7F84);

  /// Inactive nav icons and labels.
  static const Color textMuted = Color(0xFFB4A6AB);

  /// Text on [primary] / [primaryDark].
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Muted text on [primaryDark], e.g. the header subtitle.
  static const Color textOnPrimarySoft = Color(0xFFF3DDE3);

  /// Text on [accent], e.g. the avatar initial.
  static const Color textOnAccent = Color(0xFF5C1129);

  // --------------------------------------------------------------- status
  /// Delivered, in stock.
  static const Color success = Color(0xFF2E7D5B);
  static const Color successBg = Color(0xFFE3F1EA);

  /// Packed, low stock.
  static const Color warning = Color(0xFFE0A82E);
  static const Color warningBg = Color(0xFFFBEFD6);

  /// Cancelled, out of stock.
  static const Color error = Color(0xFFC1435C);
  static const Color errorBg = Color(0xFFFBE7EB);

  /// Products / neutral informational chips.
  static const Color info = Color(0xFF3A6EA5);
  static const Color infoBg = Color(0xFFE4EDF6);

  // ---------------------------------------------------------------- misc
  static const Color transparent = Color(0x00000000);

  /// Card shadow: [primaryDark] at 10% opacity, pre-baked so it stays const.
  static const Color shadowSoft = Color(0x1A5C1129);

  /// Hard-offset shadow colour for the brutalist accent blocks.
  static const Color shadowHard = Color(0xFF2B1B1F);

  /// Every token above, for the dev token preview. Keep in sync when adding.
  static const Map<String, Color> all = {
    'primary': primary,
    'primaryDark': primaryDark,
    'primaryLight': primaryLight,
    'accent': accent,
    'accentLight': accentLight,
    'background': background,
    'surface': surface,
    'field': field,
    'border': border,
    'tintMaroon': tintMaroon,
    'textDark': textDark,
    'textGrey': textGrey,
    'textMuted': textMuted,
    'textOnPrimary': textOnPrimary,
    'textOnPrimarySoft': textOnPrimarySoft,
    'textOnAccent': textOnAccent,
    'success': success,
    'successBg': successBg,
    'warning': warning,
    'warningBg': warningBg,
    'error': error,
    'errorBg': errorBg,
    'info': info,
    'infoBg': infoBg,
    'shadowSoft': shadowSoft,
    'shadowHard': shadowHard,
  };
}
