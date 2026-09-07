import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../product.dart';
import 'stock_pill.dart';

/// One row of the product catalogue: thumbnail, details, edit and delete.
class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.swatch,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Product product;

  /// Stands in for the product photo until images are wired up.
  final Color swatch;

  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Straight from the design; not on the base-4 scale.
  static const double _padding = 12;
  static const double _thumb = 56;
  static const double _action = 28;
  static const double _actionRadius = 8;
  static const double _actionIcon = 15;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        label:
            '${product.name}, SKU ${product.sku}, '
            '${Formatters.rupeesFromPaise(product.pricePaise)}',
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            boxShadow: AppShadows.softShadow,
          ),
          child: Material(
            color: AppColors.transparent,
            borderRadius: AppRadii.cardRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(_padding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        height: _thumb,
                        width: _thumb,
                        decoration: BoxDecoration(
                          color: swatch,
                          borderRadius: AppRadii.cardRadius,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleMedium,
                            ),
                            Text(
                              'SKU: ${product.sku}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption,
                            ),
                            const SizedBox(height: AppSpacing.x1),
                            Text(
                              Formatters.rupeesFromPaise(product.pricePaise),
                              style: AppTypography.price,
                            ),
                            const SizedBox(height: AppSpacing.x1),
                            StockPill(product: product),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit ${product.name}',
                          background: AppColors.tintMaroon,
                          foreground: AppColors.primary,
                          onTap: onEdit,
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        _ActionButton(
                          icon: Icons.delete_outline,
                          tooltip: 'Delete ${product.name}',
                          background: AppColors.errorBg,
                          foreground: AppColors.error,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
        borderRadius: BorderRadius.circular(ProductTile._actionRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: ProductTile._action,
            width: ProductTile._action,
            child: Icon(icon, size: ProductTile._actionIcon, color: foreground),
          ),
        ),
      ),
    );
  }
}
