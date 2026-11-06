import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_schema.dart';
import '../mock/order_store.dart';
import 'products_providers.dart';
import '../../models/order.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/firestore_customers_repository.dart';
import '../repositories/firestore_dashboard_repository.dart';
import '../repositories/firestore_orders_repository.dart';
import '../../models/dashboard_stats.dart';
import 'backend_providers.dart';
import 'orders_providers.dart';

/// The dashboard source: Firestore when the app has one, the in-memory store
/// otherwise. Overridden in tests.
///
/// Reads through the same repositories the Orders and Customers tabs do, so
/// the figures can never disagree with those lists.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  if (db != null) {
    final orders = FirestoreOrdersRepository(db);
    return FirestoreDashboardRepository(
      db,
      orders,
      FirestoreCustomersRepository(db, orders),
    );
  }
  return InMemoryDashboardRepository(
    ref.watch(orderStoreProvider.notifier),
    ref.watch(productsRepositoryProvider),
  );
});

/// The recent-orders strip under the monogram.
///
/// Watches the orders, so a status changed on the orders tab is already
/// changed here by the time the dashboard is looked at again.
final recentOrdersProvider = FutureProvider<List<Order>>((ref) {
  ref.watch(orderStoreProvider);
  watchCollections(ref, orderCollections);
  return ref.watch(dashboardRepositoryProvider).fetchRecentOrders();
});

/// The figures on the KPI tiles, counted rather than written down.
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) {
  ref.watch(orderStoreProvider);
  watchCollections(ref, const [...orderCollections, Fs.products]);
  return ref.watch(dashboardRepositoryProvider).fetchStats();
});
