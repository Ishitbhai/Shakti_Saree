import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/dashboard_order.dart';
import 'order_tile.dart';

/// 'Recent Orders' heading with a 'View all' action, followed by the tiles.
class RecentOrdersSection extends StatelessWidget {
  const RecentOrdersSection({
    super.key,
    required this.orders,
    this.onViewAll,
    this.onOrderTap,
  });

  final List<DashboardOrder> orders;
  final VoidCallback? onViewAll;
  final ValueChanged<DashboardOrder>? onOrderTap;

  static const double _screenPadding = AppSpacing.x5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Recent Orders', style: AppTypography.sectionTitle),
              ),
              InkWell(
                onTap: onViewAll,
                borderRadius: AppRadii.pillRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x2,
                    vertical: AppSpacing.x1,
                  ),
                  child: Text('View all', style: AppTypography.labelMedium),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          for (final order in orders) ...[
            OrderTile(
              order: order,
              onTap: onOrderTap == null ? null : () => onOrderTap!(order),
            ),
            if (order != orders.last) const SizedBox(height: AppSpacing.x3),
          ],
        ],
      ),
    );
  }
}
