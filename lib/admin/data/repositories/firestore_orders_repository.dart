import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../api_exception.dart';
import '../firestore/firestore_schema.dart';
import '../../models/order.dart';
import '../../models/order_detail.dart';
import '../../models/order_status.dart';
import 'orders_repository.dart';

typedef FsDoc = QueryDocumentSnapshot<Map<String, dynamic>>;

/// Serves orders from the `orders` collection, joined to the rest.
///
/// An order document holds little of what the screens show: the lines are in
/// `order_items`, the customer's name and address on their `users` document,
/// the product names in `products` and how it was paid in `payments`. Every
/// one of those points back by business id (`order_id`, `user_id`, …), so
/// that is what the joins go by.
///
/// The fulfilment flow writes `status` in the same words the database
/// already uses ('Pending' for New), and records when each step happened in
/// `status_history`, which is where the detail screen's timeline comes from.
class FirestoreOrdersRepository implements OrdersRepository {
  const FirestoreOrdersRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(Fs.orders);

  @override
  Future<List<Order>> fetchOrders() => guardFirestore(() => fetchSummaries());

  /// Every order as the list sees it, newest first — or only [userId]'s.
  ///
  /// Shared with the customers and dashboard repositories, which show the
  /// same rows.
  Future<List<Order>> fetchSummaries({String? userId}) async {
    final orderQuery = userId == null
        ? _orders
        : _orders.where(Fs.userId, isEqualTo: userId);
    final (orders, items, users) = await (
      orderQuery.get(),
      _db.collection(Fs.orderItems).get(),
      _db.collection(Fs.users).get(),
    ).wait;

    final itemCounts = <String, int>{};
    for (final item in items.docs) {
      final orderId = Fs.stringOf(item.data()[Fs.orderId]);
      itemCounts[orderId] =
          (itemCounts[orderId] ?? 0) + Fs.intOf(item.data()[Fs.quantity]);
    }
    final people = usersById(users.docs);

    final summaries = [
      for (final doc in orders.docs)
        _summaryOf(doc, people[Fs.stringOf(doc.data()[Fs.userId])], itemCounts),
    ];
    summaries.sort((a, b) {
      final at = a.placedAt, bt = b.placedAt;
      if (at == null || bt == null) return at == null ? 1 : -1;
      return bt.compareTo(at);
    });
    return summaries;
  }

  @override
  Future<OrderDetail> fetchOrderDetail(String id) => guardFirestore(() async {
    final doc = await _findOrder(id);
    final data = doc.fields;
    final userId = Fs.stringOf(data[Fs.userId]);
    final paymentId = Fs.stringOf(data[Fs.paymentId]);

    final (items, products, user, payment) = await (
      _db.collection(Fs.orderItems).where(Fs.orderId, isEqualTo: id).get(),
      _db.collection(Fs.products).get(),
      _findUser(userId),
      _findPayment(paymentId: paymentId, orderId: id),
    ).wait;

    final productNames = {
      for (final product in products.docs)
        Fs.stringOf(product.data()[Fs.productId]): Fs.stringOf(
          product.data()[Fs.productName],
        ),
    };

    final lines = [
      for (final item in items.docs) _lineOf(item.data(), productNames),
    ]..sort((a, b) => a.sku.compareTo(b.sku));

    return detailOf(
      id: id,
      order: data,
      user: user,
      lines: lines,
      payment: payment,
    );
  });

  @override
  Future<OrderDetail> acceptOrder(String id) =>
      _advance(id, OrderStatus.accepted);

  @override
  Future<OrderDetail> markPacked(String id) => _advance(id, OrderStatus.packed);

  @override
  Future<OrderDetail> markShipped(
    String id, {
    required String courier,
    required String awbNumber,
  }) => _advance(
    id,
    OrderStatus.shipped,
    extra: {Fs.courier: courier.trim(), Fs.awbNumber: awbNumber.trim()},
  );

  @override
  Future<OrderDetail> markDelivered(String id) =>
      _advance(id, OrderStatus.delivered);

  @override
  Future<OrderDetail> cancelOrder(String id, {required String reason}) =>
      _write(
        id,
        OrderStatus.cancelled,
        allowed: (current) => current.canCancel,
        refusal: (current) =>
            'A ${current.label.toLowerCase()} order can no longer be '
            'cancelled.',
        extra: {Fs.cancellationReason: reason.trim()},
      );

  /// Applies the one move [OrderStatus.next] allows, and nothing else.
  Future<OrderDetail> _advance(
    String id,
    OrderStatus to, {
    Map<String, Object> extra = const {},
  }) => _write(
    id,
    to,
    allowed: (current) => current.next == to,
    refusal: (current) =>
        'A ${current.label.toLowerCase()} order cannot be marked '
        '${to.label.toLowerCase()}.',
    extra: extra,
  );

  /// Checks and writes in one transaction, so two admins acting on the same
  /// order at once cannot both win: the second sees the first's status and
  /// is refused.
  Future<OrderDetail> _write(
    String id,
    OrderStatus to, {
    required bool Function(OrderStatus current) allowed,
    required String Function(OrderStatus current) refusal,
    Map<String, Object> extra = const {},
  }) => guardFirestore(() async {
    final reference = (await _findOrder(id)).reference;
    await _db.runTransaction((transaction) async {
      final current = Fs.statusOf(
        (await transaction.get(reference)).fields[Fs.status],
      );
      if (!allowed(current)) throw BadRequest(409, refusal(current));

      final now = FieldValue.serverTimestamp();
      transaction.update(reference, {
        Fs.status: Fs.statusValue(to),
        '${Fs.statusHistory}.${Fs.statusValue(to)}': now,
        Fs.updatedAt: now,
        ...extra,
      });
    });
    return fetchOrderDetail(id);
  });

  // ---------------------------------------------------------------- lookups
  /// By `order_id`; failing that, by document id, which is what a summary
  /// carries for an order written without one.
  Future<DocumentSnapshot<Map<String, dynamic>>> _findOrder(String id) async {
    final found = await _orders.where(Fs.orderId, isEqualTo: id).limit(1).get();
    if (found.docs.isNotEmpty) return found.docs.first;

    final byDocId = await _orders.doc(id).get();
    if (byDocId.exists) return byDocId;
    throw const NotFound();
  }

  Future<Map<String, dynamic>?> _findUser(String userId) async {
    if (userId.isEmpty) return null;
    final found = await _db
        .collection(Fs.users)
        .where(Fs.userId, isEqualTo: userId)
        .limit(1)
        .get();
    if (found.docs.isNotEmpty) return found.docs.first.data();

    // An admin's document is keyed by their sign-in uid instead.
    final byDocId = await _db.collection(Fs.users).doc(userId).get();
    return byDocId.data();
  }

  Future<Map<String, dynamic>?> _findPayment({
    required String paymentId,
    required String orderId,
  }) async {
    final payments = _db.collection(Fs.payments);
    final found =
        await (paymentId.isEmpty
                ? payments.where(Fs.orderId, isEqualTo: orderId)
                : payments.where(Fs.paymentId, isEqualTo: paymentId))
            .limit(1)
            .get();
    return found.docs.isEmpty ? null : found.docs.first.data();
  }

  /// Every user, findable by `user_id` and by document id alike.
  static Map<String, Map<String, dynamic>> usersById(List<FsDoc> docs) => {
    for (final doc in docs) doc.id: doc.data(),
    for (final doc in docs)
      if (Fs.stringOf(doc.data()[Fs.userId]).isNotEmpty)
        Fs.stringOf(doc.data()[Fs.userId]): doc.data(),
  };

  /// The number to ring, if the account has one.
  static String? phoneOf(Map<String, dynamic>? user) =>
      Fs.optionalString(user?[Fs.phone]) ?? Fs.optionalString(user?['mobile']);

  // ------------------------------------------------------------- mappings
  static Order _summaryOf(
    FsDoc doc,
    Map<String, dynamic>? user,
    Map<String, int> itemCounts,
  ) {
    final data = doc.data();
    final id = _orderIdOf(doc);
    return Order(
      id: id,
      customer: _nameOf(user, Fs.stringOf(data[Fs.userId])),
      itemCount: itemCounts[id] ?? 0,
      amountPaise: Fs.paiseOf(data[Fs.totalAmount]),
      status: Fs.statusOf(data[Fs.status]),
      phone: phoneOf(user),
      placedAt: Fs.dateOf(data[Fs.orderDate]),
    );
  }

  static String _orderIdOf(DocumentSnapshot<Map<String, dynamic>> doc) {
    final stored = Fs.stringOf(doc.fields[Fs.orderId]);
    return stored.isEmpty ? doc.id : stored;
  }

  static String _nameOf(Map<String, dynamic>? user, String userId) {
    final name = Fs.stringOf(user?[Fs.name]);
    if (name.isNotEmpty) return name;
    return userId.isEmpty ? 'Unknown customer' : userId;
  }

  /// `price` on an order item is the unit price it sold at; the line on
  /// screen is the whole line.
  static OrderLine _lineOf(
    Map<String, dynamic> item,
    Map<String, String> productNames,
  ) {
    final sku = Fs.stringOf(item[Fs.productId]);
    final quantity = Fs.intOf(item[Fs.quantity]);
    final name = productNames[sku] ?? '';
    return OrderLine(
      // A product deleted since keeps its line, under the id it sold as.
      name: name.isEmpty ? sku : name,
      sku: sku,
      quantity: quantity,
      pricePaise: Fs.paiseOf(item[Fs.price]) * quantity,
    );
  }

  static OrderDetail detailOf({
    required String id,
    required Map<String, dynamic> order,
    required Map<String, dynamic>? user,
    required List<OrderLine> lines,
    required Map<String, dynamic>? payment,
  }) {
    final status = Fs.statusOf(order[Fs.status]);
    final placedAt = Fs.dateOf(order[Fs.orderDate]);

    final reachedAt = <OrderStatus, DateTime>{OrderStatus.isNew: ?placedAt};
    final history = order[Fs.statusHistory];
    if (history is Map) {
      for (final MapEntry(:key, :value) in history.entries) {
        final at = Fs.dateOf(value);
        if (at != null) reachedAt[Fs.statusOf(key)] = at;
      }
    }
    // The current status has happened even where nothing recorded the step,
    // as with an order whose status was set from the console.
    final updatedAt = Fs.dateOf(order[Fs.updatedAt]);
    if (!reachedAt.containsKey(status) && updatedAt != null) {
      reachedAt[status] = updatedAt;
    }

    // The total is what was charged. Without the delivery and discount
    // written down, whatever separates it from the lines is one or the
    // other, so the summary still adds up to the amount paid.
    final subtotal = lines.fold(
      0,
      (running, line) => running + line.pricePaise,
    );
    final total = order.containsKey(Fs.totalAmount)
        ? Fs.paiseOf(order[Fs.totalAmount])
        : subtotal;
    final delivery = order.containsKey(Fs.deliveryCharge)
        ? Fs.paiseOf(order[Fs.deliveryCharge])
        : (total > subtotal ? total - subtotal : 0);
    final discount = order.containsKey(Fs.discount)
        ? Fs.paiseOf(order[Fs.discount])
        : (subtotal + delivery > total ? subtotal + delivery - total : 0);

    return OrderDetail(
      id: id,
      customer: _nameOf(user, Fs.stringOf(order[Fs.userId])),
      phone: phoneOf(user) ?? '',
      address:
          Fs.optionalString(order[Fs.shippingAddress]) ??
          Fs.optionalString(order[Fs.address]) ??
          Fs.stringOf(user?[Fs.address]),
      // An order with no date is still shown, timed when it was first read
      // rather than not at all.
      placedAt: placedAt ?? updatedAt ?? DateTime.now(),
      status: status,
      reachedAt: reachedAt,
      lines: lines,
      paidVia: _paidVia(payment),
      deliveryPaise: delivery,
      discountPaise: discount,
      courier: Fs.optionalString(order[Fs.courier]),
      awbNumber: Fs.optionalString(order[Fs.awbNumber]),
      cancellationReason: Fs.optionalString(order[Fs.cancellationReason]),
    );
  }

  /// The method, with the payment's status beside it unless it went
  /// through — a failed payment is the one thing the admin must not miss.
  static String _paidVia(Map<String, dynamic>? payment) {
    final method = Fs.optionalString(payment?[Fs.paymentMethod]);
    if (method == null) return 'Not recorded';
    final status = Fs.stringOf(payment?[Fs.paymentStatus]);
    final settled = const {'success', 'successful', 'paid', 'captured'};
    return status.isEmpty || settled.contains(status.toLowerCase())
        ? method
        : '$method ($status)';
  }
}
