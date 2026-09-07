import '../../shared/domain/order_status.dart';

/// One product line on an order.
class OrderLine {
  const OrderLine({
    required this.name,
    required this.sku,
    required this.quantity,
    required this.pricePaise,
  });

  final String name;
  final String sku;
  final int quantity;

  /// Price for the whole line, not per unit.
  final int pricePaise;
}

/// A step in the fulfilment timeline.
///
/// A null [at] means the step has not happened yet.
class OrderEvent {
  const OrderEvent({required this.label, this.at});

  final String label;
  final DateTime? at;

  bool get isDone => at != null;
}

/// Everything the order detail screen shows.
///
/// Money is held as paise throughout; the totals are derived rather than
/// stored, so they can never drift from the lines.
class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.customer,
    required this.phone,
    required this.address,
    required this.placedAt,
    required this.status,
    required this.timeline,
    required this.lines,
    required this.paidVia,
    this.deliveryPaise = 0,
    this.discountPaise = 0,
  });

  final String id;
  final String customer;
  final String phone;
  final String address;
  final DateTime placedAt;
  final OrderStatus status;
  final List<OrderEvent> timeline;
  final List<OrderLine> lines;

  /// Payment method, e.g. 'UPI'.
  final String paidVia;

  final int deliveryPaise;
  final int discountPaise;

  int get subtotalPaise => lines.fold(0, (sum, line) => sum + line.pricePaise);

  int get totalPaise => subtotalPaise + deliveryPaise - discountPaise;

  bool get isFreeDelivery => deliveryPaise == 0;
}
