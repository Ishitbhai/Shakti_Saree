import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../shared/models/order_status.dart';
import '../shared/widgets/admin_page_header.dart';
import '../shared/models/order.dart';
import 'order_detail.dart';
import 'order_detail_screen.dart';
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
  static List<Order> get _orders {
    final now = DateTime.now();
    return [
      Order(
        id: '#SS20260726',
        customer: 'priyanshu kateshiya',
        phone: '+91 98765 43210',
        itemCount: 3,
        amountPaise: 629700,
        status: OrderStatus.isNew,
        placedAt: now.subtract(const Duration(minutes: 16)),
      ),
      Order(
        id: '#SS20260725',
        customer: 'Vivek Makvana',
        phone: '+91 90000 11111',
        itemCount: 1,
        amountPaise: 249900,
        status: OrderStatus.isNew,
        placedAt: now.subtract(const Duration(hours: 1)),
      ),
      Order(
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

  /// Builds the fuller record the detail screen needs.
  ///
  /// The lines, address and payment breakdown are sample data — the list only
  /// carries a summary, and the repository will supply the rest.
  OrderDetail _detailFor(Order order) {
    // A detail record always has these; the summary type merely allows them
    // to be absent, and every order in this list supplies both.
    final placed = order.placedAt ?? DateTime.now();

    return OrderDetail(
      id: order.id,
      customer: 'Priyanshu Kateshiya',
      phone: order.phone ?? '',
      address: '301, Shakti Complex, Kalawad Road, Rajkot, Gujarat - 360005',
      placedAt: placed,
      status: order.status,
      paidVia: 'UPI',
      discountPaise: 50000,
      timeline: [
        OrderEvent(label: 'Order Placed', at: placed),
        OrderEvent(
          label: 'Payment Confirmed',
          at: placed.add(const Duration(minutes: 1)),
        ),
        OrderEvent(
          label: 'Packed',
          at: order.status == OrderStatus.isNew
              ? null
              : placed.add(const Duration(hours: 3, minutes: 28)),
        ),
        const OrderEvent(label: 'Shipped'),
      ],
      lines: const [
        OrderLine(
          name: 'Banarasi Silk Saree',
          sku: 'SS-1024',
          quantity: 1,
          pricePaise: 249900,
        ),
        OrderLine(
          name: 'Kanjivaram Pure Silk',
          sku: 'SS-1025',
          quantity: 1,
          pricePaise: 329900,
        ),
      ],
    );
  }

  void _openDetail(Order order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // Enabled but inert: styling comes from the design, the handlers
        // land with the repository.
        builder: (_) => OrderDetailScreen(
          detail: _detailFor(order),
          onCall: () {},
          onInvoice: () {},
          onAdvanceStatus: () {},
        ),
      ),
    );
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
                        // Inert until the repository lands; the button is
                        // styled from the design either way.
                        onPrimaryAction: () {},
                        onViewDetails: () => _openDetail(visible[index]),
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
