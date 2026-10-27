import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../firestore/firestore_schema.dart';
import '../../models/dashboard_stats.dart';
import '../../models/order.dart';
import 'dashboard_repository.dart';
import 'firestore_customers_repository.dart';
import 'firestore_orders_repository.dart';

/// Counts the dashboard's figures off the live collections.
///
/// Through the same repositories the Orders and Customers tabs use, so the
/// tiles say exactly what those screens list.
class FirestoreDashboardRepository implements DashboardRepository {
  const FirestoreDashboardRepository(this._db, this._orders, this._customers);

  final FirebaseFirestore _db;
  final FirestoreOrdersRepository _orders;
  final FirestoreCustomersRepository _customers;

  @override
  Future<List<Order>> fetchRecentOrders() => guardFirestore(
    () async => (await _orders.fetchSummaries())
        .take(InMemoryDashboardRepository.recentCount)
        .toList(),
  );

  @override
  Future<DashboardStats> fetchStats() => guardFirestore(() async {
    final (orders, products, customers) = await (
      _db.collection(Fs.orders).count().get(),
      _db.collection(Fs.products).count().get(),
      _customers.fetchCustomers(),
    ).wait;

    return DashboardStats(
      totalOrders: orders.count ?? 0,
      products: products.count ?? 0,
      customers: customers.length,
    );
  });
}
