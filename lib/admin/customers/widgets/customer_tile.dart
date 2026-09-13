import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../shared/widgets/initials_avatar.dart';
import '../customer.dart';

/// One row of the customer list: initials, name and number, what they have
/// ordered and spent.
class CustomerTile extends StatelessWidget {
  const CustomerTile({super.key, required this.customer, this.onTap});

  final Customer customer;
  final VoidCallback? onTap;

  /// Straight from the design; not on the base-4 scale.
  static const double _padding = 12;
  static const double _chevron = 18;

  @override
  Widget build(BuildContext context) {
    final orders = customer.orderCount == 1
        ? '1 order'
        : '${Formatters.count(customer.orderCount)} orders';
    final spent = Formatters.rupeesFromPaise(customer.spentPaise);

    return MergeSemantics(
      child: Semantics(
        label: '${customer.name}, ${customer.phone}, $orders, $spent spent',
        button: onTap != null,
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
                  children: [
                    InitialsAvatar(
                      initials: customer.initials,
                      // Seeded on the number, which is the identity — a
                      // renamed customer keeps their colour.
                      seed: customer.phone,
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              customer.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleMedium,
                            ),
                            Text(
                              customer.phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption,
                            ),
                            const SizedBox(height: AppSpacing.x1),
                            Text(
                              '$orders  •  $spent spent',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: AppSpacing.x2),
                      const ExcludeSemantics(
                        child: Icon(
                          Icons.chevron_right,
                          size: _chevron,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
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
