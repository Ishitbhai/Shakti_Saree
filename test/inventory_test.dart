import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shakti_saree/admin/products/inventory_screen.dart';
import 'package:shakti_saree/admin/products/products_providers.dart';
import 'package:shakti_saree/admin/products/products_screen.dart';
import 'package:shakti_saree/core/theme/app_theme.dart';

Widget _host(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light,
    home: MediaQuery(
      data: const MediaQueryData(padding: EdgeInsets.only(top: 47)),
      child: child,
    ),
  ),
);

void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// The stepper buttons, found by their own labels — they are separate
/// controls rather than being merged into the row.
Finder _plus(String name) => find.bySemanticsLabel('Increase stock of $name');

Finder _minus(String name) => find.bySemanticsLabel('Decrease stock of $name');

ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(
      tester.element(find.byType(InventoryScreen)),
      listen: false,
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  /// Opens Inventory the way the app does — pushed from Products.
  ///
  /// Pumping it as the home route would leave nothing to pop, and the
  /// unsaved-changes guard only has a say when there is.
  Future<void> openInventory(WidgetTester tester) async {
    _tallPhone(tester);
    await tester.pumpWidget(_host(const ProductsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Inventory'));
    await tester.pumpAndSettle();
  }

  group('the list', () {
    testWidgets('shows every listing with its quantity', (tester) async {
      await openInventory(tester);

      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Stock management'), findsOneWidget);

      // Padded to two digits, as the design has it.
      expect(find.text('SKU: SS-1024'), findsOneWidget);
      expect(find.text('Stock 24 pcs'), findsOneWidget);
      expect(find.text('Stock 04 pcs'), findsOneWidget);
      expect(find.text('Stock 00 pcs'), findsOneWidget);
    });

    testWidgets('tallies the three stock levels', (tester) async {
      await openInventory(tester);

      // Of the five sample listings: 24, 12 and 8 are healthy, 4 is low and
      // 0 is out.
      expect(find.bySemanticsLabel('In Stock, 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Low Stock, 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Out of Stock, 1'), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('each stepper button is its own semantics node', (
      tester,
    ) async {
      // Disposed inline rather than in a tearDown: the framework checks for
      // leaked handles before tearDowns run.
      final handle = tester.ensureSemantics();
      await openInventory(tester);

      // Not just findable — findable as a node of its own. Merging the row
      // into one node would fold these labels into the row's text and leave
      // a screen reader a sentence with nothing to press.
      for (final entry in {
        'Increase stock of Banarasi Silk Saree': _plus,
        'Decrease stock of Banarasi Silk Saree': _minus,
      }.entries) {
        final node = tester.getSemantics(entry.value('Banarasi Silk Saree'));
        expect(node.label, entry.key, reason: entry.key);
        expect(node.flagsCollection.isButton, isTrue, reason: entry.key);
      }

      handle.dispose();
    });
  });

  group('stepping', () {
    testWidgets('changes the row and the tallies before saving', (
      tester,
    ) async {
      await openInventory(tester);

      // Cotton Daily Saree sits at 4, which is low. Two more makes it
      // healthy, and the tallies move with it.
      await tester.tap(_plus('Cotton Daily Saree'));
      await tester.pump();
      await tester.tap(_plus('Cotton Daily Saree'));
      await tester.pump();

      expect(find.text('Stock 06 pcs'), findsOneWidget);
      expect(find.bySemanticsLabel('In Stock, 4'), findsOneWidget);
      expect(find.bySemanticsLabel('Low Stock, 0'), findsOneWidget);

      // Nothing has reached the catalogue yet.
      final products = await _containerOf(
        tester,
      ).read(productsRepositoryProvider).fetchProducts();
      expect(products.firstWhere((p) => p.sku == 'SS-1026').stock, 4);
    });

    testWidgets('will not go below an empty shelf', (tester) async {
      await openInventory(tester);

      // Georgette Party Wear is already at zero.
      final minus = tester.widget<InkWell>(
        find.descendant(
          of: _minus('Georgette Party Wear'),
          matching: find.byType(InkWell),
        ),
      );
      expect(minus.onTap, isNull);
    });

    testWidgets('stepping back to where it started is not a change', (
      tester,
    ) async {
      await openInventory(tester);

      Widget button() =>
          tester.widget(find.widgetWithText(FilledButton, 'Update Stock'));
      expect((button() as FilledButton).onPressed, isNull);

      await tester.tap(_plus('Banarasi Silk Saree'));
      await tester.pump();
      expect((button() as FilledButton).onPressed, isNotNull);

      await tester.tap(_minus('Banarasi Silk Saree'));
      await tester.pump();
      // Back to 24, so there is nothing left to save.
      expect((button() as FilledButton).onPressed, isNull);
    });
  });

  group('saving', () {
    testWidgets('writes every stepped row at once', (tester) async {
      await openInventory(tester);

      await tester.tap(_plus('Banarasi Silk Saree'));
      await tester.pump();
      await tester.tap(_minus('Cotton Daily Saree'));
      await tester.pump();

      await tester.tap(find.text('Update Stock'));
      await tester.pumpAndSettle();

      expect(find.text('2 listings updated'), findsOneWidget);

      final products = await _containerOf(
        tester,
      ).read(productsRepositoryProvider).fetchProducts();
      expect(products.firstWhere((p) => p.sku == 'SS-1024').stock, 25);
      expect(products.firstWhere((p) => p.sku == 'SS-1026').stock, 3);

      // Saved, so the button has nothing left to do.
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Update Stock'),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('leaving', () {
    testWidgets('warns about a count that was not saved', (tester) async {
      await openInventory(tester);

      await tester.tap(_plus('Banarasi Silk Saree'));
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard stock changes?'), findsOneWidget);

      await tester.tap(find.text('Keep counting'));
      await tester.pumpAndSettle();
      expect(find.text('Inventory'), findsOneWidget);
    });

    testWidgets('leaves quietly when nothing was stepped', (tester) async {
      await openInventory(tester);
      expect(find.text('Stock management'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Discard stock changes?'), findsNothing);
      expect(find.text('Products'), findsOneWidget);
    });
  });
}
