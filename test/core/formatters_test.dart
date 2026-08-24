import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/core/utils/formatters.dart';

void main() {
  group('rupeesFromPaise', () {
    test('formats paise as whole rupees', () {
      expect(Formatters.rupeesFromPaise(629700), '₹6,297');
    });

    test('uses Indian lakh grouping past five digits', () {
      expect(Formatters.rupeesFromPaise(123456700), '₹12,34,567');
    });

    test('handles zero', () {
      expect(Formatters.rupeesFromPaise(0), '₹0');
    });

    test('rounds sub-rupee remainders', () {
      expect(Formatters.rupeesFromPaise(629750), '₹6,298');
    });
  });

  group('count', () {
    test('groups thousands', () {
      expect(Formatters.count(1248), '1,248');
      expect(Formatters.count(2150), '2,150');
    });

    test('groups lakhs the Indian way', () {
      expect(Formatters.count(123456), '1,23,456');
    });

    test('leaves small numbers ungrouped', () {
      expect(Formatters.count(320), '320');
    });
  });

  group('date', () {
    test('renders as d MMM yyyy', () {
      expect(Formatters.date(DateTime(2026, 7, 26)), '26 Jul 2026');
    });

    test('does not zero-pad the day', () {
      expect(Formatters.date(DateTime(2026, 1, 5)), '5 Jan 2026');
    });
  });

  group('relativeTime', () {
    final now = DateTime(2026, 8, 18, 12);

    test('under a minute', () {
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(seconds: 30)),
          now: now,
        ),
        'just now',
      );
    });

    test('minutes', () {
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(minutes: 16)),
          now: now,
        ),
        '16 min ago',
      );
    });

    test('one hour is singular', () {
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(hours: 1)),
          now: now,
        ),
        '1 hour ago',
      );
    });

    test('several hours are plural', () {
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(hours: 5)),
          now: now,
        ),
        '5 hours ago',
      );
    });

    test('yesterday', () {
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(days: 1)),
          now: now,
        ),
        'yesterday',
      );
    });

    test('falls back to the date past a week', () {
      expect(
        Formatters.relativeTime(DateTime(2026, 7, 26), now: now),
        '26 Jul 2026',
      );
    });
  });

  group('items', () {
    test('one item is singular', () {
      expect(Formatters.items(1), '1 item');
    });

    test('other counts are plural', () {
      expect(Formatters.items(3), '3 items');
      expect(Formatters.items(0), '0 items');
    });

    test('groups large counts', () {
      expect(Formatters.items(1248), '1,248 items');
    });
  });
}
