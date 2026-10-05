/// Where an order sits in the fulfilment flow.
///
/// Shared by the dashboard and the orders list, so it lives outside both.
/// `isNew` rather than `new`, which is a reserved word.
///
/// The order of the values is the order of the flow, and [next] is the only
/// thing that defines which move is legal. Labels hang off that rather than
/// implying a sequence of their own.
enum OrderStatus {
  isNew('New'),
  accepted('Accepted'),
  packed('Packed'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.label);

  /// Text shown on the status pill and the filter chips.
  final String label;

  /// The status this one advances to, or null once the order is finished.
  ///
  /// Cancellation is deliberately not here: it leaves the happy path rather
  /// than continuing it, so it is reached through [canCancel] instead.
  OrderStatus? get next => switch (this) {
    OrderStatus.isNew => OrderStatus.accepted,
    OrderStatus.accepted => OrderStatus.packed,
    OrderStatus.packed => OrderStatus.shipped,
    OrderStatus.shipped => OrderStatus.delivered,
    OrderStatus.delivered => null,
    OrderStatus.cancelled => null,
  };

  /// Whether an admin may still cancel from here.
  ///
  /// Cancellable up to the point the parcel leaves. Once it is with the
  /// courier, unwinding it is a return, not a status change.
  bool get canCancel => switch (this) {
    OrderStatus.isNew || OrderStatus.accepted || OrderStatus.packed => true,
    OrderStatus.shipped ||
    OrderStatus.delivered ||
    OrderStatus.cancelled => false,
  };

  /// Whether the order has come to rest and needs nothing further.
  bool get isTerminal => next == null;

  /// How this status reads as a step that has happened, rather than as a
  /// state the order is in — 'Order Placed' rather than 'New'.
  String get timelineLabel =>
      this == OrderStatus.isNew ? 'Order Placed' : label;

  /// The happy path in order, from New through to Delivered.
  ///
  /// Walked from [next] rather than listed again, so the flow cannot end up
  /// disagreeing with the transitions that define it. Cancellation is not
  /// here: it leaves this path rather than appearing along it.
  static List<OrderStatus> get fulfilmentFlow {
    final flow = [OrderStatus.isNew];
    for (var status = OrderStatus.isNew.next; status != null;) {
      flow.add(status);
      status = status.next;
    }
    return flow;
  }

  /// The one action an admin is expected to take next, or null when the order
  /// needs nothing further. Short, for the narrow buttons on the list.
  String? get nextActionLabel => switch (this) {
    OrderStatus.isNew => 'Accept',
    OrderStatus.accepted => 'Pack',
    OrderStatus.packed => 'Ship',
    OrderStatus.shipped => 'Mark Delivered',
    OrderStatus.delivered => null,
    OrderStatus.cancelled => null,
  };

  /// The same action worded in full, for the wide button on the detail
  /// screen. Null wherever [nextActionLabel] is null.
  String? get nextActionLabelLong => switch (this) {
    OrderStatus.isNew => 'Accept Order',
    OrderStatus.accepted => 'Mark Packed',
    OrderStatus.packed => 'Mark Shipped',
    OrderStatus.shipped => 'Mark Delivered',
    OrderStatus.delivered => null,
    OrderStatus.cancelled => null,
  };
}
