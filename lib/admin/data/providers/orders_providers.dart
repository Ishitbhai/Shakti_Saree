import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_schema.dart';
import '../mock/order_store.dart';
import '../../models/order.dart';
import '../repositories/firestore_orders_repository.dart';
import '../repositories/orders_repository.dart';
import 'backend_providers.dart';

/// The orders source: Firestore when the app has one, the in-memory store
/// otherwise. Overridden in tests.
///
/// Watches the store's notifier rather than its contents: the repository
/// itself does not change when an order does, so rebuilding it on every
/// transition would throw away a perfectly good object.
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  if (db != null) return FirestoreOrdersRepository(db);
  return InMemoryOrdersRepository(ref.watch(orderStoreProvider.notifier));
});

/// The collections an order summary is assembled from.
const orderCollections = [Fs.orders, Fs.orderItems, Fs.users];

/// Every order. Screens filter by status themselves, so the read is shared
/// across the filter chips rather than refetched per tab.
///
/// Watches the stored list — or the collections behind it — so a transition
/// anywhere, or a new order from the customer app, re-runs this on its own:
/// the list, the header count and the filter chips catch up without a
/// screen having to invalidate anything.
final ordersProvider = FutureProvider<List<Order>>((ref) {
  ref.watch(orderStoreProvider);
  watchCollections(ref, orderCollections);
  return ref.watch(ordersRepositoryProvider).fetchOrders();
});
