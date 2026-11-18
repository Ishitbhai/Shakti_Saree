import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/data/providers/backend_providers.dart';
import 'package:shakti_saree/admin/screens/orders_screen.dart';
import 'package:shakti_saree/admin/styles/app_theme.dart';
import 'package:shakti_saree/admin/widgets/orders/order_card.dart';

/// The orders list names the customer, on an order written the way the
/// customer app writes it: who it is for is on the order itself, and the
/// account's document holds only an address.
void main() {
  testWidgets('a checkout order shows its name, number and age', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const uid = 'testCustomerUid0001';
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(uid).set({'street': 'Kalawad Road'});
    await db.collection('orders').doc('ORD_1000000000001').set({
      'order_id': 'ORD_1000000000001',
      'user_id': uid,
      'total_amount': 12000,
      'order_status': 'Pending',
      'created_at': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      'delivery_address': {
        'recipient_name': 'Asha Patel',
        'phone': '9876543210',
        'street': 'Kalawad Road',
        'pincode': '360005',
      },
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [firestoreProvider.overrideWithValue(db)],
        child: MaterialApp(theme: AppTheme.light, home: const OrdersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OrderCard), findsOneWidget);
    expect(find.text('Asha Patel'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('10 min ago'), findsOneWidget);
    expect(find.text(uid), findsNothing);
  });
}
