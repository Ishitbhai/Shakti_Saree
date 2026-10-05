import '../admin/categories/category.dart';
import '../admin/more/admin_profile.dart';
import '../admin/orders/order_detail.dart';
import '../admin/products/product.dart';
import '../admin/shared/models/order.dart';
import '../admin/shared/models/order_status.dart';
import '../admin/support/faq.dart';
import '../core/constants/app_assets.dart';

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

  /// Who is signed in.
  ///
  /// One fixed record: there is no sign-in, so there is nobody else it could
  /// be.
  ///
  /// Not const: a [DateTime] has no const constructor.
  static AdminProfile admin() => AdminProfile(
    name: 'Priyanshu Kateshiya',
    email: 'k@example.com',
    role: 'Super Admin',
    mobile: '+91 98765 43210',
    dateOfBirth: DateTime(2002, 8, 12),
    gender: Gender.male,
  );

  /// The sample product catalogue.
  ///
  /// Twenty-five listings, covering every SKU the sample orders mention, so
  /// no order line points at a product that is not in the catalogue and the
  /// price on a line always matches the price on its listing.
  ///
  /// Each carries a bundled picture and its own tint. The tint is not
  /// redundant: it is what the frame falls back to if the file is missing,
  /// and what a listing created in the app wears until it has a picture of
  /// its own.
  ///
  /// Stock is spread on purpose — three listings sit at zero and five more
  /// sit at or under the low-stock threshold — so the inventory screen has
  /// something in every state.
  static List<Product> products() => const [
    Product(
      name: 'Banarasi Silk Saree',
      sku: 'SS-1024',
      pricePaise: 249900,
      stock: 24,
      swatchIndex: 0,
      category: 'Banarasi',
      image: AppAssets.banarasiSilkSaree,
    ),
    Product(
      name: 'Kanjivaram Pure Silk',
      sku: 'SS-1025',
      pricePaise: 329900,
      stock: 12,
      swatchIndex: 1,
      category: 'Kanjivaram',
      image: AppAssets.kanjivaramPureSilk,
    ),
    Product(
      name: 'Cotton Daily Saree',
      sku: 'SS-1026',
      pricePaise: 169900,
      stock: 4,
      swatchIndex: 2,
      category: 'Cotton Saree',
      image: AppAssets.cottonDailySaree,
    ),
    Product(
      name: 'Georgette Party Wear',
      sku: 'SS-1027',
      pricePaise: 189900,
      stock: 0,
      swatchIndex: 3,
      category: 'Georgette',
      image: AppAssets.georgettePartyWear,
    ),
    // Named for its border rather than just "Paithani Silk Saree": SS-1063
    // further down already carries that name, and two listings answering to
    // one name is a trap for anyone reading an order.
    Product(
      name: 'Paithani Muniya Border Silk',
      sku: 'SS-1028',
      pricePaise: 415000,
      stock: 8,
      swatchIndex: 4,
      category: 'Paithani',
      image: AppAssets.paithaniMuniyaBorder,
    ),
    Product(
      name: 'Mysore Crepe Silk',
      sku: 'SS-1029',
      pricePaise: 279900,
      stock: 15,
      swatchIndex: 0,
      category: 'Silk Saree',
      image: AppAssets.mysoreCrepeSilk,
    ),
    Product(
      name: 'Bridal Kanjivaram Red',
      sku: 'SS-1030',
      pricePaise: 1249900,
      stock: 3,
      swatchIndex: 1,
      category: 'Bridal Wear',
      image: AppAssets.bridalKanjivaramRed,
    ),
    Product(
      name: 'Patola Handloom Saree',
      sku: 'SS-1031',
      pricePaise: 899900,
      stock: 2,
      swatchIndex: 2,
      category: 'Patola',
      image: AppAssets.patolaHandloomSaree,
    ),
    Product(
      name: 'Bandhani Georgette Saree',
      sku: 'SS-1042',
      pricePaise: 189900,
      stock: 18,
      swatchIndex: 3,
      category: 'Georgette',
      image: AppAssets.bandhaniGeorgetteSaree,
    ),
    Product(
      name: 'Designer Net Saree',
      sku: 'SS-1045',
      pricePaise: 549900,
      stock: 26,
      swatchIndex: 4,
      category: 'Designer',
      image: AppAssets.designerNetSaree,
    ),
    Product(
      name: 'Chanderi Cotton Silk',
      sku: 'SS-1050',
      pricePaise: 215000,
      stock: 20,
      swatchIndex: 0,
      category: 'Chanderi',
      image: AppAssets.chanderiCottonSilk,
    ),
    Product(
      name: 'Linen Daily Saree',
      sku: 'SS-1055',
      pricePaise: 149900,
      stock: 32,
      swatchIndex: 1,
      category: 'Daily Wear',
      image: AppAssets.linenDailySaree,
    ),
    Product(
      name: 'Paithani Silk Saree',
      sku: 'SS-1063',
      pricePaise: 649900,
      stock: 5,
      swatchIndex: 2,
      category: 'Paithani',
      image: AppAssets.paithaniSilkSaree,
    ),
    Product(
      name: 'Tussar Silk Saree',
      sku: 'SS-1071',
      pricePaise: 375000,
      stock: 9,
      swatchIndex: 3,
      category: 'Silk Saree',
      image: AppAssets.tussarSilkSaree,
    ),
    Product(
      name: 'Banarasi Katan Silk',
      sku: 'SS-1078',
      pricePaise: 459900,
      stock: 7,
      swatchIndex: 4,
      category: 'Banarasi',
      image: AppAssets.banarasiKatanSilk,
    ),
    // Out of stock, which is why order #SS20260902 was cancelled against it.
    Product(
      name: 'Organza Embroidered Saree',
      sku: 'SS-1084',
      pricePaise: 289900,
      stock: 0,
      swatchIndex: 0,
      category: 'Organza',
      image: AppAssets.organzaEmbroideredSaree,
    ),
    Product(
      name: 'Ajrakh Print Modal Silk',
      sku: 'SS-1090',
      pricePaise: 229900,
      stock: 14,
      swatchIndex: 1,
      category: 'Designer',
      image: AppAssets.ajrakhPrintModalSilk,
    ),
    Product(
      name: 'Tissue Silk Saree',
      sku: 'SS-1096',
      pricePaise: 339900,
      stock: 11,
      swatchIndex: 2,
      category: 'Silk Saree',
      image: AppAssets.tissueSilkSaree,
    ),
    Product(
      name: 'Gadwal Cotton Silk',
      sku: 'SS-1102',
      pricePaise: 275000,
      stock: 16,
      swatchIndex: 3,
      category: 'Cotton Saree',
      image: AppAssets.gadwalCottonSilk,
    ),
    Product(
      name: 'Narayanpet Cotton',
      sku: 'SS-1108',
      pricePaise: 139900,
      stock: 28,
      swatchIndex: 4,
      category: 'Cotton Saree',
      image: AppAssets.narayanpetCotton,
    ),
    Product(
      name: 'Maheshwari Handloom',
      sku: 'SS-1115',
      pricePaise: 199900,
      stock: 22,
      swatchIndex: 0,
      category: 'Cotton Saree',
      image: AppAssets.maheshwariHandloom,
    ),
    Product(
      name: 'Kota Doria Cotton',
      sku: 'SS-1120',
      pricePaise: 129900,
      stock: 3,
      swatchIndex: 1,
      category: 'Cotton Saree',
      image: AppAssets.kotaDoriaCotton,
    ),
    Product(
      name: 'Velvet Bridal Saree',
      sku: 'SS-1127',
      pricePaise: 1549900,
      stock: 0,
      swatchIndex: 2,
      category: 'Bridal Wear',
      image: AppAssets.velvetBridalSaree,
    ),
    Product(
      name: 'Bhagalpuri Silk Saree',
      sku: 'SS-1133',
      pricePaise: 175000,
      stock: 19,
      swatchIndex: 3,
      category: 'Silk Saree',
      image: AppAssets.bhagalpuriSilkSaree,
    ),
    Product(
      name: 'Chiffon Sequin Saree',
      sku: 'SS-1141',
      pricePaise: 205000,
      stock: 13,
      swatchIndex: 4,
      category: 'Designer',
      image: AppAssets.chiffonSequinSaree,
    ),
  ];


  /// The sample categories, in the order the admin list shows them.
  ///
  /// Twelve, so the grouping screen has a real list to work with. The
  /// twenty-five seeded products are spread across all of them, from one
  /// listing in the quietest to five in Cotton Saree, so the counts the
  /// screen works out are worth reading. Two are seeded hidden.
  static List<Category> categories() => const [
    Category(
      name: 'Silk Saree',
      swatchIndex: 0,
      image: AppAssets.silkSareeCategory,
    ),
    Category(
      name: 'Banarasi',
      swatchIndex: 1,
      image: AppAssets.banarasiCategory,
    ),
    Category(
      name: 'Cotton Saree',
      swatchIndex: 2,
      image: AppAssets.cottonSareeCategory,
    ),
    Category(
      name: 'Georgette',
      swatchIndex: 3,
      image: AppAssets.georgetteCategory,
    ),
    Category(
      name: 'Kanjivaram',
      swatchIndex: 4,
      isHidden: true,
      image: AppAssets.kanjivaramCategory,
    ),
    Category(
      name: 'Bridal Wear',
      swatchIndex: 0,
      image: AppAssets.bridalWearCategory,
    ),
    Category(
      name: 'Designer',
      swatchIndex: 1,
      image: AppAssets.designerCategory,
    ),
    Category(
      name: 'Daily Wear',
      swatchIndex: 2,
      image: AppAssets.dailyWearCategory,
    ),
    Category(
      name: 'Chanderi',
      swatchIndex: 3,
      image: AppAssets.chanderiCategory,
    ),
    Category(name: 'Patola', swatchIndex: 4, image: AppAssets.patolaCategory),
    Category(
      name: 'Paithani',
      swatchIndex: 0,
      image: AppAssets.paithaniCategory,
    ),
    Category(
      name: 'Organza',
      swatchIndex: 1,
      isHidden: true,
      image: AppAssets.organzaCategory,
    ),
  ];

  /// The sample help questions, in the order the support screen lists them.
  ///
  /// Answers written the way an admin would need them: where to look, and
  /// what to tell a customer who asks.
  static List<Faq> faqs() => const [
    Faq(
      question: 'How to see status of my orders?',
      answer:
          'Go to Profile > My Orders. Every order there carries its live '
          'status and a tracking link. Tracking starts working about 24 '
          'hours after the order is placed.',
    ),
    Faq(
      question: 'Can I apply a coupon code?',
      answer:
          'Coupon codes go in at checkout, one per order. A code that has '
          'expired or does not cover the items in the basket is refused with '
          'the reason.',
    ),
    Faq(
      question: 'What is the return and refund policy?',
      answer:
          'Returns are accepted within 7 days of delivery, unworn and with '
          'the tags on. Refunds reach the original payment method within 5 '
          'to 7 working days of the parcel coming back.',
    ),
    Faq(
      question: 'How much is the delivery charge?',
      answer:
          'Delivery is ₹99 on Cash on Delivery orders and free on everything '
          'that is paid for up front.',
    ),
    Faq(
      question: 'How long can a saree be?',
      answer:
          'Sarees are 5.5 metres, or 6.3 metres where a blouse piece is '
          'included. The length is on every listing under the description.',
    ),
    Faq(
      question: 'Is Cash on Delivery available?',
      answer:
          'Yes, on orders up to ₹10,000 and to pincodes our couriers cover. '
          'Checkout says so before the order is placed if it is not on offer.',
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
