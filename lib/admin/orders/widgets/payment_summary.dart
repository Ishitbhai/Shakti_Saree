import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/order_detail.dart';

/// Subtotal, delivery and discount, then what was actually paid.
class PaymentSummary extends StatelessWidget {
  const PaymentSummary({super.key, required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
          label: 'Subtotal',
          value: Formatters.rupeesFromPaise(detail.subtotalPaise),
        ),
        const SizedBox(height: AppSpacing.x2),
        _Row(
          label: 'Delivery',
          value: detail.isFreeDelivery
              ? 'FREE'
              : Formatters.rupeesFromPaise(detail.deliveryPaise),
          // Free delivery and money off are both good news for the customer.
          valueColor: detail.isFreeDelivery ? AppColors.success : null,
        ),
        if (detail.discountPaise > 0) ...[
          const SizedBox(height: AppSpacing.x2),
          _Row(
            label: 'Discount',
            value: '− ${Formatters.rupeesFromPaise(detail.discountPaise)}',
            valueColor: AppColors.success,
          ),
        ],
        const SizedBox(height: AppSpacing.x3),
        const Divider(),
        const SizedBox(height: AppSpacing.x3),
        Row(
          children: [
            Expanded(
              child: Text(
                'Paid via ${detail.paidVia}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Text(
              Formatters.rupeesFromPaise(detail.totalPaise),
              style: AppTypography.price,
            ),
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall,
          ),
        ),
        const SizedBox(width: AppSpacing.x2),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: valueColor ?? AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
