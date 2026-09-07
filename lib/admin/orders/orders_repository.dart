import '../shared/models/order.dart';
import '../shared/models/order_status.dart';
import 'order_detail.dart';

/// Reads orders and their details.
///
/// Screens depend on this, never on a data source, so the in-memory sample
/// below can be swapped for an HTTP implementation without a screen changing.
/// Failures surface as `ApiException` from `core/network`.
abstract interface class OrdersRepository {
  /// Every order, newest first. Screens filter by status themselves.
  Future<List<Order>> fetchOrders();

  /// The full record behind one summary.
  Future<OrderDetail> fetchOrderDetail(String id);
}

/// Serves sample orders from memory.
///
/// Stands in until the backend exists. The API implementation belongs beside
/// this one and takes a `DioClient`, calling `getList('/orders')` and
/// `getObject('/orders/$id')`; nothing above this file changes when it
/// arrives.
class InMemoryOrdersRepository implements OrdersRepository {
  const InMemoryOrdersRepository();

  /// Moved here out of the screen — presentation should not carry data.
  ///
  /// Timestamps are relative to now so the "16 min ago" wording stays true
  /// however long the demo runs.
  static List<Order> _sampleOrders() {
    final now = DateTime.now();
    return [
      Order(
        id: '#SS20260726',
        customer: 'priyanshu kateshiya',
        phone: '+91 98765 43210',
        itemCount: 3,
        amountPaise: 629700,
        status: OrderStatus.isNew,
        placedAt: now.subtract(const Duration(minutes: 16)),
      ),
      Order(
        id: '#SS20260725',
        customer: 'Vivek Makvana',
        phone: '+91 90000 11111',
        itemCount: 1,
        amountPaise: 249900,
        status: OrderStatus.isNew,
        placedAt: now.subtract(const Duration(hours: 1)),
      ),
      Order(
        id: '#SS20260724',
        customer: 'Ishit vadhavana',
        phone: '+91 91234 56789',
        itemCount: 2,
        amountPaise: 519800,
        status: OrderStatus.packed,
        placedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Future<List<Order>> fetchOrders() async => _sampleOrders();

  @override
  Future<OrderDetail> fetchOrderDetail(String id) async {
    final order = _sampleOrders().firstWhere(
      (candidate) => candidate.id == id,
      orElse: () => throw StateError('No order $id'),
    );
    return _detailFor(order);
  }

  /// Builds the fuller record from a summary.
  ///
  /// The lines, address and payment breakdown are sample data — a real
  /// backend returns them with the order.
  OrderDetail _detailFor(Order order) {
    final placed = order.placedAt ?? DateTime.now();

    return OrderDetail(
      id: order.id,
      customer: 'Priyanshu Kateshiya',
      phone: order.phone ?? '',
      address: '301, Shakti Complex, Kalawad Road, Rajkot, Gujarat - 360005',
      placedAt: placed,
      status: order.status,
      paidVia: 'UPI',
      discountPaise: 50000,
      timeline: [
        OrderEvent(label: 'Order Placed', at: placed),
        OrderEvent(
          label: 'Payment Confirmed',
          at: placed.add(const Duration(minutes: 1)),
        ),
        OrderEvent(
          label: 'Packed',
          at: order.status == OrderStatus.isNew
              ? null
              : placed.add(const Duration(hours: 3, minutes: 28)),
        ),
        const OrderEvent(label: 'Shipped'),
      ],
      lines: const [
        OrderLine(
          name: 'Banarasi Silk Saree',
          sku: 'SS-1024',
          quantity: 1,
          pricePaise: 249900,
        ),
        OrderLine(
          name: 'Kanjivaram Pure Silk',
          sku: 'SS-1025',
          quantity: 1,
          pricePaise: 329900,
        ),
      ],
    );
  }
}
