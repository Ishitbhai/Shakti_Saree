import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';

/// A single KPI tile: icon chip, formatted number, caption.
///
/// Takes the raw [value] and formats it here — callers must never pass a
/// pre-formatted string.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final VoidCallback? onTap;

  /// Floor, not a fixed height — the card still grows with its content.
  /// [BrandPlate] matches this so the two line up in a row.
  static const double minHeight = 96;

  /// Off the base-4 scale, straight from the design.
  static const double _padding = 14;
  static const double _iconTile = 34;
  static const double _iconTileRadius = 10;
  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final formatted = Formatters.count(value);

    return MergeSemantics(
      child: Semantics(
        label: '$label, $formatted',
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            boxShadow: AppShadows.softShadow,
          ),
          child: Material(
            // Transparent so the DecoratedBox fill shows through; this layer
            // exists only to clip the ripple to the corner radius.
            color: AppColors.transparent,
            borderRadius: AppRadii.cardRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: minHeight),
                child: Padding(
                  padding: const EdgeInsets.all(_padding),
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: _iconTile,
                          width: _iconTile,
                          decoration: BoxDecoration(
                            color: AppColors.tintMaroon,
                            borderRadius: BorderRadius.circular(
                              _iconTileRadius,
                            ),
                          ),
                          child: Icon(
                            icon,
                            size: _iconSize,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          formatted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.statValue,
                        ),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
