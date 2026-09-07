import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../shared/widgets/status_pill.dart';
import '../order.dart';

/// One order in the admin list: header, customer details, and the two actions.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.onPrimaryAction,
    this.onViewDetails,
  });

  final AdminOrder order;

  /// Accept / Ship / Mark Delivered, depending on the status.
  final VoidCallback? onPrimaryAction;

  final VoidCallback? onViewDetails;

  /// Straight from the design; not on the base-4 scale.
  static const double _padding = 14;
  static const double _actionHeight = 42;
  static const double _detailIcon = 15;

  @override
  Widget build(BuildContext context) {
    final action = order.status.nextActionLabel;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        boxShadow: AppShadows.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        Formatters.relativeTime(order.placedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusPill(status: order.status),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      Formatters.rupeesFromPaise(order.amountPaise),
                      style: AppTypography.price,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            const Divider(),
            const SizedBox(height: AppSpacing.x3),
            Row(
              children: [
                Expanded(
                  child: _Detail(
                    icon: Icons.person_outline,
                    text: order.customer,
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                _Detail(
                  icon: Icons.inventory_2_outlined,
                  text: Formatters.items(order.itemCount),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            _Detail(icon: Icons.call_outlined, text: order.phone),
            const SizedBox(height: AppSpacing.x4),
            Row(
              children: [
                if (action != null) ...[
                  Expanded(
                    child: SizedBox(
                      height: _actionHeight,
                      child: FilledButton(
                        onPressed: onPrimaryAction,
                        child: Text(action),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                ],
                Expanded(
                  child: SizedBox(
                    height: _actionHeight,
                    child: OutlinedButton(
                      onPressed: onViewDetails,
                      child: const Text('View Details'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Icon(
            icon,
            size: OrderCard._detailIcon,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(width: AppSpacing.x2),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall,
          ),
        ),
      ],
    );
  }
}
