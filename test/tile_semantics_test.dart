import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shakti_saree/admin/categories/category.dart';
import 'package:shakti_saree/admin/categories/widgets/category_tile.dart';
import 'package:shakti_saree/admin/products/product.dart';
import 'package:shakti_saree/admin/products/widgets/product_tile.dart';
import 'package:shakti_saree/admin/shared/widgets/swatches.dart';
import 'package:shakti_saree/core/theme/app_theme.dart';

/// The rows carry an edit and a delete button each. Both have to reach a
/// screen reader as controls of their own — wrapping a whole row in a
/// MergeSemantics folds them into the row's text and leaves a sentence with
/// nothing to press.
///
/// Checked with getSemantics rather than a finder: bySemanticsLabel matches a
/// merged node too, so a finder alone would pass either way.
Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(8), child: child),
  ),
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Asserts a button is its own node, labelled exactly as given.
void _expectOwnButton(WidgetTester tester, String label) {
  final node = tester.getSemantics(find.bySemanticsLabel(label));
  expect(node.label, label, reason: label);
  expect(node.flagsCollection.isButton, isTrue, reason: label);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a product row keeps its buttons reachable', (tester) async {
    _phone(tester);
    // Disposed inline: the framework checks for leaked handles before
    // tearDowns run.
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        ProductTile(
          product: const Product(
            name: 'Banarasi Silk Saree',
            sku: 'SS-1024',
            pricePaise: 249900,
            stock: 24,
          ),
          swatch: Swatches.at(0),
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    _expectOwnButton(tester, 'Edit Banarasi Silk Saree');
    _expectOwnButton(tester, 'Delete Banarasi Silk Saree');

    handle.dispose();
  });

  testWidgets('a category row keeps its buttons reachable', (tester) async {
    _phone(tester);
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        CategoryTile(
          listing: const CategoryListing(
            category: Category(name: 'Banarasi'),
            productCount: 1,
          ),
          onEdit: () {},
          onDelete: () {},
          onToggleHidden: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    _expectOwnButton(tester, 'Edit Banarasi');
    _expectOwnButton(tester, 'Delete Banarasi');

    handle.dispose();
  });
}
