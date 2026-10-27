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

  // --------------------------------------------------------------- products
  static const String productId = 'product_id';
  static const String productName = 'product_name';
  static const String description = 'description';
  static const String price = 'price';
  static const String stockQuantity = 'stock_quantity';
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

  // ------------------------------------------------------------ order items
  static const String quantity = 'quantity';

  // --------------------------------------------------------------- payments
  static const String paymentMethod = 'payment_method';
  static const String paymentStatus = 'payment_status';

  // ---------------------------------------------------------------- support
  static const String supportId = 'support_id';
  static const String subject = 'subject';
  static const String message = 'message';

  // -------------------------------------------------------- order statuses
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
