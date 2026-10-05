import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../styles/app_colors.dart';
import '../styles/app_spacing.dart';
import '../styles/app_typography.dart';
import '../utils/formatters.dart';
import '../models/order.dart';
import '../widgets/common/admin_page_header.dart';
import '../widgets/common/async_content.dart';
import '../widgets/common/order_tile.dart';
import '../models/customer.dart';
import '../data/providers/customers_providers.dart';

/// What one customer has ordered.
///
/// Read-only: the actions on an order belong on the orders tab, where the
/// whole queue is in view. This answers "what has this person bought", which
/// is what the row on the customer list was promising.
class CustomerOrdersScreen extends ConsumerWidget {
  const CustomerOrdersScreen({super.key, required this.customer});

  final Customer customer;

  static const double _screenPadding = AppSpacing.x5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(customerOrdersProvider(customer.phone));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AdminPageHeader(title: customer.name, subtitle: customer.phone),
            Expanded(
              child: AsyncContent<List<Order>>(
                state: orders,
                onRetry: () =>
                    ref.invalidate(customerOrdersProvider(customer.phone)),
                isEmpty: (loaded) => loaded.isEmpty,
                emptyMessage: 'No orders from this customer.',
                builder: (context, loaded) => ListView(
                  padding: const EdgeInsets.fromLTRB(
                    _screenPadding,
                    AppSpacing.x2,
                    _screenPadding,
                    AppSpacing.x6,
                  ),
                  children: [
                    Text(
                      '${loaded.length == 1 ? '1 order' : '${Formatters.count(loaded.length)} orders'}'
                      '  •  '
                      '${Formatters.rupeesFromPaise(customer.spentPaise)} spent',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    for (final order in loaded) ...[
                      OrderTile(order: order),
                      if (order != loaded.last)
                        const SizedBox(height: AppSpacing.x3),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
