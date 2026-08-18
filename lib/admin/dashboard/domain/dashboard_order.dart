/// Where an order sits in the fulfilment flow.
///
/// `isNew` rather than `new`, which is a reserved word.
enum OrderStatus {
  isNew('New'),
  packed('Packed'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.label);

  /// Text shown on the status pill.
  final String label;
}

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
