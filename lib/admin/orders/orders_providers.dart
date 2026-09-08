import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/models/order.dart';
import 'orders_repository.dart';

/// The orders source. Overridden in tests and, later, swapped for the HTTP
/// implementation in one place.
final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => const InMemoryOrdersRepository(),
);

/// Every order. Screens filter by status themselves, so the read is shared
/// across the filter chips rather than refetched per tab.
final ordersProvider = FutureProvider<List<Order>>(
  (ref) => ref.watch(ordersRepositoryProvider).fetchOrders(),
);
