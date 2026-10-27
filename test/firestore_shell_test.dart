import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/data/admin_tab.dart';
import 'package:shakti_saree/admin/data/providers/backend_providers.dart';
import 'package:shakti_saree/admin/screens/admin_shell.dart';
import 'package:shakti_saree/admin/styles/app_theme.dart';
import 'package:shakti_saree/admin/widgets/navigation/admin_bottom_nav.dart';

import 'support/firestore_seed.dart';

/// The real shell on Firestore: the same screens the app shows, wired the
/// way `main.dart` wires them, against a fake database holding what the live
/// one does.
void main() {
  late FakeFirebaseFirestore db;

  Future<ProviderContainer> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    db = await seededFirestore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [firestoreProvider.overrideWithValue(db)],
        child: MaterialApp(theme: AppTheme.light, home: const AdminShell()),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(AdminShell)),
      listen: false,
    );
  }

  Future<void> openTab(WidgetTester tester, int index) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AdminBottomNav),
        matching: find.byIcon(AdminBottomNav.items[index].icon),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the dashboard shows the real order', (tester) async {
    await pumpShell(tester);

    // The name sits beside the item count in the recent-orders strip.
    expect(
      find.textContaining('Ishitkumar Vadhavana').hitTestable(),
      findsAtLeastNWidgets(1),
    );
    expect(find.text('ORD_001').hitTestable(), findsAtLeastNWidgets(1));
  });

  testWidgets('the products tab lists and searches the catalogue', (
    tester,
  ) async {
    await pumpShell(tester);
    await openTab(tester, 1);

    expect(find.text('Banarasi Silk Saree').hitTestable(), findsOneWidget);
    expect(find.text('1 total'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Search product or SKU'),
      'kanjivaram',
    );
    await tester.pumpAndSettle();
    expect(find.text('Banarasi Silk Saree').hitTestable(), findsNothing);
    expect(find.text('Nothing matches "kanjivaram"'), findsOneWidget);
  });

  testWidgets('accepting from the orders list writes and moves the order', (
    tester,
  ) async {
    final container = await pumpShell(tester);
    container.read(adminTabProvider.notifier).select(AdminTab.orders);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Accept').hitTestable());
    await tester.pumpAndSettle();

    final stored = await db
        .collection('orders')
        .where('order_id', isEqualTo: 'ORD_001')
        .get();
    expect(stored.docs.single.data()['status'], 'Accepted');
    // Gone from the New queue the tab opens on.
    expect(find.text('No new orders'), findsOneWidget);
  });

  testWidgets('a write from elsewhere reaches an open screen', (tester) async {
    await pumpShell(tester);
    await openTab(tester, 1);

    // As the customer app or the console would: straight to the database,
    // with nothing in the panel told about it.
    await db.collection('products').add({
      'product_id': 'PROD_002',
      'product_name': 'Paithani Saree',
      'price': 7999.0,
      'category_id': 'CAT_001',
      'stock_quantity': 3,
    });
    await tester.pumpAndSettle();

    expect(find.text('Paithani Saree').hitTestable(), findsOneWidget);
    expect(find.text('2 total'), findsOneWidget);
  });

  testWidgets('the users tab lists registered customers', (tester) async {
    await pumpShell(tester);
    await openTab(tester, 3);

    expect(find.text('Ishitkumar Vadhavana').hitTestable(), findsOneWidget);
    expect(find.text('test@example.com').hitTestable(), findsOneWidget);
    expect(find.text('1 registered'), findsOneWidget);
  });
}
