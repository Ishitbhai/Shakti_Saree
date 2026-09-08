import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The placeholder tints a product listing can carry until real photos exist.
///
/// The one place the palette is written down: the tile paints from it and the
/// form offers it, so a colour chosen in the form is the colour that appears
/// in the list.
class ProductSwatches {
  const ProductSwatches._();

  /// Every entry is an existing theme token — no literals here either.
  static const List<Color> palette = [
    AppColors.primary,
    AppColors.warning,
    AppColors.success,
    AppColors.info,
    AppColors.primaryLight,
  ];

  static int get count => palette.length;

  /// The colour for a stored index.
  ///
  /// Wraps rather than throwing, so a product carrying an index from a longer
  /// palette than this build knows about still renders something.
  static Color at(int index) => palette[index % palette.length];
}
