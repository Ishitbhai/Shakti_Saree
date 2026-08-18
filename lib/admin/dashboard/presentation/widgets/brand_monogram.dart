import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Gold circle carrying the two-letter mark, sitting between the stat grid
/// and the recent orders list.
///
/// Decorative — hidden from screen readers.
class BrandMonogram extends StatelessWidget {
  const BrandMonogram({super.key, this.initials = 'SS'});

  final String initials;

  /// Straight from the design; not on the base-4 scale.
  static const double _diameter = 110;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Center(
        child: Container(
          height: _diameter,
          width: _diameter,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: Text(initials, style: AppTypography.monogram),
        ),
      ),
    );
  }
}
