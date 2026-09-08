import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mock/order_store.dart';
import '../products/products_providers.dart';
import '../shared/models/order.dart';
import 'dashboard_repository.dart';
import 'dashboard_stats.dart';

/// The dashboard source. Overridden in tests and, later, swapped for the HTTP
/// implementation in one place.
///
/// Reads the same store the orders list does, so the two can never disagree
/// about an order's status.
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => InMemoryDashboardRepository(
    ref.watch(orderStoreProvider.notifier),
    ref.watch(productsRepositoryProvider),
  ),
);

/// The recent-orders strip under the monogram.
///
/// Watches the stored orders, so a status changed on the orders tab is
/// already changed here by the time the dashboard is looked at again.
final recentOrdersProvider = FutureProvider<List<Order>>((ref) {
  ref.watch(orderStoreProvider);
  return ref.watch(dashboardRepositoryProvider).fetchRecentOrders();
});

/// The figures on the KPI tiles, counted rather than written down.
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) {
  ref.watch(orderStoreProvider);
  return ref.watch(dashboardRepositoryProvider).fetchStats();
});
