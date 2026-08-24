import '../../shared/domain/order_status.dart';

/// One order in the admin orders list.
///
/// Money is held as paise; [placedAt] is an instant, not a display string, so
/// the "16 min ago" wording is computed rather than stored.
class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.customer,
    required this.phone,
    required this.itemCount,
    required this.amountPaise,
    required this.status,
    required this.placedAt,
  });

  final String id;
  final String customer;
  final String phone;
  final int itemCount;
  final int amountPaise;
  final OrderStatus status;
  final DateTime placedAt;
}
