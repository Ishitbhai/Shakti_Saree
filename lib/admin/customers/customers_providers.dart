import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mock/order_store.dart';
import '../shared/models/order.dart';
import 'customer.dart';
import 'customers_repository.dart';

/// The customer source. Overridden in tests and, later, swapped for the HTTP
/// implementation in one place.
final customersRepositoryProvider = Provider<CustomersRepository>(
  (ref) => InMemoryCustomersRepository(ref.watch(orderStoreProvider.notifier)),
);

/// Everyone who has ordered.
///
/// Watches the stored orders, because that is what customers are made of: an
/// order cancelled on the orders tab changes what someone has spent, and this
/// list has to follow.
final customersProvider = FutureProvider<List<Customer>>((ref) {
  ref.watch(orderStoreProvider);
  return ref.watch(customersRepositoryProvider).fetchCustomers();
});

/// One customer's orders, keyed by their phone number.
///
/// Watches the store for the same reason the list does: a transition on the
/// orders tab changes what shows here.
final customerOrdersProvider = FutureProvider.family<List<Order>, String>((
  ref,
  phone,
) {
  ref.watch(orderStoreProvider);
  return ref.watch(customersRepositoryProvider).fetchOrdersFor(phone);
});
