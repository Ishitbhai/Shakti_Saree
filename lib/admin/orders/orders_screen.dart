import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../shared/models/order.dart';
import '../shared/models/order_status.dart';
import '../shared/widgets/admin_page_header.dart';
import '../shared/widgets/async_content.dart';
import 'order_detail_screen.dart';
import 'orders_repository.dart';
import 'widgets/order_card.dart';
import 'widgets/status_filter_chips.dart';

/// Admin orders list, filtered by fulfilment status.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.repository});

  /// Injectable so tests can supply their own orders or a failing source.
  final OrdersRepository? repository;

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
  late final OrdersRepository _repository =
      widget.repository ?? const InMemoryOrdersRepository();

  OrderStatus _filter = OrderStatus.isNew;
  List<Order>? _orders;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await _repository.fetchOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  Future<void> _openDetail(Order order) async {
    // The in-memory source answers immediately. Once this is a network call,
    // the tap needs feedback — either a spinner on the button or a detail
    // screen that loads itself.
    final detail = await _repository.fetchOrderDetail(order.id);
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        // Enabled but inert: styling comes from the design, the handlers
        // land with the repository.
        builder: (_) => OrderDetailScreen(
          detail: detail,
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
    final newToday =
        orders?.where((o) => o.status == OrderStatus.isNew).length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AdminPageHeader(
              title: 'Orders',
              // Blank until the count is known, so the header keeps its
              // height instead of jumping when the orders arrive.
              subtitle: orders == null
                  ? ''
                  : '${Formatters.count(newToday)} new today',
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
                value: orders,
                error: _error,
                onRetry: _load,
                builder: (context, loaded) => _buildList(
                  loaded.where((o) => o.status == _filter).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Order> visible) {
    if (visible.isEmpty) {
      return AsyncMessage(text: 'No ${_filter.label.toLowerCase()} orders');
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
