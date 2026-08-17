import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/admin_app.dart';

void main() {
  testWidgets('admin shell opens on Dashboard and switches screens', (
    tester,
  ) async {
    // Force a wide surface so the sidebar renders permanently.
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AdminApp());

    expect(find.textContaining('sales chart'), findsOneWidget);

    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();

    expect(find.textContaining('sales chart'), findsNothing);
    expect(find.textContaining('add-product form'), findsOneWidget);
  });
}
