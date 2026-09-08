import '../shared/models/order.dart';
import '../shared/models/order_status.dart';

/// Reads what the dashboard shows.
///
/// Only the recent-orders strip for now. The KPI figures still live in
/// `widgets/stat_grid.dart` and move here once that widget is settled.
abstract interface class DashboardRepository {
  /// The handful of latest orders shown under the monogram.
  Future<List<Order>> fetchRecentOrders();
}

/// Serves the sample strip from memory.
///
/// Stands in until the backend exists. The API implementation belongs beside
/// this one and brings its own HTTP client; nothing above this file changes
/// when it arrives.
class InMemoryDashboardRepository implements DashboardRepository {
  const InMemoryDashboardRepository();

  /// Moved here out of the screen — presentation should not carry data.
  ///
  /// Deliberately the same two rows the dashboard already displayed; the
  /// orders list keeps its own fuller sample.
  static const List<Order> _recentOrders = [
    Order(
      id: '#SS20260726',
      customer: 'Priyanshu K.',
      itemCount: 3,
      amountPaise: 629700,
      status: OrderStatus.isNew,
    ),
    Order(
      id: '#SS20260725',
      customer: 'Vivek M.',
      itemCount: 3,
      amountPaise: 249900,
      status: OrderStatus.packed,
    ),
  ];

  @override
  Future<List<Order>> fetchRecentOrders() async => _recentOrders;
}
