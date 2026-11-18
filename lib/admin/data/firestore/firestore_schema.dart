import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/order_status.dart';
import '../api_exception.dart';

/// The names the `shakti-saree` Firestore database actually uses.
///
/// Read off the live documents rather than chosen here: every collection
/// carries its own business id (`product_id`, `order_id`, …) as a field next
/// to an auto-generated document id, and documents refer to one another by
/// those fields, never by document id. Money is in rupees, as a double.
///
/// The few fields marked *added by the admin panel* did not exist before the
/// panel needed somewhere to keep them. They are only ever written alongside
/// the original fields, never instead of them, and every read tolerates their
/// absence.
class Fs {
  const Fs._();

  // ------------------------------------------------------------ collections
  static const String users = 'users';
  static const String products = 'products';
  static const String categories = 'categories';
  static const String orders = 'orders';
  static const String orderItems = 'order_items';
  static const String carts = 'carts';
  static const String cartItems = 'cart_items';
  static const String payments = 'payments';
  static const String support = 'support';

  // ------------------------------------------------------------------ users
  static const String userId = 'user_id';
  static const String name = 'name';
  static const String email = 'email';
  static const String address = 'address';
  static const String userType = 'user_type';
  static const String registeredAt = 'registered_at';

  /// Added by the admin panel's profile form, as are the two below.
  static const String phone = 'phone';
  static const String dateOfBirth = 'date_of_birth';
  static const String gender = 'gender';

  /// What `user_type` holds for someone allowed into the admin panel.
  static const String adminType = 'admin';

  /// What `user_type` holds for everyone else. The security rules insist on
  /// it for an account that registers itself.
  static const String customerType = 'customer';

  /// What a `users` document's `status` holds for an account in good standing.
  static const String activeStatus = 'active';

  // --------------------------------------------------------------- products
  static const String productId = 'product_id';
  static const String productName = 'product_name';
  static const String description = 'description';
  static const String price = 'price';
  static const String stockQuantity = 'stock_quantity';
  /// The picture. On products and categories, the path of one of the app's
  /// own pictures, chosen in the admin from `assets/images/`; one saved before
  /// that may hold a photo kept in the document as a `data:` URL (see
  /// `EmbeddedPhoto`). On an admin's own `users` document, their profile
  /// photo as a `data:` URL. Blank reads as no picture.
  static const String image = 'image';

  /// Added by the admin panel: the placeholder tint, on products and
  /// categories alike.
  static const String swatchIndex = 'swatch_index';

  // ------------------------------------------------------------- categories
  static const String categoryId = 'category_id';
  static const String categoryName = 'category_name';
  static const String createdAt = 'created_at';

  /// Added by the admin panel's hide toggle.
  static const String isHidden = 'is_hidden';

  // ----------------------------------------------------------------- orders
  static const String orderId = 'order_id';
  static const String orderDate = 'order_date';

  /// Where an order has got to. The customer app writes 'Pending' here at
  /// checkout, and the admin panel moves it on from there.
  static const String orderStatus = 'order_status';

  /// What the panel used to keep [orderStatus] in, still on older orders.
  /// Never written now, and read only through [orderStatusOf].
  static const String status = 'status';
  static const String totalAmount = 'total_amount';
  static const String paymentId = 'payment_id';

  /// Added by the admin panel's fulfilment flow, as are the four below:
  /// a map of status value → when the order reached it.
  static const String statusHistory = 'status_history';
  static const String updatedAt = 'updated_at';
  static const String courier = 'courier';
  static const String awbNumber = 'awb_number';
  static const String cancellationReason = 'cancellation_reason';

  /// Read when present; nothing in the database carries them yet.
  static const String shippingAddress = 'shipping_address';
  static const String deliveryCharge = 'delivery_charge';
  static const String discount = 'discount';

  /// Written by the customer app at checkout: a map holding who the order is
  /// going to, under [recipientName] and [phone].
  static const String deliveryAddress = 'delivery_address';
  static const String recipientName = 'recipient_name';

  // ------------------------------------------------------------ order items
  static const String quantity = 'quantity';

  // ------------------------------------------------------------------ carts
  static const String cartId = 'cart_id';
  static const String cartItemId = 'cart_item_id';

  // --------------------------------------------------------------- payments
  static const String paymentMethod = 'payment_method';
  static const String paymentStatus = 'payment_status';

  /// What `payment_status` reads on an order once it has been paid for.
  static const String paidOnOrder = 'Paid';

  /// The same, on the order's document in `payments`. The customer app spells
  /// the two differently, and these are its words.
  static const String paidOnPayment = 'Success';

  // ---------------------------------------------------------------- support
  static const String supportId = 'support_id';

  /// On a customer's query, what it is about. On a question the admin answers
  /// on the Help & Support screen, the question.
  static const String subject = 'subject';

  /// On a customer's query, what they wrote. On the admin's, the answer.
  static const String message = 'message';

  // -------------------------------------------------------- order statuses
  /// The status of the order holding [fields].
  ///
  /// `order_status` decides, whatever an older `status` beside it says. That
  /// one counts only on an order with no `order_status` at all.
  static OrderStatus orderStatusOf(Map<String, dynamic> fields) =>
      statusOf(optionalString(fields[orderStatus]) ?? fields[status]);

  /// The status as the app reads it.
  ///
  /// Lenient, because the customer app and the console both write this
  /// field: the seed order says 'Pending', and the obvious synonyms are
  /// accepted rather than dropping an order into the wrong tab.
  static OrderStatus statusOf(Object? raw) =>
      switch ('${raw ?? ''}'.trim().toLowerCase()) {
        'accepted' || 'confirmed' || 'processing' => OrderStatus.accepted,
        'packed' => OrderStatus.packed,
        'shipped' || 'dispatched' || 'in transit' => OrderStatus.shipped,
        'delivered' || 'completed' => OrderStatus.delivered,
        'cancelled' || 'canceled' => OrderStatus.cancelled,
        // 'pending', 'new', 'placed', and anything not recognised: an order
        // nobody has acted on yet is the safe reading of an unknown word.
        _ => OrderStatus.isNew,
      };

  /// The status as it is written back.
  ///
  /// New is spelled 'Pending', which is what the database already uses for
  /// it; everything else is the label the panel shows.
  static String statusValue(OrderStatus status) =>
      status == OrderStatus.isNew ? 'Pending' : status.label;

  // ---------------------------------------------------------------- support
  /// Whether a `support` document is a query from a customer, who is named on
  /// it. Without a `user_id` it is a question the admin answered.
  static bool isCustomerQuery(Map<String, dynamic> fields) =>
      stringOf(fields[userId]).isNotEmpty;

  // ---------------------------------------------------------- payment words
  /// Whether [method] is cash handed over at the door, however it is spelled.
  static bool isCashOnDelivery(Object? method) =>
      switch (stringOf(method).toLowerCase().replaceAll(RegExp('[^a-z]'), '')) {
        'cod' || 'cashondelivery' => true,
        _ => false,
      };

  /// Whether [status] says the money is still to come.
  static bool isPendingPayment(Object? status) =>
      stringOf(status).toLowerCase() == 'pending';

  // ------------------------------------------------------------ conversions
  /// Rupees as stored, in paise as the models hold them.
  static int paiseOf(Object? rupees) {
    final value = rupees is num ? rupees : num.tryParse('${rupees ?? ''}');
    return value == null ? 0 : (value * 100).round();
  }

  /// Paise back to rupees, as the double the database stores.
  static double rupeesOf(int paise) => paise / 100;

  static int intOf(Object? value) =>
      value is num ? value.toInt() : int.tryParse('${value ?? ''}'.trim()) ?? 0;

  static String stringOf(Object? value) => value == null ? '' : '$value'.trim();

  /// Null for blank, so an empty image field reads as "no picture".
  static String? optionalString(Object? value) {
    final text = stringOf(value);
    return text.isEmpty ? null : text;
  }

  static DateTime? dateOf(Object? value) => switch (value) {
    Timestamp() => value.toDate(),
    DateTime() => value,
    String() => DateTime.tryParse(value),
    _ => null,
  };

  /// A tint for a record that never had one chosen, steady across runs.
  ///
  /// Summed rather than `hashCode`, which Dart does not promise is stable from
  /// one run to the next — a listing would otherwise change colour on every
  /// launch.
  static int swatchFor(Object? stored, String seed, int paletteSize) {
    if (stored is num) return stored.toInt();
    return seed.codeUnits.fold(0, (total, unit) => total + unit) % paletteSize;
  }

  /// The next id in a `PREFIX_001` sequence.
  ///
  /// Ids that do not follow the pattern are skipped rather than parsed, and
  /// the result is never one already in [taken].
  static String nextId(String prefix, Iterable<String> taken) {
    final pattern = RegExp('^${RegExp.escape(prefix)}_(\\d+)\$');
    var highest = 0;
    for (final id in taken) {
      final match = pattern.firstMatch(id);
      final number = match == null ? null : int.tryParse(match.group(1)!);
      if (number != null && number > highest) highest = number;
    }
    return '${prefix}_${'${highest + 1}'.padLeft(3, '0')}';
  }
}

/// Runs a Firestore call and turns its failures into [ApiException]s, which
/// is the only kind of failure the screens know how to word.
Future<T> guardFirestore<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on ApiException {
    rethrow;
  } on FirebaseException catch (error) {
    throw apiExceptionFor(error);
  }
}

ApiException apiExceptionFor(FirebaseException error) => switch (error.code) {
  'unavailable' => const NetworkUnavailable(),
  'deadline-exceeded' => const RequestTimeout(),
  'not-found' => const NotFound(),
  'permission-denied' || 'unauthenticated' => const BadRequest(
    403,
    'You do not have permission to do that. Sign in with an admin account.',
  ),
  'already-exists' => const BadRequest(409, 'That record already exists.'),
  'invalid-argument' || 'failed-precondition' || 'out-of-range' => BadRequest(
    400,
    error.message ?? 'That request could not be completed.',
  ),
  'resource-exhausted' => const ServerError(
    429,
    'Too many requests right now. Please wait a moment and retry.',
  ),
  'internal' || 'data-loss' => const ServerError(500),
  _ => const UnknownApiException(),
};

extension FsDocument on DocumentSnapshot<Map<String, dynamic>> {
  /// The fields, or nothing for a document that is not there.
  Map<String, dynamic> get fields => data() ?? const {};
}
