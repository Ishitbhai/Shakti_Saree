import '../../core/errors/api_exception.dart';
import '../../mock/mock_data.dart';
import '../shared/models/order.dart';
import '../shared/models/order_status.dart';
import 'order_detail.dart';

/// Reads orders and their details, and moves them through the fulfilment flow.
///
/// Screens depend on this, never on a data source, so the in-memory sample
/// below can be swapped for an HTTP implementation without a screen changing.
/// Failures surface as `ApiException` from `core/errors`.
///
/// Every transition returns the updated [OrderDetail] rather than just a
/// status, because that is what the caller is looking at: the detail carries
/// the timeline, the courier fields and the cancellation reason that the
/// transition itself produced. Callers that only need the summary re-read the
/// list.
///
/// Legality is [OrderStatus.next] and [OrderStatus.canCancel] — an
/// implementation must reject anything else rather than quietly applying it.
abstract interface class OrdersRepository {
  /// Every order, newest first. Screens filter by status themselves.
  Future<List<Order>> fetchOrders();

  /// The full record behind one summary.
  Future<OrderDetail> fetchOrderDetail(String id);

  /// New → Accepted.
  Future<OrderDetail> acceptOrder(String id);

  /// Accepted → Packed.
  Future<OrderDetail> markPacked(String id);

  /// Packed → Shipped.
  ///
  /// The courier details are required because they are the point of the
  /// transition — a shipped order the admin cannot track is not shipped.
  Future<OrderDetail> markShipped(
    String id, {
    required String courier,
    required String awbNumber,
  });

  /// Shipped → Delivered.
  Future<OrderDetail> markDelivered(String id);

  /// Anything before Shipped → Cancelled.
  ///
  /// The reason is required: it is the only record of why the order stopped.
  Future<OrderDetail> cancelOrder(String id, {required String reason});
}

/// Serves sample orders from memory.
///
/// Stands in until the backend exists. The API implementation belongs beside
/// this one and brings its own HTTP client — there is no longer one in the
/// project, so choosing it is part of writing that implementation.
///
/// The transition endpoint is deliberately not guessed at here — no contract
/// has been agreed for it yet, so nothing in this file encodes a field name or
/// a wire value. The five methods below are the shape the HTTP implementation
/// has to satisfy; how it spells them on the wire is still an open question.
///
/// Unlike the read-only version this replaces, this holds state: a transition
/// has to still be there when the orders list is re-read after it.
class InMemoryOrdersRepository implements OrdersRepository {
  InMemoryOrdersRepository();

  /// The sample orders, built once and then mutated in place.
  ///
  /// Held as full details rather than summaries: a transition changes the
  /// timeline, the courier fields and the reason as well as the status, and
  /// all of those live on the detail. The list screen's summaries are derived
  /// from these, so the two can never disagree.
  ///
  /// Rebuilding this per call would discard every write.
  late final List<OrderDetail> _orders = MockData.orders();

  @override
  Future<List<Order>> fetchOrders() async => List.unmodifiable([
    for (final order in _orders) MockData.summaryOf(order),
  ]);

  @override
  Future<OrderDetail> fetchOrderDetail(String id) async =>
      _orders[_indexOf(id)];

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
  }) =>
      _advance(id, OrderStatus.shipped, courier: courier, awbNumber: awbNumber);

  @override
  Future<OrderDetail> markDelivered(String id) =>
      _advance(id, OrderStatus.delivered);

  @override
  Future<OrderDetail> cancelOrder(String id, {required String reason}) async {
    final index = _indexOf(id);
    final current = _orders[index].status;
    if (!current.canCancel) {
      throw BadRequest(
        409,
        'A ${current.label.toLowerCase()} order can no longer be cancelled.',
      );
    }
    return _write(index, OrderStatus.cancelled, cancellationReason: reason);
  }

  /// Applies the one move [OrderStatus.next] allows from where the order is,
  /// rejecting anything else.
  Future<OrderDetail> _advance(
    String id,
    OrderStatus to, {
    String? courier,
    String? awbNumber,
  }) async {
    final index = _indexOf(id);
    final current = _orders[index].status;
    if (current.next != to) {
      throw BadRequest(
        409,
        'A ${current.label.toLowerCase()} order cannot be marked '
        '${to.label.toLowerCase()}.',
      );
    }
    return _write(index, to, courier: courier, awbNumber: awbNumber);
  }

  /// Commits a transition that has already been found legal.
  ///
  /// Stamps the moment the order reached [to], so the timeline grows a real
  /// step rather than one the widget invents. Anything not supplied is
  /// carried over untouched.
  OrderDetail _write(
    int index,
    OrderStatus to, {
    String? courier,
    String? awbNumber,
    String? cancellationReason,
  }) {
    final current = _orders[index];

    final updated = OrderDetail(
      id: current.id,
      customer: current.customer,
      phone: current.phone,
      address: current.address,
      placedAt: current.placedAt,
      status: to,
      reachedAt: {...current.reachedAt, to: DateTime.now()},
      lines: current.lines,
      paidVia: current.paidVia,
      deliveryPaise: current.deliveryPaise,
      discountPaise: current.discountPaise,
      courier: courier ?? current.courier,
      awbNumber: awbNumber ?? current.awbNumber,
      cancellationReason: cancellationReason ?? current.cancellationReason,
    );

    _orders[index] = updated;
    return updated;
  }

  int _indexOf(String id) {
    final index = _orders.indexWhere((candidate) => candidate.id == id);
    // Repositories are documented to surface ApiException, so an unknown id
    // reads as the 404 it would be against a real backend rather than as a
    // StateError nothing above here is prepared to catch.
    if (index == -1) throw const NotFound();
    return index;
  }
}
