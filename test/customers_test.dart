import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/customers/customer.dart';
import 'package:shakti_saree/admin/customers/customers_providers.dart';
import 'package:shakti_saree/admin/customers/customers_screen.dart';
import 'package:shakti_saree/admin/customers/widgets/customer_tile.dart';
import 'package:shakti_saree/admin/orders/orders_providers.dart';
import 'package:shakti_saree/admin/shared/widgets/order_tile.dart';
import 'package:shakti_saree/core/theme/app_theme.dart';
import 'package:shakti_saree/mock/mock_data.dart';

Widget _host() => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light,
    home: const MediaQuery(
      data: MediaQueryData(padding: EdgeInsets.only(top: 47)),
      child: CustomersScreen(),
    ),
  ),
);

void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Finder _searchField() =>
    find.widgetWithText(TextField, 'Search name or mobile');

/// The row carrying a given customer name.
Finder _tileFor(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(CustomerTile));

/// A container with the real providers, for reading the derived list directly.
ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('the list', () {
    testWidgets('counts everyone who has ordered', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // Fourteen sample orders, each from a different person.
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('14 registered'), findsOneWidget);
    });

    testWidgets('shows a row per person, with their totals', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // Sorted by spend, so the biggest is at the top: Hetal Sompura's
      // three-line order, ₹11,549 after its discount.
      final first = tester
          .widgetList<CustomerTile>(find.byType(CustomerTile))
          .first;
      expect(first.customer.name, 'Hetal Sompura');
      expect(first.customer.spentPaise, 1154900);

      expect(find.text('Meera Trivedi'), findsOneWidget);
      expect(find.text('+91 94263 88104'), findsOneWidget);
      expect(find.text('1 order  •  ₹8,999 spent'), findsOneWidget);
    });

    test('a cancelled order still counts as an order, not as spend', () {
      final container = _container();
      final cancelled = MockData.orders().firstWhere(
        (order) => order.cancellationReason != null,
      );

      final customers = container.read(customersProvider.future);

      return customers.then((loaded) {
        final customer = loaded.firstWhere(
          (candidate) => candidate.phone == cancelled.phone,
        );
        expect(customer.orderCount, greaterThanOrEqualTo(1));
        expect(customer.spentPaise, 0);
      });
    });

    testWidgets('initials come off the name', (tester) async {
      const customer = Customer(
        name: 'Priyanshu Kateshiya',
        phone: '+91 98250 41267',
        orderCount: 1,
        spentPaise: 100,
      );
      expect(customer.initials, 'PK');

      // One word, and nothing at all, both still give something to draw.
      expect(
        const Customer(
          name: 'Meera',
          phone: '',
          orderCount: 0,
          spentPaise: 0,
        ).initials,
        'M',
      );
      expect(
        const Customer(
          name: '   ',
          phone: '',
          orderCount: 0,
          spentPaise: 0,
        ).initials,
        '-',
      );
    });
  });

  group('search', () {
    testWidgets('narrows by name, whatever the case', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.enterText(_searchField(), 'meera');
      await tester.pumpAndSettle();

      expect(find.byType(CustomerTile), findsOneWidget);
      expect(find.text('Meera Trivedi'), findsOneWidget);
    });

    testWidgets('narrows by number, however it is spaced', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // Typed without the spaces the stored number carries.
      await tester.enterText(_searchField(), '9825041267');
      await tester.pumpAndSettle();

      expect(find.byType(CustomerTile), findsOneWidget);
      expect(find.text('Priyanshu Kateshiya'), findsOneWidget);
    });

    testWidgets('says so when nothing matches', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.enterText(_searchField(), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.text('Nobody matches "zzzz"'), findsOneWidget);
      expect(find.byType(CustomerTile), findsNothing);

      // The count in the header is everyone, not the matches.
      expect(find.text('14 registered'), findsOneWidget);
    });

    testWidgets('clearing brings everyone back', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.enterText(_searchField(), 'meera');
      await tester.pumpAndSettle();
      expect(find.byType(CustomerTile), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      expect(find.byType(CustomerTile), findsWidgets);
      expect(find.text('Nobody matches ""'), findsNothing);
    });
  });

  group('a customer', () {
    testWidgets('opens on what they have ordered', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Meera Trivedi'));
      await tester.pumpAndSettle();

      // Their own screen, listing their orders and nobody else's.
      expect(find.text('+91 94263 88104'), findsWidgets);
      expect(find.byType(OrderTile), findsOneWidget);
      expect(find.text('1 order  •  ₹8,999 spent'), findsOneWidget);
      expect(find.byType(CustomerTile), findsNothing);
    });

    testWidgets('follows what happens on the orders tab', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CustomersScreen)),
        listen: false,
      );

      // Cancel Meera's only order from the repository the orders tab uses.
      await container
          .read(ordersRepositoryProvider)
          .cancelOrder('#SS20260913', reason: 'Out of stock');
      await tester.pumpAndSettle();

      // She has still ordered once, but has now spent nothing. Scoped to her
      // row: the sample already has cancelled customers sitting at zero.
      expect(
        find.descendant(
          of: _tileFor('Meera Trivedi'),
          matching: find.text('1 order  •  ₹0 spent'),
        ),
        findsOneWidget,
      );
    });
  });
}
