import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/admin_app.dart';

void main() {
  testWidgets('admin shell opens on Dashboard and switches tabs', (
    tester,
  ) async {
    // Phone-sized surface — the shell is built for mobile only.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AdminApp());

    expect(find.textContaining('sales chart'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    await tester.pumpAndSettle();

    expect(find.textContaining('add-product form'), findsOneWidget);
  });

  testWidgets('More tab pushes Categories with a back button', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AdminApp());

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();

    expect(find.textContaining('rename and delete'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('rename and delete'), findsNothing);
    expect(find.text('Logout'), findsOneWidget);
  });
}
