import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/models/order.dart';
import 'orders_repository.dart';

/// The orders source. Overridden in tests and, later, swapped for the HTTP
/// implementation in one place.
/// Not const: the in-memory implementation holds the transitions applied to
/// it, and the provider caches this one instance so those survive an
/// `invalidate` of [ordersProvider] below.
final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => InMemoryOrdersRepository(),
);

/// Every order. Screens filter by status themselves, so the read is shared
/// across the filter chips rather than refetched per tab.
final ordersProvider = FutureProvider<List<Order>>(
  (ref) => ref.watch(ordersRepositoryProvider).fetchOrders(),
);
