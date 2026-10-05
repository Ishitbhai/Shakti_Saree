/// The choices the order sheets offer, and the one rule they enforce.
///
/// Local data for the UI, nothing more: these lists fill two dropdowns and
/// the number below is the only check made on an AWB. They were part of a
/// wire-format contract for a backend that does not exist, which is why they
/// now live here instead.
class OrderOptions {
  const OrderOptions._();

  // --------------------------------------------------------------- couriers
  /// The carriers offered when shipping, in the order they are listed.
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
  /// carrier. Never stored — whatever the admin types is stored in its place.
  static const String otherCourierOption = 'Other';

  // ---------------------------------------------------------- cancellation
  /// Why an order gets cancelled, in the order they are offered.
  ///
  /// Like [couriers], the text is the value: the chosen line is stored as the
  /// cancellation reason exactly as spelled here, and 'Other' stores whatever
  /// the admin typed instead.
  static const List<String> cancellationReasons = [
    'Customer requested',
    'Out of stock',
    'Payment failed',
    'Duplicate order',
    'Address unserviceable',
  ];

  /// The reason entry that reveals a free-text field. Never stored.
  static const String otherReasonOption = 'Other';

  /// Shortest AWB number accepted.
  ///
  /// Deliberately the only check on the format. Carriers number consignments
  /// however they like — digits, letters, both, varying lengths — so anything
  /// stricter would reject numbers that are perfectly valid.
  static const int awbMinLength = 6;
}
