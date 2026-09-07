import '../../shared/domain/order_status.dart';

/// One row of the dashboard's recent-orders list.
///
/// Money is held as paise; formatting happens at the widget.
class DashboardOrder {
  const DashboardOrder({
    required this.id,
    required this.customer,
    required this.itemCount,
    required this.amountPaise,
    required this.status,
  });

  final String id;
  final String customer;
  final int itemCount;
  final int amountPaise;
  final OrderStatus status;
}
