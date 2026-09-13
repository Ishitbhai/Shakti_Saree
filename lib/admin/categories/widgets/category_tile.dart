import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/tinted_pill.dart';
import '../../shared/widgets/swatches.dart';
import '../category.dart';

/// One row of the category list: tint, name, how much sits in it, whether it
/// is on offer, and the actions.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.listing,
    this.onEdit,
    this.onDelete,
    this.onToggleHidden,
  });

  final CategoryListing listing;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleHidden;

  /// Straight from the design; not on the base-4 scale.
  static const double _padding = 12;
  static const double _swatch = 56;
  static const double _action = 28;
  static const double _actionRadius = 8;
  static const double _actionIcon = 15;

  @override
  Widget build(BuildContext context) {
    final count = listing.productCount == 1
        ? '1 product'
        : '${Formatters.count(listing.productCount)} products';

    // No MergeSemantics around the whole row: the edit and delete buttons and
    // the overflow are real controls, and merging them into one node would
    // leave a screen reader with a sentence and nothing to press.
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        boxShadow: AppShadows.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                height: _swatch,
                width: _swatch,
                decoration: BoxDecoration(
                  color: Swatches.at(listing.swatchIndex),
                  borderRadius: AppRadii.cardRadius,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      listing.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium,
                    ),
                    Text(count, style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.x1),
                    _VisibilityPill(isHidden: listing.isHidden),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Overflow(
                  isHidden: listing.isHidden,
                  onToggleHidden: onToggleHidden,
                ),
                const SizedBox(height: AppSpacing.x1),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit ${listing.name}',
                      background: AppColors.tintMaroon,
                      foreground: AppColors.primary,
                      onTap: onEdit,
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    _ActionButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete ${listing.name}',
                      background: AppColors.errorBg,
                      foreground: AppColors.error,
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Active or Hidden, in the same shape as the other status chips.
class _VisibilityPill extends StatelessWidget {
  const _VisibilityPill({required this.isHidden});

  final bool isHidden;

  @override
  Widget build(BuildContext context) {
    return TintedPill(
      label: isHidden ? 'Hidden' : 'Active',
      background: isHidden ? AppColors.field : AppColors.successBg,
      foreground: isHidden ? AppColors.textGrey : AppColors.success,
    );
  }
}

/// The row's overflow, which is where showing and hiding lives.
///
/// Hiding is reversible and not destructive, so it does not want a button of
/// its own next to delete — but it does need somewhere to be.
class _Overflow extends StatelessWidget {
  const _Overflow({required this.isHidden, this.onToggleHidden});

  final bool isHidden;
  final VoidCallback? onToggleHidden;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      enabled: onToggleHidden != null,
      tooltip: isHidden ? 'Show or hide' : 'Show or hide',
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textMuted),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          onTap: onToggleHidden,
          child: Text(
            isHidden ? 'Show in store' : 'Hide from store',
            style: AppTypography.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.foreground,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(CategoryTile._actionRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: CategoryTile._action,
            width: CategoryTile._action,
            child: Icon(
              icon,
              size: CategoryTile._actionIcon,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
