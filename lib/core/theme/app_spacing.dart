import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Base-4 spacing scale, corner radii and the two elevation treatments.
class AppSpacing {
  const AppSpacing._();

  // --------------------------------------------------------------- base-4
  static const double x0 = 0;
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x7 = 28;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;

  // ------------------------------------------------------------- semantic
  /// Horizontal gutter on every screen.
  static const double pagePadding = x6;

  /// Inner padding of a card.
  static const double cardPadding = x4;

  /// Default gap between sibling elements.
  static const double gap = x3;
}

/// Corner radii. Only these three exist — anything else is a mistake.
class AppRadii {
  const AppRadii._();

  /// Cards, tiles, inputs.
  static const double card = 16;

  /// Fully rounded: status pills, avatars, toggles.
  static const double pill = 999;

  /// Bottom sheets, dialogs, the curved admin header.
  static const double sheet = 28;

  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
  static const BorderRadius sheetRadius = BorderRadius.all(
    Radius.circular(sheet),
  );
}

/// The two shadow treatments in the design.
///
/// DERIVED: with section 3 unavailable, [softShadow] is transcribed from the
/// `feDropShadow` filter in `13_admin_dashboard.svg` (dy 6, blur 24, colour
/// #5C1129 at 10%). [brutalShadow] is measured off the dashboard screenshot's
/// gold "SHAKTI SAREE" block — a hard offset with no blur.
class AppShadows {
  const AppShadows._();

  /// Cards and raised surfaces.
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: AppColors.shadowSoft,
      offset: Offset(0, 6),
      blurRadius: 24,
    ),
  ];

  /// Neo-brutalist accent blocks: solid offset, zero blur.
  static const List<BoxShadow> brutalShadow = [
    BoxShadow(color: AppColors.shadowHard, offset: Offset(4, 4), blurRadius: 0),
  ];
}
