import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mock/order_store.dart';
import '../../models/order.dart';
import '../../models/customer.dart';
import '../repositories/customers_repository.dart';
import '../repositories/firestore_customers_repository.dart';
import '../repositories/firestore_orders_repository.dart';
import 'backend_providers.dart';
import 'orders_providers.dart';

/// The customer source: Firestore's `users` when the app has a database,
/// the in-memory orders otherwise. Overridden in tests.
final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  if (db != null) {
    return FirestoreCustomersRepository(db, FirestoreOrdersRepository(db));
  }
  return InMemoryCustomersRepository(ref.watch(orderStoreProvider.notifier));
});

/// Everyone on record.
///
/// Watches the orders, because what someone has spent is made of them: an
/// order cancelled on the orders tab changes the figure, and this list has to
/// follow.
final customersProvider = FutureProvider<List<Customer>>((ref) {
  ref.watch(orderStoreProvider);
  watchCollections(ref, orderCollections);
  return ref.watch(customersRepositoryProvider).fetchCustomers();
});

/// One customer's orders, keyed by [Customer.id].
///
/// Watches the orders for the same reason the list does: a transition on the
/// orders tab changes what shows here.
final customerOrdersProvider = FutureProvider.family<List<Order>, String>((
  ref,
  id,
) {
  ref.watch(orderStoreProvider);
  watchCollections(ref, orderCollections);
  return ref.watch(customersRepositoryProvider).fetchOrdersFor(id);
});
