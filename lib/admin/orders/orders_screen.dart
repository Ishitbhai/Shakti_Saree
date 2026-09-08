import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../shared/models/order.dart';
import '../shared/models/order_status.dart';
import '../shared/widgets/admin_page_header.dart';
import '../shared/widgets/async_content.dart';
import 'order_detail_screen.dart';
import 'orders_providers.dart';
import 'widgets/order_card.dart';
import 'widgets/status_filter_chips.dart';

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

  Future<void> _openDetail(Order order) async {
    // The in-memory source answers immediately. Once this is a network call,
    // the tap needs feedback — either a spinner on the button or a detail
    // screen that loads itself.
    final detail = await ref
        .read(ordersRepositoryProvider)
        .fetchOrderDetail(order.id);
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        // The status action is the screen's own business now; Call and
        // Invoice are still inert, styled from the design.
        builder: (_) =>
            OrderDetailScreen(detail: detail, onCall: () {}, onInvoice: () {}),
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
        // Inert until the repository can write; the button is styled from
        // the design either way.
        onPrimaryAction: () {},
        onViewDetails: () => _openDetail(visible[index]),
      ),
    );
  }
}
