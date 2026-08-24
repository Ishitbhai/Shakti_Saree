import 'package:intl/intl.dart';

/// App-wide display formatting.
///
/// Money is stored and passed around as **paise** (integer) everywhere in the
/// app — never as a double rupee value — so rounding happens once, here.
class Formatters {
  const Formatters._();

  /// Indian digit grouping: 1248 -> '1,248', 123456 -> '1,23,456'.
  static final NumberFormat _count = NumberFormat.decimalPattern('en_IN');

  /// Indian grouping with the rupee sign and no paise digits.
  static final NumberFormat _rupees = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Left unlocalised on purpose: 'd MMM yyyy' renders identically under the
  /// built-in locale, so this avoids needing `initializeDateFormatting`.
  static final DateFormat _date = DateFormat('d MMM yyyy');

  /// Whole-number counts. `1248` -> `'1,248'`.
  static String count(num value) => _count.format(value);

  /// Paise to a display price. `629700` -> `'₹6,297'`.
  ///
  /// Sub-rupee remainders are rounded to the nearest rupee, matching how the
  /// designs show prices.
  static String rupeesFromPaise(int paise) => _rupees.format(paise / 100);

  /// `26 Jul 2026`.
  static String date(DateTime value) => _date.format(value);

  /// How long ago something happened, worded the way the designs word it.
  ///
  /// Falls back to [date] past a week, because '23 days ago' reads worse than
  /// the date itself. Pass [now] to make callers testable.
  static String relativeTime(DateTime value, {DateTime? now}) {
    final elapsed = (now ?? DateTime.now()).difference(value);

    if (elapsed.inMinutes < 1) return 'just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min ago';
    if (elapsed.inHours < 24) {
      final plural = elapsed.inHours == 1 ? '' : 's';
      return '${elapsed.inHours} hour$plural ago';
    }
    if (elapsed.inDays == 1) return 'yesterday';
    if (elapsed.inDays < 7) return '${elapsed.inDays} days ago';
    return date(value);
  }

  /// `1 item` / `3 items` — the singular matters in the designs.
  static String items(int quantity) {
    final plural = quantity == 1 ? '' : 's';
    return '${count(quantity)} item$plural';
  }
}
