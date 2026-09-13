/// One person who has ordered, as the admin list shows them.
///
/// Not a record the app stores: there is no customer table, only orders, so a
/// customer is what the orders add up to. The phone number is the identity —
/// two people can share a name, but an order carries the number it was placed
/// against.
///
/// Money is held as paise; formatting happens at the widget.
class Customer {
  const Customer({
    required this.name,
    required this.phone,
    required this.orderCount,
    required this.spentPaise,
  });

  final String name;
  final String phone;

  /// Every order they have placed, cancellations included — they still
  /// ordered.
  final int orderCount;

  /// What they have actually spent, which is not the same thing: a cancelled
  /// order is not money taken.
  final int spentPaise;

  /// Up to two letters for the avatar, from the first words of the name.
  ///
  /// Falls back to the first letter alone for a single-word name, and to a
  /// dash for an empty one, so the circle is never blank.
  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    if (words.isEmpty) return '-';
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}
