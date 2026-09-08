import '../../mock/order_store.dart';
import '../products/products_repository.dart';
import '../shared/models/order.dart';
import 'dashboard_stats.dart';

/// Reads what the dashboard shows.
///
/// The dashboard is a view over other people's data — the orders and the
/// catalogue — rather than a thing that owns any of its own. This reads
/// across both and counts.
abstract interface class DashboardRepository {
  /// The handful of latest orders shown under the monogram.
  Future<List<Order>> fetchRecentOrders();

  /// The figures on the KPI tiles.
  Future<DashboardStats> fetchStats();
}

/// Counts the dashboard's figures off the shared in-memory store.
///
/// Holds nothing itself. It reads the same orders the list screen reads, so
/// accepting an order on one screen is the same order the strip shows on the
/// other — there is no second copy to fall out of step.
///
/// Stands in until the backend exists, which will almost certainly serve
/// these totals ready-counted rather than making the app tally them.
class InMemoryDashboardRepository implements DashboardRepository {
  const InMemoryDashboardRepository(this._store, this._products);

  final OrderStore _store;
  final ProductsRepository _products;

  /// How many rows the strip shows. Enough to see more than one status at a
  /// glance without turning the dashboard into a second orders list.
  static const int recentCount = 4;

  @override
  Future<List<Order>> fetchRecentOrders() async => _store.recent(recentCount);

  @override
  Future<DashboardStats> fetchStats() async {
    final orders = _store.orders;
    final catalogue = await _products.fetchProducts();

    return DashboardStats(
      totalOrders: orders.length,
      products: catalogue.length,
      // By person, not by order: two orders from the same customer are one
      // customer.
      customers: orders.map((order) => order.customer).toSet().length,
    );
  }
}
