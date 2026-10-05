/// The figures on the dashboard's KPI tiles.
///
/// Counted from what the app actually holds rather than written down, so the
/// tiles cannot claim one thing while the orders list shows another.
class DashboardStats {
  const DashboardStats({
    required this.totalOrders,
    required this.products,
    required this.customers,
  });

  /// Every order on record, whatever status it is in.
  final int totalOrders;

  /// Listings in the catalogue.
  final int products;

  /// Distinct people who have ordered, not orders placed.
  final int customers;
}
