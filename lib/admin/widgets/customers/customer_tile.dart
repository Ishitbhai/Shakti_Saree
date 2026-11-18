import 'package:flutter/material.dart';

import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';
import '../../styles/app_typography.dart';
import '../../utils/formatters.dart';
import '../common/initials_avatar.dart';
import '../../models/customer.dart';

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
    final contact = Formatters.phone(customer.phone);

    return MergeSemantics(
      child: Semantics(
        label: '${customer.name}, $contact, $orders, $spent spent',
        button: onTap != null,
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
                    // Seeded on the id, which is the identity — a
                    // renamed customer keeps their colour.
                    seed: customer.id,
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
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            contact,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption,
                          ),
                          const SizedBox(height: AppSpacing.x1),
                          Text(
                            '$orders  •  $spent spent',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.success,
                            ),
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
    );
  }
}
