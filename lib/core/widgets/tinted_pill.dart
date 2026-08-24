import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Small rounded chip with a tinted fill and matching text.
///
/// Shared by the order-status and stock-level pills so the two cannot drift
/// apart; callers supply the palette because the meaning of a colour belongs
/// to the feature, not to this widget.
class TintedPill extends StatelessWidget {
  const TintedPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.pill.copyWith(color: foreground),
      ),
    );
  }
}
