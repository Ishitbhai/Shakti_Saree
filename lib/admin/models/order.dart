import 'order_status.dart';

/// A customer order, as the admin screens see it.
///
/// One class for the dashboard's recent-orders strip and the full orders
/// list, because they are the same entity — the dashboard simply shows fewer
/// of its fields.
///
/// Money is held as paise; formatting happens at the widget.
class Order {
  const Order({
    required this.id,
    required this.customer,
    required this.itemCount,
    required this.amountPaise,
    required this.status,
    this.phone,
    this.placedAt,
  });

  final String id;
  final String customer;
  final int itemCount;
  final int amountPaise;
  final OrderStatus status;

  /// Absent in summaries that do not need to offer a call.
  final String? phone;

  /// Absent in summaries that show no timestamp.
  final DateTime? placedAt;
}
