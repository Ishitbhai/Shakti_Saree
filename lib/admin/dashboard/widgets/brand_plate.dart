import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'stat_card.dart';

/// Gold brand block that sits in the stat grid where a fourth KPI would go.
///
/// Purely decorative — it carries no data, so it is hidden from screen
/// readers.
class BrandPlate extends StatelessWidget {
  const BrandPlate({super.key, this.text = 'SHAKTI SAREE'});

  final String text;

  static const double _borderWidth = 2;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: StatCard.minHeight),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppSpacing.x2),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(color: AppColors.textDark, width: _borderWidth),
          boxShadow: AppShadows.brutalShadow,
        ),
        child: Text(
          // One word per line, so 'SHAKTI SAREE' stacks into two.
          text.trim().split(RegExp(r'\s+')).join('\n'),
          textAlign: TextAlign.center,
          style: AppTypography.brandPlate,
        ),
      ),
    );
  }
}
