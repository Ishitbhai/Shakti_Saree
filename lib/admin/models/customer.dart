/// One person who has ordered, as the admin list shows them.
///
/// [id] is the identity: the `user_id` of their account in Firestore, or the
/// phone number for the in-memory sample, where a customer is only what the
/// orders add up to. Two people can share a name, never an id.
///
/// Money is held as paise; formatting happens at the widget.
class Customer {
  const Customer({
    String? id,
    required this.name,
    required this.phone,
    required this.orderCount,
    required this.spentPaise,
  }) : id = id ?? phone;

  final String id;
  final String name;

  /// How to reach them, as shown under the name: a phone number where there
  /// is one, otherwise the email address the account was opened with.
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
