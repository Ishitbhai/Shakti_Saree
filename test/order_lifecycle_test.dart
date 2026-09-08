import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shakti_saree/admin/orders/order_detail.dart';
import 'package:shakti_saree/admin/orders/order_detail_screen.dart';
import 'package:shakti_saree/admin/orders/orders_providers.dart';
import 'package:shakti_saree/admin/orders/orders_repository.dart';
import 'package:shakti_saree/admin/orders/orders_screen.dart';
import 'package:shakti_saree/admin/orders/widgets/order_card.dart';
import 'package:shakti_saree/admin/orders/widgets/order_timeline.dart';
import 'package:shakti_saree/admin/shared/admin_tab.dart';
import 'package:shakti_saree/admin/shared/models/order.dart';
import 'package:shakti_saree/admin/shared/models/order_status.dart';
import 'package:shakti_saree/admin/shared/widgets/status_pill.dart';
import 'package:shakti_saree/core/errors/api_exception.dart';
import 'package:shakti_saree/core/theme/app_theme.dart';

/// Answers nothing. Subclasses override only the transition under test, so a
/// test that hits any other one fails loudly instead of quietly passing.
class _StubOrders implements OrdersRepository {
  @override
  Future<List<Order>> fetchOrders() async => const [];

  @override
  Future<OrderDetail> fetchOrderDetail(String id) async =>
      throw const NotFound();

  @override
  Future<OrderDetail> acceptOrder(String id) => throw UnimplementedError();

  @override
  Future<OrderDetail> markPacked(String id) => throw UnimplementedError();

  @override
  Future<OrderDetail> markShipped(
    String id, {
    required String courier,
    required String awbNumber,
  }) => throw UnimplementedError();

  @override
  Future<OrderDetail> markDelivered(String id) => throw UnimplementedError();

  @override
  Future<OrderDetail> cancelOrder(String id, {required String reason}) =>
      throw UnimplementedError();
}

/// Accept hangs until the test releases it, so the in-flight bar can be read.
class _HangingAccept extends _StubOrders {
  final completer = Completer<OrderDetail>();

  @override
  Future<OrderDetail> acceptOrder(String id) => completer.future;
}

class _FailingAccept extends _StubOrders {
  @override
  Future<OrderDetail> acceptOrder(String id) async =>
      throw const RequestTimeout();
}

/// Records what the ship sheet actually sent.
class _RecordingShip extends _StubOrders {
  String? courier;
  String? awbNumber;

  @override
  Future<OrderDetail> markShipped(
    String id, {
    required String courier,
    required String awbNumber,
  }) async {
    this.courier = courier;
    this.awbNumber = awbNumber;
    return _detailAt(OrderStatus.shipped);
  }
}

/// Shipping hangs until released, so the locked sheet can be inspected.
class _HangingShip extends _StubOrders {
  final completer = Completer<OrderDetail>();

  @override
  Future<OrderDetail> markShipped(
    String id, {
    required String courier,
    required String awbNumber,
  }) => completer.future;
}

/// Records the reason the cancel sheet actually sent.
class _RecordingCancel extends _StubOrders {
  String? reason;
  var calls = 0;

  @override
  Future<OrderDetail> cancelOrder(String id, {required String reason}) async {
    this.reason = reason;
    calls++;
    return _detailAt(OrderStatus.cancelled);
  }
}

class _FailingCancel extends _StubOrders {
  @override
  Future<OrderDetail> cancelOrder(String id, {required String reason}) async =>
      throw const NetworkUnavailable();
}

class _FailingShip extends _StubOrders {
  @override
  Future<OrderDetail> markShipped(
    String id, {
    required String courier,
    required String awbNumber,
  }) async => throw const ServerError(500);
}

/// Throws something that is not an [ApiException] — a bug rather than a
/// failure the repository was designed to report.
class _BuggyOrders extends _StubOrders {
  @override
  Future<OrderDetail> acceptOrder(String id) async => throw StateError('boom');

  @override
  Future<OrderDetail> markShipped(
    String id, {
    required String courier,
    required String awbNumber,
  }) async => throw StateError('boom');

  @override
  Future<OrderDetail> cancelOrder(String id, {required String reason}) async =>
      throw StateError('boom');
}

final _placedAt = DateTime(2026, 1, 1, 10);

/// The statuses an order at [status] must have been through to get there.
List<OrderStatus> _historyFor(OrderStatus status) {
  if (status == OrderStatus.cancelled) {
    return [OrderStatus.isNew, OrderStatus.cancelled];
  }
  final flow = OrderStatus.fulfilmentFlow;
  return flow.sublist(0, flow.indexOf(status) + 1);
}

OrderDetail _detailAt(
  OrderStatus status, {
  String? courier,
  String? awbNumber,
  String? cancellationReason,
  List<OrderStatus>? history,
}) {
  final reached = history ?? _historyFor(status);
  return OrderDetail(
    id: '#SS1',
    customer: 'Priyanshu Kateshiya',
    phone: '+91 98765 43210',
    address: 'Rajkot',
    placedAt: _placedAt,
    status: status,
    paidVia: 'UPI',
    courier: courier,
    awbNumber: awbNumber,
    cancellationReason: cancellationReason,
    reachedAt: {
      for (var index = 0; index < reached.length; index++)
        reached[index]: _placedAt.add(Duration(hours: index)),
    },
    lines: const [
      OrderLine(name: 'Saree', sku: 'SS-1', quantity: 1, pricePaise: 100000),
    ],
  );
}

/// Hosts a screen, optionally against a repository the test controls.
///
/// With no repository the real one is used, backed by the shared order store
/// — which is what the app runs on, so anything checked that way is checked
/// end to end.
Widget _host(Widget child, [OrdersRepository? repository]) => ProviderScope(
  overrides: [
    if (repository != null)
      ordersRepositoryProvider.overrideWithValue(repository),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    home: MediaQuery(
      data: const MediaQueryData(padding: EdgeInsets.only(top: 47)),
      child: child,
    ),
  ),
);

/// A real store-backed repository, outside any widget tree.
OrdersRepository _liveRepository() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container.read(ordersRepositoryProvider);
}

/// The status shown on the pill, as distinct from the same word appearing as
/// a step in the timeline.
Finder _pill(String label) =>
    find.descendant(of: find.byType(StatusPill), matching: find.text(label));

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('action bar', () {
    testWidgets('a new order offers Accept and Cancel', (tester) async {
      _phone(tester);

      await tester.pumpWidget(
        _host(
          OrderDetailScreen(detail: _detailAt(OrderStatus.isNew)),
          _StubOrders(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accept Order'), findsOneWidget);
      expect(find.text('Cancel Order'), findsOneWidget);
      expect(find.text('Invoice'), findsOneWidget);
    });

    testWidgets('a delivered order offers only the invoice', (tester) async {
      _phone(tester);

      await tester.pumpWidget(
        _host(
          OrderDetailScreen(detail: _detailAt(OrderStatus.delivered)),
          _StubOrders(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invoice'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Cancel Order'), findsNothing);
    });

    testWidgets('a shipped order can no longer be cancelled', (tester) async {
      _phone(tester);

      await tester.pumpWidget(
        _host(
          OrderDetailScreen(detail: _detailAt(OrderStatus.shipped)),
          _StubOrders(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark Delivered'), findsOneWidget);
      expect(find.text('Cancel Order'), findsNothing);
    });

    testWidgets('a packed order can be shipped or cancelled', (tester) async {
      _phone(tester);

      await tester.pumpWidget(
        _host(
          OrderDetailScreen(detail: _detailAt(OrderStatus.packed)),
          _StubOrders(),
        ),
      );
      await tester.pumpAndSettle();

      // Both are live; each opens the step that collects what it needs.
      final ship = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Mark Shipped'),
      );
      final cancel = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cancel Order'),
      );
      expect(ship.onPressed, isNotNull);
      expect(cancel.onPressed, isNotNull);
    });
  });

  group('a transition in flight', () {
    testWidgets('spins on its own button and disables the bar', (tester) async {
      _phone(tester);
      final repository = _HangingAccept();

      await tester.pumpWidget(
        _host(
          OrderDetailScreen(detail: _detailAt(OrderStatus.isNew)),
          repository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accept Order'));
      await tester.pump();

      // The label is gone, replaced by the spinner, and nothing else in the
      // bar can be pressed meanwhile.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Accept Order'), findsNothing);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
      );

      repository.completer.complete(_detailAt(OrderStatus.accepted));
      await tester.pumpAndSettle();

      // Settled on the new status, and the bar is live again.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Mark Packed'), findsOneWidget);
      expect(_pill('Accepted'), findsOneWidget);
    });

    testWidgets('a failure clears the spinner and says why', (tester) async {
      _phone(tester);

      await tester.pumpWidget(
        _host(
          OrderDetailScreen(detail: _detailAt(OrderStatus.isNew)),
          _FailingAccept(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accept Order'));
      await tester.pump();
      await tester.pump();

      expect(find.text(const RequestTimeout().message), findsOneWidget);
      // Never stuck: the spinner is off and the order is still where it was.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Accept Order'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });
  });

  group('ship sheet', () {
    /// Opens the sheet from a packed order.
    Future<void> open(WidgetTester tester, OrdersRepository repository) async {
      _phone(tester);
      await tester.pumpWidget(
        _host(
          OrderDetailScreen(detail: _detailAt(OrderStatus.packed)),
          repository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Shipped'));
      await tester.pumpAndSettle();
    }

    Future<void> pickCourier(WidgetTester tester, String name) async {
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }

    /// The AWB field is always the last text field in the sheet.
    Finder awbField() => find.byType(TextField).last;

    testWidgets('confirm stays disabled until both fields are given', (
      tester,
    ) async {
      await open(tester, _StubOrders());

      Widget confirm() =>
          tester.widget(find.widgetWithText(FilledButton, 'Confirm Shipment'));

      expect((confirm() as FilledButton).onPressed, isNull);

      // Courier alone is not enough.
      await pickCourier(tester, 'Delhivery');
      expect((confirm() as FilledButton).onPressed, isNull);

      // Nor is an AWB that is too short.
      await tester.enterText(awbField(), 'AB12');
      await tester.pumpAndSettle();
      expect((confirm() as FilledButton).onPressed, isNull);
      expect(find.textContaining('too short'), findsOneWidget);

      await tester.enterText(awbField(), 'AB123456');
      await tester.pumpAndSettle();
      expect((confirm() as FilledButton).onPressed, isNotNull);
      expect(find.textContaining('too short'), findsNothing);
    });

    testWidgets('the sheet does not open already complaining', (tester) async {
      await open(tester, _StubOrders());

      expect(find.text('Enter the AWB number.'), findsNothing);

      // Type and clear it, and now it has something to say.
      await tester.enterText(awbField(), 'A');
      await tester.enterText(awbField(), '');
      await tester.pumpAndSettle();
      expect(find.text('Enter the AWB number.'), findsOneWidget);
    });

    testWidgets('sends the chosen courier and a trimmed AWB', (tester) async {
      final repository = _RecordingShip();
      await open(tester, repository);

      await pickCourier(tester, 'Blue Dart');
      await tester.enterText(awbField(), '  1234567890  ');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Shipment'));
      await tester.pumpAndSettle();

      expect(repository.courier, 'Blue Dart');
      expect(repository.awbNumber, '1234567890');

      // Sheet gone, screen moved on.
      expect(find.text('Ship Order'), findsNothing);
      expect(_pill('Shipped'), findsOneWidget);
      expect(find.text('Mark Delivered'), findsOneWidget);
    });

    testWidgets('Other reveals a field and sends what was typed', (
      tester,
    ) async {
      final repository = _RecordingShip();
      await open(tester, repository);

      expect(find.byType(TextField), findsOneWidget);

      await pickCourier(tester, 'Other');
      expect(find.byType(TextField), findsNWidgets(2));

      await tester.enterText(find.byType(TextField).first, ' Local Runner ');
      await tester.enterText(awbField(), 'XY-99-88-77');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Shipment'));
      await tester.pumpAndSettle();

      expect(repository.courier, 'Local Runner');
      expect(repository.awbNumber, 'XY-99-88-77');
    });

    testWidgets('locks itself while the request is in flight', (tester) async {
      final repository = _HangingShip();
      await open(tester, repository);

      await pickCourier(tester, 'DTDC');
      await tester.enterText(awbField(), 'AB123456');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Shipment'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<PopScope<OrderDetail?>>(find.byType(PopScope<OrderDetail?>))
            .canPop,
        isFalse,
      );

      // The barrier goes through maybePop, so PopScope holds the sheet shut.
      // Plain pumps, not pumpAndSettle: the spinner never stops animating.
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Ship Order'), findsOneWidget);

      repository.completer.complete(_detailAt(OrderStatus.shipped));
      await tester.pumpAndSettle();
      expect(find.text('Ship Order'), findsNothing);
    });

    testWidgets('a failure keeps the sheet and the typed values', (
      tester,
    ) async {
      await open(tester, _FailingShip());

      await pickCourier(tester, 'Ekart');
      await tester.enterText(awbField(), 'AB123456');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Shipment'));
      await tester.pumpAndSettle();

      // Still open, still filled in, and it says what went wrong.
      expect(find.text('Ship Order'), findsOneWidget);
      expect(find.text(const ServerError(500).message), findsOneWidget);
      expect(find.text('AB123456'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // And it can be dismissed again now that nothing is in flight.
      expect(
        tester
            .widget<PopScope<OrderDetail?>>(find.byType(PopScope<OrderDetail?>))
            .canPop,
        isTrue,
      );
    });
  });

  group('cancel flow', () {
    Future<void> openScreen(
      WidgetTester tester,
      OrdersRepository repository, {
      OrderStatus status = OrderStatus.isNew,
    }) async {
      _phone(tester);
      await tester.pumpWidget(
        _host(OrderDetailScreen(detail: _detailAt(status)), repository),
      );
      await tester.pumpAndSettle();
    }

    Future<void> pickReason(WidgetTester tester, String reason) async {
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(reason).last);
      await tester.pumpAndSettle();
    }

    testWidgets('never cancels on a single tap', (tester) async {
      final repository = _RecordingCancel();
      await openScreen(tester, repository);

      await tester.tap(find.text('Cancel Order'));
      await tester.pumpAndSettle();

      // One tap gets a question, not a cancellation.
      expect(find.text('Cancel this order?'), findsOneWidget);
      expect(repository.calls, 0);
      expect(find.text('Reason for cancelling'), findsNothing);
    });

    testWidgets('backing out of the confirmation changes nothing', (
      tester,
    ) async {
      final repository = _RecordingCancel();
      await openScreen(tester, repository);

      await tester.tap(find.text('Cancel Order'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep order'));
      await tester.pumpAndSettle();

      expect(repository.calls, 0);
      expect(find.text('Reason for cancelling'), findsNothing);
      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('confirming asks for a reason before cancelling', (
      tester,
    ) async {
      final repository = _RecordingCancel();
      await openScreen(tester, repository);

      await tester.tap(find.text('Cancel Order'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();

      // Second step, and still nothing sent.
      expect(find.text('Reason for cancelling'), findsOneWidget);
      expect(repository.calls, 0);

      // Required: the confirm button waits for a reason.
      final confirm = find.widgetWithText(FilledButton, 'Cancel Order');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await pickReason(tester, 'Out of stock');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);

      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(repository.reason, 'Out of stock');
      expect(_pill('Cancelled'), findsOneWidget);
      // Nothing left to do to a cancelled order.
      expect(find.text('Cancel Order'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('Other sends the typed reason', (tester) async {
      final repository = _RecordingCancel();
      await openScreen(tester, repository);

      await tester.tap(find.text('Cancel Order'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      await pickReason(tester, 'Other');
      expect(find.byType(TextField), findsOneWidget);

      // Chosen but not yet typed, so there is still no reason to send.
      final confirm = find.widgetWithText(FilledButton, 'Cancel Order');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '  Shop closed  ');
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(repository.reason, 'Shop closed');
    });

    testWidgets('a failure keeps the sheet and the chosen reason', (
      tester,
    ) async {
      await openScreen(tester, _FailingCancel());

      await tester.tap(find.text('Cancel Order'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      await pickReason(tester, 'Payment failed');
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel Order'));
      await tester.pumpAndSettle();

      expect(find.text('Reason for cancelling'), findsOneWidget);
      expect(find.text(const NetworkUnavailable().message), findsOneWidget);
      expect(find.text('Payment failed'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('the button is absent once it is out of our hands', (
      tester,
    ) async {
      for (final status in [OrderStatus.shipped, OrderStatus.delivered]) {
        await openScreen(tester, _StubOrders(), status: status);
        expect(find.text('Cancel Order'), findsNothing, reason: status.label);
      }
    });
  });

  group('timeline', () {
    Future<void> show(WidgetTester tester, OrderDetail detail) async {
      _phone(tester);
      await tester.pumpWidget(
        _host(OrderDetailScreen(detail: detail), _StubOrders()),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a new order has one step done and the rest pending', (
      tester,
    ) async {
      await show(tester, _detailAt(OrderStatus.isNew));

      // The whole flow is laid out, so the admin can see what is coming.
      for (final label in ['Order Placed', 'Accepted', 'Packed', 'Shipped']) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      // Everything after the first step is still to happen.
      expect(find.text('Pending'), findsNWidgets(4));
    });

    testWidgets('steps complete as the order moves', (tester) async {
      await show(tester, _detailAt(OrderStatus.packed));

      // Placed, Accepted and Packed are done; Shipped and Delivered are not.
      expect(find.text('Pending'), findsNWidgets(2));
    });

    testWidgets('the shipped step carries the courier and AWB', (tester) async {
      await show(
        tester,
        _detailAt(
          OrderStatus.shipped,
          courier: 'Blue Dart',
          awbNumber: '1234567890',
        ),
      );

      expect(find.text('Blue Dart  •  1234567890'), findsOneWidget);
    });

    testWidgets('no courier line before anything has shipped', (tester) async {
      await show(tester, _detailAt(OrderStatus.packed));

      expect(
        find.descendant(
          of: find.byType(OrderTimeline),
          matching: find.textContaining('  •  '),
        ),
        findsNothing,
      );
    });

    testWidgets('a cancellation ends the timeline with its reason', (
      tester,
    ) async {
      await show(
        tester,
        _detailAt(
          OrderStatus.cancelled,
          cancellationReason: 'Out of stock',
          history: [
            OrderStatus.isNew,
            OrderStatus.accepted,
            OrderStatus.cancelled,
          ],
        ),
      );

      // What actually happened, then the cancellation and why.
      expect(find.text('Order Placed'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Cancelled'), findsWidgets);
      expect(find.text('Out of stock'), findsOneWidget);

      // Nothing is left hanging after it.
      expect(find.text('Pending'), findsNothing);
      expect(find.text('Packed'), findsNothing);
      expect(find.text('Shipped'), findsNothing);
    });

    testWidgets('the cancelled step is marked differently', (tester) async {
      await show(
        tester,
        _detailAt(
          OrderStatus.cancelled,
          cancellationReason: 'Payment failed',
          history: [OrderStatus.isNew, OrderStatus.cancelled],
        ),
      );

      // Crossed rather than ticked: one of each, since one step ran first.
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    // Against the real repository, so the timestamps are the ones the
    // transitions recorded rather than ones a test made up.
    test('real transitions build the steps they should', () async {
      final repository = _liveRepository();
      final id = (await repository.fetchOrders()).first.id;

      await repository.acceptOrder(id);
      await repository.markPacked(id);
      final shipped = await repository.markShipped(
        id,
        courier: 'DTDC',
        awbNumber: 'AB123456',
      );

      expect(shipped.timeline.map((event) => event.label), [
        'Order Placed',
        'Accepted',
        'Packed',
        'Shipped',
        'Delivered',
      ]);
      // Everything up to Shipped happened; Delivered has not.
      expect(shipped.timeline.map((event) => event.isDone), [
        true,
        true,
        true,
        true,
        false,
      ]);
      expect(
        shipped.timeline
            .firstWhere((event) => event.status == OrderStatus.shipped)
            .detail,
        'DTDC  •  AB123456',
      );
    });

    test('a real cancellation truncates the steps', () async {
      final repository = _liveRepository();
      final id = (await repository.fetchOrders()).first.id;

      await repository.acceptOrder(id);
      final cancelled = await repository.cancelOrder(
        id,
        reason: 'Out of stock',
      );

      expect(cancelled.timeline.map((event) => event.label), [
        'Order Placed',
        'Accepted',
        'Cancelled',
      ]);
      expect(cancelled.timeline.every((event) => event.isDone), isTrue);
      expect(cancelled.timeline.last.detail, 'Out of stock');
    });
  });

  group('an unexpected failure', () {
    // A repository is supposed to surface ApiException. When it throws
    // anything else the admin must still be told, and the control that
    // started it must still come back to life.
    testWidgets('on the bar still says something and unsticks', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _host(
          OrderDetailScreen(detail: _detailAt(OrderStatus.isNew)),
          _BuggyOrders(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accept Order'));
      await tester.pumpAndSettle();

      expect(find.text(const UnknownApiException().message), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('in the ship sheet still says something and unsticks', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(
        _host(
          OrderDetailScreen(detail: _detailAt(OrderStatus.packed)),
          _BuggyOrders(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark Shipped'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delhivery').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'AB123456');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Shipment'));
      await tester.pumpAndSettle();

      expect(find.text(const UnknownApiException().message), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirm Shipment'),
            )
            .onPressed,
        isNotNull,
      );
      // And the sheet can be closed again.
      expect(
        tester
            .widget<PopScope<OrderDetail?>>(find.byType(PopScope<OrderDetail?>))
            .canPop,
        isTrue,
      );
    });

    testWidgets('in the cancel sheet still says something and unsticks', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(
        _host(
          OrderDetailScreen(detail: _detailAt(OrderStatus.isNew)),
          _BuggyOrders(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel Order'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate order').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel Order'));
      await tester.pumpAndSettle();

      expect(find.text(const UnknownApiException().message), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Reason for cancelling'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Cancel Order'),
            )
            .onPressed,
        isNotNull,
      );
    });
  });

  group('the list after a transition', () {
    /// Opens the first New order from the list, on the real repository.
    Future<void> openFirstNewOrder(WidgetTester tester) async {
      _phone(tester);
      await tester.pumpWidget(_host(const OrdersScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Details').first);
      await tester.pumpAndSettle();
    }

    /// The detail screen's own back square, not the list's behind it.
    Future<void> popBack(WidgetTester tester) async {
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
    }

    testWidgets('back pops a pushed screen', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_host(const OrdersScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Details').first);
      await tester.pumpAndSettle();
      expect(find.byType(OrderDetailScreen), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailScreen), findsNothing);
      expect(find.text('Orders'), findsOneWidget);
    });

    testWidgets('back at the root of a tab steps left', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_host(const OrdersScreen()));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(OrdersScreen)),
        listen: false,
      );
      // Sitting on the Orders tab, with nothing pushed on top of it.
      container.read(adminTabProvider.notifier).select(2);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      // Nothing to pop, so it moves to the tab before this one.
      expect(container.read(adminTabProvider), 1);
    });

    testWidgets('reflects the new status when you pop back', (tester) async {
      await openFirstNewOrder(tester);

      await tester.tap(find.text('Accept Order'));
      await tester.pumpAndSettle();
      await popBack(tester);

      // One fewer New order — three in the sample, two now — and the header
      // count agrees.
      expect(find.text('2 new today'), findsOneWidget);
      expect(find.byType(OrderCard), findsNWidgets(2));
      expect(find.text('#SS20260914'), findsNothing);

      // And it is now under Accepted, alongside the two already there.
      await tester.ensureVisible(find.bySemanticsLabel('Accepted'));
      await tester.tap(find.bySemanticsLabel('Accepted'));
      await tester.pumpAndSettle();
      expect(find.text('#SS20260914'), findsOneWidget);
    });

    testWidgets('a cancelled order moves to the Cancelled chip', (
      tester,
    ) async {
      await openFirstNewOrder(tester);

      await tester.tap(find.text('Cancel Order'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Out of stock').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel Order'));
      await tester.pumpAndSettle();
      await popBack(tester);

      expect(find.text('2 new today'), findsOneWidget);

      await tester.ensureVisible(find.bySemanticsLabel('Cancelled'));
      await tester.tap(find.bySemanticsLabel('Cancelled'));
      await tester.pumpAndSettle();
      expect(find.text('#SS20260914'), findsOneWidget);
    });
  });

  group('filter chips', () {
    testWidgets('every status is reachable, plus All', (tester) async {
      _phone(tester);

      await tester.pumpWidget(_host(const OrdersScreen(), _StubOrders()));
      await tester.pumpAndSettle();

      for (final label in [
        'All',
        'New',
        'Accepted',
        'Packed',
        'Shipped',
        'Delivered',
        'Cancelled',
      ]) {
        await tester.ensureVisible(find.bySemanticsLabel(label));
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('All drops the status filter', (tester) async {
      // Tall enough that the first few orders past the new ones are built.
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const OrdersScreen()));
      await tester.pumpAndSettle();

      // Opens on New, so an accepted order is nowhere to be seen.
      expect(find.text('#SS20260914'), findsOneWidget);
      expect(find.text('#SS20260911'), findsNothing);

      await tester.ensureVisible(find.bySemanticsLabel('All'));
      await tester.tap(find.bySemanticsLabel('All'));
      await tester.pumpAndSettle();

      // Now both are in the same list.
      expect(find.text('#SS20260914'), findsOneWidget);
      expect(find.text('#SS20260911'), findsOneWidget);
    });
  });
}
