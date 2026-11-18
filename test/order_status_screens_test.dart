import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/data/providers/backend_providers.dart';
import 'package:shakti_saree/admin/data/repositories/firestore_orders_repository.dart';
import 'package:shakti_saree/admin/models/order_options.dart';
import 'package:shakti_saree/admin/screens/order_detail_screen.dart';
import 'package:shakti_saree/admin/screens/orders_screen.dart';
import 'package:shakti_saree/admin/styles/app_theme.dart';
import 'package:shakti_saree/admin/widgets/common/status_pill.dart';
import 'package:shakti_saree/admin/widgets/orders/order_card.dart';

/// The orders list and the order's own screen, on the real repository: each
/// button moves `order_status` in the database, and only that.
void main() {
  const orderId = 'ORD_1000000000002';
  late FakeFirebaseFirestore db;

  Future<Map<String, dynamic>> stored() async =>
      (await db.collection('orders').doc(orderId).get()).data()!;

  /// Shaped like the live order that prompted this: finished under the old
  /// `status`, while `order_status` still says what checkout wrote.
  Future<void> pumpOrders(
    WidgetTester tester,
    String orderStatus, {
    Map<String, dynamic> fields = const {},
    Map<String, dynamic>? payment,
  }) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final at = Timestamp.fromDate(DateTime.utc(2026, 11, 2, 9, 30));
    db = FakeFirebaseFirestore();
    await db.collection('orders').doc(orderId).set({
      'order_id': orderId,
      'user_id': 'testCustomerUid0002',
      'total_amount': 1000.0,
      'order_status': orderStatus,
      'status': 'Delivered',
      'created_at': at,
      'status_history': {
        'Accepted': at,
        'Packed': at,
        'Shipped': at,
        'Delivered': at,
      },
      'delivery_address': {
        'recipient_name': 'Asha Patel',
        'phone': '9876543210',
      },
      ...fields,
    });
    if (payment != null) {
      await db.collection('payments').doc('payment1').set(payment);
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [firestoreProvider.overrideWithValue(db)],
        child: MaterialApp(theme: AppTheme.light, home: const OrdersScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapFilled(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FilledButton, label).hitTestable());
    await tester.pumpAndSettle();
  }

  /// Fixed pumps, because the list's progress bar keeps moving behind the
  /// courier sheet for as long as the sheet is open.
  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Fills in the courier sheet that [button] opens, and confirms it.
  Future<void> shipFrom(WidgetTester tester, String button) async {
    await tester.tap(find.widgetWithText(FilledButton, button).hitTestable());
    await pumpSheet(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await pumpSheet(tester);
    await tester.tap(find.text('Blue Dart').last);
    await pumpSheet(tester);
    await tester.enterText(find.byType(TextField).last, 'NEW123456');
    await pumpSheet(tester);
    await tapFilled(tester, 'Confirm Shipment');
  }

  /// Which chip an order sits under is the list's word on where it has got to.
  Future<void> openChip(WidgetTester tester, String label) async {
    final chip = find.text(label).first;
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  testWidgets('the list goes by order_status, not the older status', (
    tester,
  ) async {
    await pumpOrders(tester, 'Pending');

    // Opens on the New queue, which is where `order_status` says it is.
    expect(find.byType(OrderCard), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Accept'), findsOneWidget);
  });

  testWidgets('every button on the list moves order_status', (tester) async {
    await pumpOrders(tester, 'Pending');

    await tapFilled(tester, 'Accept');
    expect((await stored())['order_status'], 'Accepted');

    await openChip(tester, 'Accepted');
    await tapFilled(tester, 'Pack');
    expect((await stored())['order_status'], 'Packed');

    await openChip(tester, 'Packed');
    await shipFrom(tester, 'Ship');
    expect((await stored())['order_status'], 'Shipped');

    await openChip(tester, 'Shipped');
    await tapFilled(tester, 'Mark Delivered');
    expect((await stored())['order_status'], 'Delivered');

    await openChip(tester, 'Delivered');
    expect(find.byType(OrderCard), findsOneWidget);
    expect((await stored())['status'], 'Delivered');
  });

  testWidgets('every button on the order screen moves order_status', (
    tester,
  ) async {
    await pumpOrders(tester, 'Pending');

    await tester.tap(find.text('View Details').hitTestable());
    await tester.pumpAndSettle();
    expect(find.byType(OrderDetailScreen), findsOneWidget);

    String pill() =>
        tester.widget<StatusPill>(find.byType(StatusPill)).status.label;
    expect(pill(), 'New');

    await tapFilled(tester, 'Accept Order');
    expect((await stored())['order_status'], 'Accepted');
    expect(pill(), 'Accepted');

    await tapFilled(tester, 'Mark Packed');
    expect((await stored())['order_status'], 'Packed');
    expect(pill(), 'Packed');

    await shipFrom(tester, 'Mark Shipped');
    expect((await stored())['order_status'], 'Shipped');
    expect(pill(), 'Shipped');

    await tapFilled(tester, 'Mark Delivered');
    expect((await stored())['order_status'], 'Delivered');
    expect(pill(), 'Delivered');

    final fields = await stored();
    expect(fields['status'], 'Delivered');
    expect(fields['courier'], 'Blue Dart');
    expect(fields['awb_number'], 'NEW123456');
  });

  testWidgets('cancelling on the order screen moves order_status', (
    tester,
  ) async {
    await pumpOrders(tester, 'Pending');

    await tester.tap(find.text('View Details').hitTestable());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Cancel Order'));
    await tester.tap(find.text('Cancel Order'));
    await tester.pumpAndSettle();

    // Confirm the dialog, then give a reason in the sheet.
    await tester.tap(find.text('Cancel order').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(OrderOptions.cancellationReasons.first).last);
    await tester.pumpAndSettle();
    await tapFilled(tester, 'Cancel Order');

    final fields = await stored();
    expect(fields['order_status'], 'Cancelled');
    expect(fields['status'], 'Delivered');
  });

  group('a cash on delivery order', () {
    const cash = {'payment_method': 'COD', 'payment_status': 'Pending'};
    const payment = {'order_id': orderId, ...cash};

    Future<Map<String, dynamic>> storedPayment() async =>
        (await db.collection('payments').doc('payment1').get()).data()!;

    testWidgets('stops saying pending once the order screen delivers it', (
      tester,
    ) async {
      await pumpOrders(tester, 'Shipped', fields: cash, payment: payment);

      await openChip(tester, 'Shipped');
      await tester.tap(find.text('View Details').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Paid via COD (Pending)'), findsOneWidget);

      await tapFilled(tester, 'Mark Delivered');

      expect(find.text('Paid via COD'), findsOneWidget);
      expect(find.text('Paid via COD (Pending)'), findsNothing);
      expect((await stored())['payment_status'], 'Paid');
      expect((await storedPayment())['payment_status'], 'Success');
    });

    testWidgets('is settled by the button on the list too', (tester) async {
      await pumpOrders(tester, 'Shipped', fields: cash, payment: payment);

      await openChip(tester, 'Shipped');
      await tapFilled(tester, 'Mark Delivered');

      expect((await stored())['payment_status'], 'Paid');
      expect((await storedPayment())['payment_status'], 'Success');

      await openChip(tester, 'Delivered');
      await tester.tap(find.text('View Details').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Paid via COD'), findsOneWidget);
    });

    testWidgets('catches up when someone else delivered it first', (
      tester,
    ) async {
      await pumpOrders(tester, 'Shipped', fields: cash, payment: payment);

      await openChip(tester, 'Shipped');
      await tester.tap(find.text('View Details').hitTestable());
      await tester.pumpAndSettle();

      // Another admin, while this screen is open.
      await FirestoreOrdersRepository(db).markDelivered(orderId);

      await tapFilled(tester, 'Mark Delivered');

      expect(find.text('Paid via COD'), findsOneWidget);
      expect(find.text('Paid via COD (Pending)'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Mark Delivered'), findsNothing);
    });

    testWidgets('one delivered earlier no longer says pending', (tester) async {
      await pumpOrders(tester, 'Delivered', fields: cash, payment: payment);

      await openChip(tester, 'Delivered');
      await tester.tap(find.text('View Details').hitTestable());
      await tester.pumpAndSettle();

      expect(find.text('Paid via COD'), findsOneWidget);
    });
  });

  testWidgets('a shipped order offers delivery, whatever status says', (
    tester,
  ) async {
    await pumpOrders(tester, 'Shipped');

    await openChip(tester, 'Shipped');
    await tapFilled(tester, 'Mark Delivered');

    expect((await stored())['order_status'], 'Delivered');
  });
}
