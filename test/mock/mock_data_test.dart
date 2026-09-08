import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/orders/order_detail.dart';
import 'package:shakti_saree/admin/shared/models/order_status.dart';
import 'package:shakti_saree/mock/mock_data.dart';

/// Guards the sample data the app runs on.
///
/// None of this checks behaviour — it checks that the fixture is worth
/// trusting: that every status is represented, that the details agree with
/// the summaries built from them, and that nothing in it would look wrong on
/// screen. A screen test that passes against nonsense data has proved little.
void main() {
  late List<OrderDetail> orders;

  setUp(() => orders = MockData.orders());

  group('coverage', () {
    test('every status has at least two orders', () {
      for (final status in OrderStatus.values) {
        final matching = orders.where((order) => order.status == status);
        expect(
          matching.length,
          greaterThanOrEqualTo(2),
          reason: 'only ${matching.length} ${status.label} orders',
        );
      }
    });

    test('there are at least a dozen orders', () {
      expect(orders.length, greaterThanOrEqualTo(12));
    });

    test('order numbers are unique', () {
      final ids = orders.map((order) => order.id).toSet();
      expect(ids, hasLength(orders.length));
    });

    test('several orders carry more than one item', () {
      final multiItem = orders.where(
        (order) =>
            order.lines.length > 1 ||
            order.lines.any((line) => line.quantity > 1),
      );
      expect(multiItem.length, greaterThanOrEqualTo(4));
    });

    test('both cities are represented', () {
      for (final city in ['Rajkot', 'Ahmedabad']) {
        expect(
          orders.where((order) => order.address.contains(city)),
          isNotEmpty,
          reason: city,
        );
      }
    });
  });

  group('plausibility', () {
    test('phone numbers are valid Indian mobiles', () {
      final shape = RegExp(r'^\+91 [6-9]\d{4} \d{5}$');
      for (final order in orders) {
        expect(
          shape.hasMatch(order.phone),
          isTrue,
          reason: '${order.id}: ${order.phone}',
        );
      }
    });

    test('addresses end in a city and a PIN code', () {
      final shape = RegExp(r'(Rajkot|Ahmedabad), Gujarat - \d{6}$');
      for (final order in orders) {
        expect(
          shape.hasMatch(order.address),
          isTrue,
          reason: '${order.id}: ${order.address}',
        );
      }
    });

    test('orders were placed within the last week, and not in the future', () {
      final now = DateTime.now();
      for (final order in orders) {
        final age = now.difference(order.placedAt);
        expect(age.isNegative, isFalse, reason: '${order.id} is in the future');
        expect(
          age.inDays,
          lessThanOrEqualTo(7),
          reason: '${order.id} is stale',
        );
      }
    });

    test('every order is worth something, and the total is the lines', () {
      for (final order in orders) {
        expect(order.totalPaise, greaterThan(0), reason: order.id);
        expect(
          order.subtotalPaise,
          order.lines.fold<int>(0, (sum, line) => sum + line.pricePaise),
          reason: order.id,
        );
      }
    });

    test('every line names a product and a SKU', () {
      for (final order in orders) {
        expect(order.lines, isNotEmpty, reason: order.id);
        for (final line in order.lines) {
          expect(line.name, isNotEmpty, reason: order.id);
          expect(line.sku, startsWith('SS-'), reason: order.id);
          expect(line.quantity, greaterThan(0), reason: order.id);
          expect(line.pricePaise, greaterThan(0), reason: order.id);
        }
      }
    });
  });

  group('internal consistency', () {
    test('tracking is present on exactly the orders that have shipped', () {
      for (final order in orders) {
        final hasShipped =
            order.status == OrderStatus.shipped ||
            order.status == OrderStatus.delivered;
        expect(order.hasTracking, hasShipped, reason: order.id);
      }
    });

    test('a reason is present on exactly the cancelled orders', () {
      for (final order in orders) {
        expect(
          order.cancellationReason != null,
          order.status == OrderStatus.cancelled,
          reason: order.id,
        );
      }
    });

    test('every order has a timestamp for the status it is in', () {
      for (final order in orders) {
        expect(
          order.reachedAt.containsKey(order.status),
          isTrue,
          reason: order.id,
        );
      }
    });

    test('an order has no timestamp for a status it never reached', () {
      for (final order in orders.where(
        (order) => order.status != OrderStatus.cancelled,
      )) {
        final flow = OrderStatus.fulfilmentFlow;
        final reached = flow.sublist(0, flow.indexOf(order.status) + 1);
        expect(order.reachedAt.keys.toSet(), reached.toSet(), reason: order.id);
      }
    });

    test('timestamps only move forward', () {
      for (final order in orders) {
        final times = order.reachedAt.values.toList();
        for (var index = 1; index < times.length; index++) {
          expect(
            times[index].isAfter(times[index - 1]),
            isTrue,
            reason: '${order.id} step $index',
          );
        }
      }
    });

    test(
      'a cancelled order ends at the cancellation, with nothing pending',
      () {
        final cancelled = orders.where(
          (order) => order.status == OrderStatus.cancelled,
        );
        expect(cancelled, isNotEmpty);

        for (final order in cancelled) {
          expect(
            order.timeline.every((event) => event.isDone),
            isTrue,
            reason: '${order.id} has a pending step after being cancelled',
          );
          expect(order.timeline.last.isCancellation, isTrue, reason: order.id);
          expect(
            order.timeline.last.detail,
            order.cancellationReason,
            reason: order.id,
          );
        }
      },
    );

    test('a shipped order shows its courier on the timeline', () {
      final shipped = orders.where(
        (order) => order.status == OrderStatus.shipped,
      );
      expect(shipped, isNotEmpty);

      for (final order in shipped) {
        final step = order.timeline.firstWhere(
          (event) => event.status == OrderStatus.shipped,
        );
        expect(step.detail, contains(order.courier!), reason: order.id);
        expect(step.detail, contains(order.awbNumber!), reason: order.id);
      }
    });
  });

  group('summaries', () {
    test('there is one per order, in the same order', () {
      final summaries = MockData.summaries();
      expect(summaries.map((summary) => summary.id), orders.map((o) => o.id));
    });

    test('each agrees with the order behind it', () {
      final details = MockData.orders();
      final summaries = [
        for (final detail in details) MockData.summaryOf(detail),
      ];

      for (var index = 0; index < details.length; index++) {
        final detail = details[index];
        final summary = summaries[index];

        expect(summary.amountPaise, detail.totalPaise, reason: detail.id);
        expect(
          summary.itemCount,
          detail.lines.fold<int>(0, (sum, line) => sum + line.quantity),
          reason: detail.id,
        );
        expect(summary.status, detail.status, reason: detail.id);
        expect(summary.customer, detail.customer, reason: detail.id);
        expect(summary.phone, detail.phone, reason: detail.id);
        expect(summary.placedAt, detail.placedAt, reason: detail.id);
      }
    });
  });
}
