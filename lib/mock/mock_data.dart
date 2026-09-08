import '../admin/orders/order_detail.dart';
import '../admin/products/product.dart';
import '../admin/shared/models/order.dart';
import '../admin/shared/models/order_status.dart';

/// Sample orders for running the admin app without a backend.
///
/// Fourteen orders, at least two in every status, so each filter chip has
/// something under it and the timeline can be seen at every stage.
///
/// [orders] is a function rather than a constant because the timestamps are
/// relative to now — the list is meant to read as "16 minutes ago" and
/// "yesterday" however long after writing it the app is run.
///
/// The order numbers are opaque running numbers, not dates; the date an order
/// was placed lives in `placedAt` alone.
///
/// Money is in paise throughout, matching the models. A line's `pricePaise`
/// is the total for that line, so a quantity of two carries twice the unit
/// price.
class MockData {
  const MockData._();

  /// Every sample order, newest first.
  static List<OrderDetail> orders() {
    final now = DateTime.now();

    DateTime ago(Duration duration) => now.subtract(duration);

    return [
      // ------------------------------------------------------------- new
      _order(
        id: '#SS20260914',
        customer: 'Priyanshu Kateshiya',
        phone: '+91 98250 41267',
        address:
            '12, Shreeji Residency, Kalawad Road, Rajkot, '
            'Gujarat - 360005',
        placedAt: ago(const Duration(minutes: 16)),
        status: OrderStatus.isNew,
        paidVia: 'UPI',
        discountPaise: 50000,
        lines: const [
          OrderLine(
            name: 'Banarasi Silk Saree',
            sku: 'SS-1024',
            quantity: 1,
            pricePaise: 249900,
          ),
          OrderLine(
            name: 'Chanderi Cotton Silk',
            sku: 'SS-1050',
            quantity: 1,
            pricePaise: 215000,
          ),
        ],
      ),
      _order(
        id: '#SS20260913',
        customer: 'Meera Trivedi',
        phone: '+91 94263 88104',
        address:
            '18, Shivalik Bungalows, Satellite, Ahmedabad, '
            'Gujarat - 380015',
        placedAt: ago(const Duration(hours: 1, minutes: 12)),
        status: OrderStatus.isNew,
        paidVia: 'Card',
        lines: const [
          OrderLine(
            name: 'Patola Handloom Saree',
            sku: 'SS-1031',
            quantity: 1,
            pricePaise: 899900,
          ),
        ],
      ),
      _order(
        id: '#SS20260912',
        customer: 'Jignesh Parmar',
        phone: '+91 99043 27519',
        address: '201, Silver Crest, Mavdi Chokdi, Rajkot, Gujarat - 360004',
        placedAt: ago(const Duration(hours: 3, minutes: 40)),
        status: OrderStatus.isNew,
        paidVia: 'Cash on delivery',
        deliveryPaise: 9900,
        lines: const [
          // Two of the same saree — the line price is for both.
          OrderLine(
            name: 'Kota Doria Cotton',
            sku: 'SS-1120',
            quantity: 2,
            pricePaise: 259800,
          ),
          OrderLine(
            name: 'Maheshwari Handloom',
            sku: 'SS-1115',
            quantity: 1,
            pricePaise: 199900,
          ),
        ],
      ),

      // -------------------------------------------------------- accepted
      _order(
        id: '#SS20260911',
        customer: 'Nidhi Chauhan',
        phone: '+91 97129 60438',
        address:
            'A-77, Navrangpura, Near Gujarat College, Ahmedabad, '
            'Gujarat - 380009',
        placedAt: ago(const Duration(hours: 8)),
        status: OrderStatus.accepted,
        paidVia: 'UPI',
        lines: const [
          OrderLine(
            name: 'Bandhani Georgette Saree',
            sku: 'SS-1042',
            quantity: 1,
            pricePaise: 189900,
          ),
          OrderLine(
            name: 'Organza Embroidered Saree',
            sku: 'SS-1084',
            quantity: 1,
            pricePaise: 289900,
          ),
        ],
      ),
      _order(
        id: '#SS20260910',
        customer: 'Rakesh Bhatt',
        phone: '+91 63548 21970',
        address: '44, Jagnath Plot, Dr Yagnik Road, Rajkot, Gujarat - 360001',
        placedAt: ago(const Duration(hours: 20)),
        status: OrderStatus.accepted,
        paidVia: 'Netbanking',
        lines: const [
          OrderLine(
            name: 'Kanjivaram Pure Silk',
            sku: 'SS-1025',
            quantity: 1,
            pricePaise: 329900,
          ),
        ],
      ),

      // ---------------------------------------------------------- packed
      _order(
        id: '#SS20260909',
        customer: 'Hetal Sompura',
        phone: '+91 78748 33062',
        address:
            '1102, Venus Stratum, Prahladnagar, Ahmedabad, '
            'Gujarat - 380015',
        placedAt: ago(const Duration(days: 1, hours: 2)),
        status: OrderStatus.packed,
        paidVia: 'UPI',
        discountPaise: 75000,
        lines: const [
          OrderLine(
            name: 'Paithani Silk Saree',
            sku: 'SS-1063',
            quantity: 1,
            pricePaise: 649900,
          ),
          OrderLine(
            name: 'Tussar Silk Saree',
            sku: 'SS-1071',
            quantity: 1,
            pricePaise: 375000,
          ),
          OrderLine(
            name: 'Chiffon Sequin Saree',
            sku: 'SS-1141',
            quantity: 1,
            pricePaise: 205000,
          ),
        ],
      ),
      _order(
        id: '#SS20260908',
        customer: 'Darshan Kansara',
        phone: '+91 90993 45182',
        address: '7, Sardar Nagar Main Road, Rajkot, Gujarat - 360001',
        placedAt: ago(const Duration(days: 1, hours: 6)),
        status: OrderStatus.packed,
        paidVia: 'Card',
        lines: const [
          OrderLine(
            name: 'Ajrakh Print Modal Silk',
            sku: 'SS-1090',
            quantity: 2,
            pricePaise: 459800,
          ),
        ],
      ),

      // --------------------------------------------------------- shipped
      _order(
        id: '#SS20260907',
        customer: 'Falguni Desai',
        phone: '+91 82384 09176',
        address:
            '63, Bodakdev, Judges Bungalow Road, Ahmedabad, '
            'Gujarat - 380054',
        placedAt: ago(const Duration(days: 2)),
        status: OrderStatus.shipped,
        paidVia: 'UPI',
        courier: 'Delhivery',
        awbNumber: '1478529630',
        lines: const [
          OrderLine(
            name: 'Gadwal Cotton Silk',
            sku: 'SS-1102',
            quantity: 1,
            pricePaise: 275000,
          ),
          OrderLine(
            name: 'Bhagalpuri Silk Saree',
            sku: 'SS-1133',
            quantity: 1,
            pricePaise: 175000,
          ),
        ],
      ),
      _order(
        id: '#SS20260906',
        customer: 'Ronak Zalavadiya',
        phone: '+91 70690 51423',
        address:
            '9, Raiya Road, Nirmala Convent Road, Rajkot, '
            'Gujarat - 360007',
        placedAt: ago(const Duration(days: 2, hours: 10)),
        status: OrderStatus.shipped,
        paidVia: 'Cash on delivery',
        deliveryPaise: 9900,
        courier: 'Blue Dart',
        awbNumber: '78412596304',
        lines: const [
          OrderLine(
            name: 'Chanderi Cotton Silk',
            sku: 'SS-1050',
            quantity: 1,
            pricePaise: 215000,
          ),
        ],
      ),

      // ------------------------------------------------------- delivered
      _order(
        id: '#SS20260905',
        customer: 'Shreya Nanavati',
        phone: '+91 88667 24095',
        address: '26, Maninagar East, Ahmedabad, Gujarat - 380008',
        placedAt: ago(const Duration(days: 3, hours: 5)),
        status: OrderStatus.delivered,
        paidVia: 'UPI',
        courier: 'DTDC',
        awbNumber: '6032914785',
        lines: const [
          OrderLine(
            name: 'Banarasi Silk Saree',
            sku: 'SS-1024',
            quantity: 1,
            pricePaise: 249900,
          ),
          OrderLine(
            name: 'Kota Doria Cotton',
            sku: 'SS-1120',
            quantity: 1,
            pricePaise: 129900,
          ),
        ],
      ),
      _order(
        id: '#SS20260904',
        customer: 'Ketan Dholakia',
        phone: '+91 93131 78240',
        address: 'C-12, Shastri Nagar, Gondal Road, Rajkot, Gujarat - 360004',
        placedAt: ago(const Duration(days: 4, hours: 3)),
        status: OrderStatus.delivered,
        paidVia: 'Card',
        courier: 'Ekart',
        awbNumber: 'EK9204718356',
        lines: const [
          OrderLine(
            name: 'Kanjivaram Pure Silk',
            sku: 'SS-1025',
            quantity: 1,
            pricePaise: 329900,
          ),
        ],
      ),
      _order(
        id: '#SS20260903',
        customer: 'Anjali Rathod',
        phone: '+91 76008 41539',
        address:
            '302, Iscon Platinum, S G Highway, Ahmedabad, '
            'Gujarat - 380054',
        placedAt: ago(const Duration(days: 5, hours: 7)),
        status: OrderStatus.delivered,
        paidVia: 'Netbanking',
        discountPaise: 30000,
        courier: 'Xpressbees',
        awbNumber: 'XB5471028936',
        lines: const [
          OrderLine(
            name: 'Maheshwari Handloom',
            sku: 'SS-1115',
            quantity: 2,
            pricePaise: 399800,
          ),
          OrderLine(
            name: 'Chiffon Sequin Saree',
            sku: 'SS-1141',
            quantity: 1,
            pricePaise: 205000,
          ),
        ],
      ),

      // ------------------------------------------------------- cancelled
      _order(
        id: '#SS20260902',
        customer: 'Vivek Makvana',
        phone: '+91 99786 12604',
        address:
            'B-304, Amber Heights, University Road, Rajkot, '
            'Gujarat - 360005',
        placedAt: ago(const Duration(days: 2, hours: 4)),
        status: OrderStatus.cancelled,
        // Got as far as being accepted before the shelf was found empty.
        reachedBeforeCancelling: OrderStatus.accepted,
        cancellationReason: 'Out of stock',
        paidVia: 'UPI',
        lines: const [
          OrderLine(
            name: 'Organza Embroidered Saree',
            sku: 'SS-1084',
            quantity: 1,
            pricePaise: 289900,
          ),
        ],
      ),
      _order(
        id: '#SS20260901',
        customer: 'Ishit Vadhavana',
        phone: '+91 84605 39718',
        address:
            '504, Satyamev Eminence, Science City Road, Ahmedabad, '
            'Gujarat - 380060',
        placedAt: ago(const Duration(days: 4, hours: 8)),
        status: OrderStatus.cancelled,
        // Already packed when the customer rang to call it off.
        reachedBeforeCancelling: OrderStatus.packed,
        cancellationReason: 'Customer requested',
        paidVia: 'Cash on delivery',
        deliveryPaise: 9900,
        lines: const [
          OrderLine(
            name: 'Patola Handloom Saree',
            sku: 'SS-1031',
            quantity: 1,
            pricePaise: 899900,
          ),
          OrderLine(
            name: 'Tussar Silk Saree',
            sku: 'SS-1071',
            quantity: 1,
            pricePaise: 375000,
          ),
        ],
      ),
    ];
  }

  /// The sample product catalogue.
  ///
  /// Each carries its own placeholder tint, so a product keeps its colour
  /// wherever it appears and whatever order the list is in.
  static List<Product> products() => const [
    Product(
      name: 'Banarasi Silk Saree',
      sku: 'SS-1024',
      pricePaise: 249900,
      stock: 24,
      swatchIndex: 0,
    ),
    Product(
      name: 'Kanjivaram Pure Silk',
      sku: 'SS-1025',
      pricePaise: 329900,
      stock: 12,
      swatchIndex: 1,
    ),
    Product(
      name: 'Cotton Daily Saree',
      sku: 'SS-1026',
      pricePaise: 169900,
      stock: 4,
      swatchIndex: 2,
    ),
    Product(
      name: 'Georgette Party Wear',
      sku: 'SS-1027',
      pricePaise: 189900,
      stock: 0,
      swatchIndex: 3,
    ),
    Product(
      name: 'Paithani Silk Saree',
      sku: 'SS-1028',
      pricePaise: 415000,
      stock: 8,
      swatchIndex: 4,
    ),
  ];

  /// The same orders as list summaries.
  static List<Order> summaries() => [
    for (final detail in orders()) summaryOf(detail),
  ];

  /// The summary the list screen shows for one order.
  ///
  /// The count and the amount are read off the lines rather than stored
  /// separately, so a summary can never disagree with the order behind it.
  static Order summaryOf(OrderDetail detail) => Order(
    id: detail.id,
    customer: detail.customer,
    itemCount: detail.lines.fold(0, (sum, line) => sum + line.quantity),
    amountPaise: detail.totalPaise,
    status: detail.status,
    phone: detail.phone,
    placedAt: detail.placedAt,
  );

  /// Builds one order, giving it a history consistent with where it ended up.
  static OrderDetail _order({
    required String id,
    required String customer,
    required String phone,
    required String address,
    required DateTime placedAt,
    required OrderStatus status,
    required String paidVia,
    required List<OrderLine> lines,
    int deliveryPaise = 0,
    int discountPaise = 0,
    String? courier,
    String? awbNumber,
    String? cancellationReason,
    OrderStatus? reachedBeforeCancelling,
  }) {
    return OrderDetail(
      id: id,
      customer: customer,
      phone: phone,
      address: address,
      placedAt: placedAt,
      status: status,
      paidVia: paidVia,
      deliveryPaise: deliveryPaise,
      discountPaise: discountPaise,
      courier: courier,
      awbNumber: awbNumber,
      cancellationReason: cancellationReason,
      reachedAt: _history(
        placedAt,
        reached: reachedBeforeCancelling ?? status,
        thenCancelled: status == OrderStatus.cancelled,
      ),
      lines: lines,
    );
  }

  /// Timestamps for an order that walked the flow as far as [reached],
  /// optionally stopping at a cancellation after that.
  ///
  /// Stages are spaced evenly, which is enough for sample data — what matters
  /// is that a status the order reached has a time and one it never reached
  /// has none, because that is what draws the timeline.
  static Map<OrderStatus, DateTime> _history(
    DateTime placedAt, {
    required OrderStatus reached,
    bool thenCancelled = false,
    Duration step = const Duration(hours: 5),
  }) {
    final stamps = <OrderStatus, DateTime>{};
    var elapsed = Duration.zero;

    for (final stage in OrderStatus.fulfilmentFlow) {
      stamps[stage] = placedAt.add(elapsed);
      if (stage == reached) break;
      elapsed += step;
    }

    if (thenCancelled) {
      stamps[OrderStatus.cancelled] = placedAt.add(elapsed + step);
    }
    return stamps;
  }
}
