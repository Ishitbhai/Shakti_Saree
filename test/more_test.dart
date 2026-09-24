import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/categories/categories_screen.dart';
import 'package:shakti_saree/admin/more/more_screen.dart';
import 'package:shakti_saree/admin/products/products_providers.dart';
import 'package:shakti_saree/admin/shared/admin_tab.dart';
import 'package:shakti_saree/core/theme/app_theme.dart';
import 'package:shakti_saree/mock/mock_data.dart';

Widget _host() => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light,
    home: const MediaQuery(
      data: MediaQueryData(padding: EdgeInsets.only(top: 47)),
      child: MoreScreen(),
    ),
  ),
);

void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(
      tester.element(find.byType(MoreScreen)),
      listen: false,
    );

void main() {
  group('the page', () {
    testWidgets('shows who is signed in', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      final admin = MockData.admin();
      expect(find.text('More'), findsOneWidget);
      expect(find.text(admin.name), findsOneWidget);
      expect(find.text(admin.email), findsOneWidget);
      expect(find.text(admin.role), findsOneWidget);
      // First letter of the name on the avatar, both initials on the
      // monogram — 'Priyanshu Kateshiya' gives P and PK.
      expect(find.text(admin.initial), findsOneWidget);
      expect(find.text(admin.initials), findsOneWidget);
    });

    testWidgets('lists the sections and the version', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      expect(find.text('STORE'), findsOneWidget);
      expect(find.text('SYSTEM'), findsOneWidget);
      expect(find.text('Admin Edit Profile'), findsOneWidget);
      expect(find.text('Manage Categories'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Shakti Saree Admin • v1.0.0'), findsOneWidget);
    });
  });

  group('the rows', () {
    testWidgets('every row leads somewhere', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // Nothing on this tab is a dead end any more, so nothing wears the
      // "Soon" label the menu shows a row with nowhere to go.
      expect(find.text('Soon'), findsNothing);
    });

    testWidgets('categories is reachable from here', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Manage Categories'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoriesScreen), findsOneWidget);
      expect(find.text('Manage Categories'), findsWidgets);
    });
  });

  group('logging out', () {
    testWidgets('asks first, and staying changes nothing', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      final container = _containerOf(tester);
      // Something to lose: delete a listing before logging out.
      await container.read(productsRepositoryProvider).deleteProduct('SS-1024');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsOneWidget);

      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();

      final products = await container
          .read(productsRepositoryProvider)
          .fetchProducts();
      expect(products, hasLength(4));
    });

    testWidgets('confirming puts the sample data back', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      final container = _containerOf(tester);
      await container.read(productsRepositoryProvider).deleteProduct('SS-1024');
      container.read(adminTabProvider.notifier).select(4);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      // The session was the stores, so it is back to seed, on the home tab.
      final products = await container
          .read(productsRepositoryProvider)
          .fetchProducts();
      expect(products, hasLength(5));
      expect(container.read(adminTabProvider), AdminTab.home);
      expect(find.text('Back to the sample data'), findsOneWidget);
    });
  });

  testWidgets('back steps to the tab on the left', (tester) async {
    _tallPhone(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final container = _containerOf(tester);
    container.read(adminTabProvider.notifier).select(4);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    expect(container.read(adminTabProvider), 3);
  });
}
