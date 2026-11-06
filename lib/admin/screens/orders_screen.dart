import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../styles/app_colors.dart';
import '../styles/app_spacing.dart';
import '../utils/formatters.dart';
import '../models/order.dart';
import '../models/order_detail.dart';
import '../models/order_status.dart';
import '../widgets/orders/ship_order_sheet.dart';
import '../widgets/common/admin_page_header.dart';
import '../widgets/common/async_content.dart';
import 'order_detail_screen.dart';
import '../data/providers/orders_providers.dart';
import '../widgets/orders/order_card.dart';
import '../widgets/orders/status_filter_chips.dart';
import '../widgets/navigation/admin_route.dart';

/// Admin orders list, filtered by fulfilment status.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  /// The statuses an admin works through, in flow order, preceded by an
  /// 'All' chip the widget adds itself.
  ///
  /// Every status appears: an order that reaches one missing from this list
  /// would be filtered out of every tab and become unreachable.
  static const List<OrderStatus> filters = [
    OrderStatus.isNew,
    OrderStatus.accepted,
    OrderStatus.packed,
    OrderStatus.shipped,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  /// Null is the 'All' chip. Opens on New because that is the queue an admin
  /// actually works, not because the other tabs matter less.
  OrderStatus? _filter = OrderStatus.isNew;

  /// The order whose detail is being fetched, so a second tap does not open
  /// it twice and the list can show that something is happening.
  String? _opening;

  Future<void> _openDetail(Order order) async {
    if (_opening != null) return;
    // The in-memory source answers immediately; Firestore takes a moment, and
    // the bar under the header says so.
    setState(() => _opening = order.id);
    final OrderDetail detail;
    try {
      detail = await ref
          .read(ordersRepositoryProvider)
          .fetchOrderDetail(order.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AsyncContent.messageFor(error))));
      return;
    } finally {
      if (mounted) setState(() => _opening = null);
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      AdminRoute<void>(
        // The status action is the screen's own business now; Call is still
        // inert, styled from the design.
        builder: (_) => OrderDetailScreen(detail: detail, onCall: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AdminPageHeader(
              title: 'Orders',
              // Blank until the count is known, so the header keeps its
              // height instead of jumping when the orders arrive.
              subtitle: orders.maybeWhen(
                data: (loaded) {
                  final newToday = loaded
                      .where((o) => o.status == OrderStatus.isNew)
                      .length;
                  return '${Formatters.count(newToday)} new today';
                },
                orElse: () => '',
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            StatusFilterChips(
              statuses: OrdersScreen.filters,
              selected: _filter,
              onSelect: (status) => setState(() => _filter = status),
            ),
            const SizedBox(height: AppSpacing.x4),
            // Same height whether showing or not, so the list does not jump.
            SizedBox(
              height: 2,
              child: _opening != null || _advancing != null
                  ? const LinearProgressIndicator()
                  : null,
            ),
            Expanded(
              child: AsyncContent<List<Order>>(
                state: orders,
                onRetry: () => ref.invalidate(ordersProvider),
                builder: (context, loaded) => _buildList(_visible(loaded)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The orders the current chip admits — everything, when the chip is 'All'.
  List<Order> _visible(List<Order> orders) {
    final filter = _filter;
    if (filter == null) return orders;
    return orders.where((order) => order.status == filter).toList();
  }

  Widget _buildList(List<Order> visible) {
    if (visible.isEmpty) {
      final filter = _filter;
      return AsyncMessage(
        text: filter == null
            ? 'No orders yet'
            : 'No ${filter.label.toLowerCase()} orders',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        0,
        AppSpacing.x5,
        AppSpacing.x6,
      ),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x4),
      itemBuilder: (context, index) => OrderCard(
        order: visible[index],
        // Disabled while any order is moving, so a double tap cannot try
        // the same step twice.
        onPrimaryAction: _advancing == null
            ? () => _advance(visible[index])
            : null,
        onViewDetails: () => _openDetail(visible[index]),
      ),
    );
  }

  /// The order whose next step is in flight from the list.
  String? _advancing;

  /// Takes the order one step along, as the detail screen's main button
  /// does. Shipping opens the courier sheet first, because it cannot be done
  /// without the courier details.
  Future<void> _advance(Order order) async {
    final repository = ref.read(ordersRepositoryProvider);
    final id = order.id;

    setState(() => _advancing = id);
    try {
      switch (order.status) {
        case OrderStatus.isNew:
          await repository.acceptOrder(id);
        case OrderStatus.accepted:
          await repository.markPacked(id);
        case OrderStatus.shipped:
          await repository.markDelivered(id);
        case OrderStatus.packed:
          final shipped = await ShipOrderSheet.show(
            context,
            onSubmit: ({required courier, required awbNumber}) => repository
                .markShipped(id, courier: courier, awbNumber: awbNumber),
          );
          if (shipped == null) return;
        case OrderStatus.delivered || OrderStatus.cancelled:
          return;
      }
      ref.invalidate(ordersProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AsyncContent.messageFor(error))));
    } finally {
      if (mounted) setState(() => _advancing = null);
    }
  }
}
