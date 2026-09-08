import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mock/order_store.dart';
import '../shared/models/order.dart';
import 'orders_repository.dart';

/// The orders source. Overridden in tests and, later, swapped for the HTTP
/// implementation in one place.
///
/// Watches the store's notifier rather than its contents: the repository
/// itself does not change when an order does, so rebuilding it on every
/// transition would throw away a perfectly good object.
final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => InMemoryOrdersRepository(ref.watch(orderStoreProvider.notifier)),
);

/// Every order. Screens filter by status themselves, so the read is shared
/// across the filter chips rather than refetched per tab.
///
/// Watches the stored list, so a transition anywhere re-runs this on its own
/// — the list, the header count and the filter chips catch up without a
/// screen having to invalidate anything.
final ordersProvider = FutureProvider<List<Order>>((ref) {
  ref.watch(orderStoreProvider);
  return ref.watch(ordersRepositoryProvider).fetchOrders();
});
