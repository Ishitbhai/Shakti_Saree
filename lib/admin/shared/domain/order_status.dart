/// Where an order sits in the fulfilment flow.
///
/// Shared by the dashboard and the orders list, so it lives outside both.
/// `isNew` rather than `new`, which is a reserved word.
enum OrderStatus {
  isNew('New'),
  packed('Packed'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.label);

  /// Text shown on the status pill and the filter chips.
  final String label;

  /// The one action an admin is expected to take next, or null when the order
  /// needs nothing further.
  String? get nextActionLabel => switch (this) {
    OrderStatus.isNew => 'Accept',
    OrderStatus.packed => 'Ship',
    OrderStatus.shipped => 'Mark Delivered',
    OrderStatus.delivered => null,
    OrderStatus.cancelled => null,
  };
}
