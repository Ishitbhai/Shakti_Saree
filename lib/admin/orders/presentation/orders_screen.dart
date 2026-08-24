import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../shared/domain/order_status.dart';
import '../../shared/widgets/admin_page_header.dart';
import '../domain/admin_order.dart';
import 'widgets/order_card.dart';
import 'widgets/status_filter_chips.dart';

/// Admin orders list, filtered by fulfilment status.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  /// The statuses an admin works through, in order.
  static const List<OrderStatus> filters = [
    OrderStatus.isNew,
    OrderStatus.packed,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderStatus _filter = OrderStatus.isNew;

  /// Hardcoded until the repository lands. Timestamps are relative to now so
  /// the "16 min ago" wording stays true however long the demo runs.
  static List<AdminOrder> get _orders {
    final now = DateTime.now();
    return [
      AdminOrder(
        id: '#SS20260726',
        customer: 'priyanshu kateshiya',
        phone: '+91 98765 43210',
        itemCount: 3,
        amountPaise: 629700,
        status: OrderStatus.isNew,
        placedAt: now.subtract(const Duration(minutes: 16)),
      ),
      AdminOrder(
        id: '#SS20260725',
        customer: 'Vivek Makvana',
        phone: '+91 90000 11111',
        itemCount: 1,
        amountPaise: 249900,
        status: OrderStatus.isNew,
        placedAt: now.subtract(const Duration(hours: 1)),
      ),
      AdminOrder(
        id: '#SS20260724',
        customer: 'Ishit vadhavana',
        phone: '+91 91234 56789',
        itemCount: 2,
        amountPaise: 519800,
        status: OrderStatus.packed,
        placedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orders;
    final visible = orders.where((o) => o.status == _filter).toList();
    final newToday = orders.where((o) => o.status == OrderStatus.isNew).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AdminPageHeader(
              title: 'Orders',
              subtitle: '${Formatters.count(newToday)} new today',
            ),
            const SizedBox(height: AppSpacing.x2),
            StatusFilterChips(
              statuses: OrdersScreen.filters,
              selected: _filter,
              onSelect: (status) => setState(() => _filter = status),
            ),
            const SizedBox(height: AppSpacing.x4),
            Expanded(
              child: visible.isEmpty
                  ? _EmptyState(status: _filter)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.x5,
                        0,
                        AppSpacing.x5,
                        AppSpacing.x6,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.x4),
                      itemBuilder: (context, index) => OrderCard(
                        order: visible[index],
                        // Enabled but inert: the buttons are styled from the
                        // design, and the handlers land with the repository.
                        onPrimaryAction: () {},
                        onViewDetails: () {},
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No ${status.label.toLowerCase()} orders',
        style: AppTypography.bodySmall,
      ),
    );
  }
}
