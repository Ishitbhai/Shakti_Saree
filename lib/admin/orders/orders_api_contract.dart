import '../../core/errors/api_exception.dart';
import '../shared/models/order_status.dart';

/// The single place the orders wire format is written down.
///
/// PROVISIONAL — none of this has been confirmed against the backend. Every
/// path, field name and status string below is a proposal, and changing them
/// once the contract is agreed is meant to be an edit to this file and
/// nothing else.
///
/// Nothing consumes this yet: the app runs on the in-memory repository and
/// there is no HTTP implementation. It exists so that when one is written, it
/// has somewhere to read these from rather than spelling them inline.
///
/// The rule for whoever writes that implementation: no literal path, JSON key
/// or status string anywhere but here.
class OrdersApiContract {
  const OrdersApiContract._();

  // ----------------------------------------------------------------- paths
  static const String ordersPath = '/orders';

  static String orderPath(String id) => '$ordersPath/$id';

  /// Where a transition is PATCHed.
  static String orderStatusPath(String id) => '${orderPath(id)}/status';

  // ------------------------------------------------------------ field names
  static const String statusField = 'status';
  static const String courierField = 'courier';
  static const String awbNumberField = 'awb_number';
  static const String cancellationReasonField = 'cancellation_reason';

  // --------------------------------------------------------- status values
  /// Wire value per status, and the only mapping in either direction.
  ///
  /// Covers every [OrderStatus], so [toWire] can index it without a fallback;
  /// a new status added to the enum without a line here is a lookup failure
  /// rather than a silent default.
  static const Map<OrderStatus, String> statusValues = {
    OrderStatus.isNew: 'new',
    OrderStatus.accepted: 'accepted',
    OrderStatus.packed: 'packed',
    OrderStatus.shipped: 'shipped',
    OrderStatus.delivered: 'delivered',
    OrderStatus.cancelled: 'cancelled',
  };

  static String toWire(OrderStatus status) => statusValues[status]!;

  // --------------------------------------------------------------- couriers
  /// The carriers offered when shipping, in the order they are listed.
  ///
  /// The name is the value: it goes to the backend exactly as spelled here.
  /// If the contract turns out to want codes rather than names, this becomes
  /// a map alongside [statusValues] and only this file changes.
  static const List<String> couriers = [
    'Delhivery',
    'Blue Dart',
    'DTDC',
    'Ekart',
    'India Post',
    'Xpressbees',
    'Shadowfax',
  ];

  /// The dropdown entry that reveals a free-text field instead of choosing a
  /// carrier. Never sent — whatever the admin types is sent in its place.
  static const String otherCourierOption = 'Other';

  // ---------------------------------------------------------- cancellation
  /// Why an order gets cancelled, in the order they are offered.
  ///
  /// Like [couriers], the text is the value: the chosen line is sent as the
  /// cancellation reason exactly as spelled here, and 'Other' sends whatever
  /// the admin typed instead.
  static const List<String> cancellationReasons = [
    'Customer requested',
    'Out of stock',
    'Payment failed',
    'Duplicate order',
    'Address unserviceable',
  ];

  /// The reason entry that reveals a free-text field. Never sent.
  static const String otherReasonOption = 'Other';

  /// Shortest AWB number accepted.
  ///
  /// Deliberately the only check on the format. Carriers number consignments
  /// however they like — digits, letters, both, varying lengths — so anything
  /// stricter would reject numbers that are perfectly valid.
  static const int awbMinLength = 6;

  /// Reads a status back off the wire.
  ///
  /// An unrecognised value is a [MalformedResponse] rather than a guess — a
  /// status the app does not understand must not be shown as one it does.
  static OrderStatus fromWire(String raw) {
    for (final entry in statusValues.entries) {
      if (entry.value == raw) return entry.key;
    }
    throw MalformedResponse('Unknown order status "$raw".');
  }
}
