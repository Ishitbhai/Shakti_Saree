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
}
