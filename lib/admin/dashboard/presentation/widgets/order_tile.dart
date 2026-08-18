import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/dashboard_order.dart';
import 'status_pill.dart';

/// One row in the recent-orders list.
class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, this.onTap});

  final DashboardOrder order;
  final VoidCallback? onTap;

  /// Straight from the design; not on the base-4 scale.
  static const double _padding = 14;
  static const double _iconCircle = 34;
  static const double _iconSize = 17;

  @override
  Widget build(BuildContext context) {
    final amount = Formatters.rupeesFromPaise(order.amountPaise);
    final items = '${Formatters.count(order.itemCount)} items';

    return MergeSemantics(
      child: Semantics(
        label:
            'Order ${order.id}, ${order.customer}, $items, '
            '$amount, ${order.status.label}',
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
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      Container(
                        height: _iconCircle,
                        width: _iconCircle,
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                          size: _iconSize,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              order.id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleMedium,
                            ),
                            Text(
                              '${order.customer}  •  $items',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x2),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(amount, style: AppTypography.price),
                          const SizedBox(height: AppSpacing.x1),
                          StatusPill(status: order.status),
                        ],
                      ),
                    ],
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
