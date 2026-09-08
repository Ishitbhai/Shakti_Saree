import '../shared/models/order_status.dart';

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

/// A step in the fulfilment timeline: one status, and when the order reached
/// it.
///
/// A null [at] means the step has not happened yet.
class OrderEvent {
  const OrderEvent({required this.status, this.at, this.detail});

  /// The status this step stands for. The timeline is the flow, so every step
  /// is a status rather than a label someone wrote down.
  final OrderStatus status;

  final DateTime? at;

  /// A second line under the step, where the status carries something worth
  /// reading — the courier and AWB on Shipped, the reason on Cancelled.
  final String? detail;

  String get label => status.timelineLabel;

  bool get isDone => at != null;

  /// Cancellation is drawn differently: it ends the timeline rather than
  /// continuing it.
  bool get isCancellation => status == OrderStatus.cancelled;
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
    required this.reachedAt,
    required this.lines,
    required this.paidVia,
    this.deliveryPaise = 0,
    this.discountPaise = 0,
    this.courier,
    this.awbNumber,
    this.cancellationReason,
  });

  final String id;
  final String customer;
  final String phone;
  final String address;
  final DateTime placedAt;
  final OrderStatus status;

  /// When the order reached each status it has been through.
  ///
  /// The raw material for [timeline]: a status with an entry has happened, a
  /// status without one has not. Every timestamp comes from the backend, so
  /// nothing on screen is a time the app made up.
  final Map<OrderStatus, DateTime> reachedAt;

  final List<OrderLine> lines;

  /// Payment method, e.g. 'UPI'.
  final String paidVia;

  final int deliveryPaise;
  final int discountPaise;

  /// Carrier the parcel went out with. Set by the ship transition, so null
  /// until the order reaches [OrderStatus.shipped].
  final String? courier;

  /// The carrier's tracking number, alongside [courier].
  final String? awbNumber;

  /// Why the order was cancelled. Null unless the order is cancelled.
  final String? cancellationReason;

  /// Whether the parcel has courier details to show.
  bool get hasTracking => courier != null && awbNumber != null;

  /// The fulfilment steps to draw, in order.
  ///
  /// Derived rather than stored, so it cannot drift from [status]. On the
  /// happy path it is the whole flow, with the steps not yet reached left
  /// pending. A cancelled order stops at the cancellation: the steps it
  /// actually went through, then the cancellation itself, and nothing after —
  /// there is no longer anything pending to do.
  List<OrderEvent> get timeline {
    final isCancelled = status == OrderStatus.cancelled;

    final steps = [
      for (final step in OrderStatus.fulfilmentFlow)
        if (!isCancelled || reachedAt.containsKey(step))
          OrderEvent(
            status: step,
            at: reachedAt[step],
            detail: _detailFor(step),
          ),
    ];

    if (!isCancelled) return steps;

    return [
      ...steps,
      OrderEvent(
        status: OrderStatus.cancelled,
        at: reachedAt[OrderStatus.cancelled],
        detail: cancellationReason,
      ),
    ];
  }

  /// The second line for a step, where it has one.
  String? _detailFor(OrderStatus step) =>
      step == OrderStatus.shipped && hasTracking
      ? '$courier  •  $awbNumber'
      : null;

  int get subtotalPaise => lines.fold(0, (sum, line) => sum + line.pricePaise);

  int get totalPaise => subtotalPaise + deliveryPaise - discountPaise;

  bool get isFreeDelivery => deliveryPaise == 0;
}
