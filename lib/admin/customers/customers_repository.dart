import '../../mock/mock_data.dart';
import '../../mock/order_store.dart';
import '../shared/models/order.dart';
import '../shared/models/order_status.dart';
import 'customer.dart';

/// Reads the people who have ordered.
abstract interface class CustomersRepository {
  /// Everyone on record, the biggest spenders first.
  Future<List<Customer>> fetchCustomers();

  /// What one person has ordered, newest first.
  Future<List<Order>> fetchOrdersFor(String phone);
}

/// Builds the customer list out of the shared order store.
///
/// There is nowhere else it could come from: the app has orders and a
/// catalogue, and no customer records of its own. Reading the same store the
/// orders list reads means a name corrected on an order is the name shown
/// here, and the dashboard's customer count and this list can never disagree
/// about how many there are.
///
/// A real backend would almost certainly have a customers table and serve
/// this directly, totals and all. That is a swap of this class, not of
/// anything above it.
class InMemoryCustomersRepository implements CustomersRepository {
  const InMemoryCustomersRepository(this._store);

  final OrderStore _store;

  @override
  Future<List<Customer>> fetchCustomers() async {
    // Grouped by phone rather than by name: two people can share a name, and
    // the number is what the order was placed against.
    final byPhone = <String, List<({String name, int paise, bool counts})>>{};

    for (final order in _store.orders) {
      (byPhone[order.phone] ??= []).add((
        name: order.customer,
        paise: order.totalPaise,
        counts: order.status != OrderStatus.cancelled,
      ));
    }

    final customers = [
      for (final entry in byPhone.entries)
        Customer(
          // The most recent spelling wins; the store holds orders newest
          // first, so that is the one at the front.
          name: entry.value.first.name,
          phone: entry.key,
          orderCount: entry.value.length,
          spentPaise: entry.value
              .where((order) => order.counts)
              .fold(0, (sum, order) => sum + order.paise),
        ),
    ];

    // Biggest spenders first: the list is read to see who matters, and an
    // arbitrary order would make that a hunt.
    customers.sort((a, b) => b.spentPaise.compareTo(a.spentPaise));
    return customers;
  }

  @override
  Future<List<Order>> fetchOrdersFor(String phone) async => [
    for (final order in _store.orders)
      if (order.phone == phone) MockData.summaryOf(order),
  ];
}
