import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../firestore/firestore_schema.dart';
import '../../models/customer.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import 'customers_repository.dart';
import 'firestore_orders_repository.dart';

/// Reads the customers out of the `users` collection.
///
/// Unlike the in-memory sample there are real accounts to list, so someone
/// who has registered but not yet ordered is a customer too. What they have
/// ordered and spent is still counted from `orders`, so the figure here and
/// the orders tab cannot disagree.
///
/// Admin accounts (`user_type` 'admin') are left out: they run the shop
/// rather than buy from it.
class FirestoreCustomersRepository implements CustomersRepository {
  const FirestoreCustomersRepository(this._db, this._orders);

  final FirebaseFirestore _db;
  final FirestoreOrdersRepository _orders;

  @override
  Future<List<Customer>> fetchCustomers() => guardFirestore(() async {
    final (users, orders) = await (
      _db.collection(Fs.users).get(),
      _db.collection(Fs.orders).get(),
    ).wait;

    final placed = <String, List<Map<String, dynamic>>>{};
    for (final order in orders.docs) {
      (placed[Fs.stringOf(order.data()[Fs.userId])] ??= []).add(order.data());
    }

    final customers = <Customer>[];
    final listed = <String>{};
    for (final doc in users.docs) {
      final data = doc.data();
      if (Fs.stringOf(data[Fs.userType]).toLowerCase() == Fs.adminType) {
        continue;
      }
      final id = Fs.stringOf(data[Fs.userId]).isEmpty
          ? doc.id
          : Fs.stringOf(data[Fs.userId]);
      customers.add(
        _customerOf(id: id, account: data, orders: placed[id] ?? const []),
      );
      listed.add(id);
    }

    // Orders from an account that has no user document still belong to
    // somebody, and their spend should not vanish from the list.
    for (final MapEntry(key: id, value: theirs) in placed.entries) {
      if (id.isEmpty || listed.contains(id)) continue;
      customers.add(_customerOf(id: id, account: const {}, orders: theirs));
    }

    customers.sort((a, b) => b.spentPaise.compareTo(a.spentPaise));
    return customers;
  });

  @override
  Future<List<Order>> fetchOrdersFor(String id) =>
      guardFirestore(() => _orders.fetchSummaries(userId: id));

  /// An account made in the customer app often has no name or number of its
  /// own. Those are on the delivery address it saved, or failing that on the
  /// latest order it placed.
  static Customer _customerOf({
    required String id,
    required Map<String, dynamic> account,
    required List<Map<String, dynamic>> orders,
  }) {
    final addresses = [account, ...orders.toList()..sort(_newestFirst)];
    String? given(String? Function(Map<String, dynamic>) read) =>
        addresses.map(read).nonNulls.firstOrNull;

    return Customer(
      id: id,
      name:
          Fs.optionalString(account[Fs.name]) ??
          given(FirestoreOrdersRepository.recipientNameOf) ??
          id,
      phone:
          FirestoreOrdersRepository.phoneOf(account) ??
          given(FirestoreOrdersRepository.recipientPhoneOf) ??
          Fs.stringOf(account[Fs.email]),
      orderCount: orders.length,
      // A cancelled order is not money taken.
      spentPaise: orders
          .where((order) => Fs.orderStatusOf(order) != OrderStatus.cancelled)
          .fold(0, (total, order) => total + Fs.paiseOf(order[Fs.totalAmount])),
    );
  }

  static int _newestFirst(Map<String, dynamic> a, Map<String, dynamic> b) {
    final at = FirestoreOrdersRepository.placedAtOf(a);
    final bt = FirestoreOrdersRepository.placedAtOf(b);
    if (at == null || bt == null) {
      return at == bt ? 0 : (at == null ? 1 : -1);
    }
    return bt.compareTo(at);
  }
}
