import '../../core/errors/api_exception.dart';
import '../../mock/order_store.dart';
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

/// Serves orders from the shared in-memory store.
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
/// Holds no orders of its own: it is handed the store every other feature
/// reads from, and is the thing that decides which writes to that store are
/// allowed.
class InMemoryOrdersRepository implements OrdersRepository {
  InMemoryOrdersRepository(this._store);

  final OrderStore _store;

  @override
  Future<List<Order>> fetchOrders() async => _store.summaries;

  @override
  Future<OrderDetail> fetchOrderDetail(String id) async => _store.find(id);

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
    final current = _store.find(id).status;
    if (!current.canCancel) {
      throw BadRequest(
        409,
        'A ${current.label.toLowerCase()} order can no longer be cancelled.',
      );
    }
    return _store.write(id, OrderStatus.cancelled, cancellationReason: reason);
  }

  /// Applies the one move [OrderStatus.next] allows from where the order is,
  /// rejecting anything else.
  Future<OrderDetail> _advance(
    String id,
    OrderStatus to, {
    String? courier,
    String? awbNumber,
  }) async {
    final current = _store.find(id).status;
    if (current.next != to) {
      throw BadRequest(
        409,
        'A ${current.label.toLowerCase()} order cannot be marked '
        '${to.label.toLowerCase()}.',
      );
    }
    return _store.write(id, to, courier: courier, awbNumber: awbNumber);
  }
}
