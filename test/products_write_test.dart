import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shakti_saree/admin/products/product.dart';
import 'package:shakti_saree/admin/products/products_screen.dart';
import 'package:shakti_saree/admin/products/widgets/product_tile.dart';
import 'package:shakti_saree/admin/shared/widgets/labelled_field.dart';
import 'package:shakti_saree/core/theme/app_theme.dart';
import 'package:shakti_saree/mock/product_store.dart';

/// A catalogue with a single listing, for the case where deleting empties it.
class _OneProductStore extends ProductStore {
  @override
  List<Product> build() => const [
    Product(name: 'Only Saree', sku: 'SS-9001', pricePaise: 100000, stock: 3),
  ];
}

Widget _host({List<Override> overrides = const []}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: AppTheme.light,
    home: const MediaQuery(
      data: MediaQueryData(padding: EdgeInsets.only(top: 47)),
      child: ProductsScreen(),
    ),
  ),
);

/// Tall enough that the whole form builds — a ListView only makes what fits.
void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// The tile carrying a given product name.
Finder _tileFor(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(ProductTile));

/// The tile's action buttons live inside a MergeSemantics, so they are found
/// by their icon within the row rather than by label.
Finder _action(String name, IconData icon) =>
    find.descendant(of: _tileFor(name), matching: find.byIcon(icon));

/// The text input under a given form label.
Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(LabelledField)),
  matching: find.byType(TextField),
);

Future<void> _openEditor(WidgetTester tester, String name) async {
  await tester.tap(_action(name, Icons.edit_outlined));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('editing', () {
    testWidgets('opens on the listing that was tapped', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await _openEditor(tester, 'Kanjivaram Pure Silk');

      // Same screen as Add, wearing the other name.
      expect(find.text('Edit Product'), findsOneWidget);
      expect(find.text('SKU SS-1025'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Add Product'), findsNothing);
      expect(find.text('Publish'), findsNothing);

      // Prefilled from the stored product, not from the design's sample.
      expect(
        tester.widget<TextField>(_field('Product Name')).controller!.text,
        'Kanjivaram Pure Silk',
      );
      expect(
        tester.widget<TextField>(_field('SKU Code')).controller!.text,
        'SS-1025',
      );
      expect(
        tester.widget<TextField>(_field('Price (₹)')).controller!.text,
        '3,299',
      );
      expect(
        tester.widget<TextField>(_field('Stock Qty')).controller!.text,
        '12',
      );
    });

    testWidgets('saving shows on the list straight away', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await _openEditor(tester, 'Cotton Daily Saree');
      await tester.enterText(_field('Product Name'), 'Cotton Everyday Saree');
      await tester.enterText(_field('Price (₹)'), '1899');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Back on the list, already showing the new values.
      expect(find.byType(ProductTile), findsNWidgets(5));
      expect(find.text('Cotton Everyday Saree'), findsOneWidget);
      expect(find.text('Cotton Daily Saree'), findsNothing);
      // Another listing is priced the same, so scope it to the row.
      expect(
        find.descendant(
          of: _tileFor('Cotton Everyday Saree'),
          matching: find.text('₹1,899'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the stock badge follows the quantity typed', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // Opens healthy at 24.
      await _openEditor(tester, 'Banarasi Silk Saree');
      expect(find.text('In Stock 24'), findsOneWidget);

      await tester.enterText(_field('Stock Qty'), '3');
      await tester.pumpAndSettle();
      expect(find.text('Low Stock'), findsOneWidget);

      await tester.enterText(_field('Stock Qty'), '0');
      await tester.pumpAndSettle();
      expect(find.text('Out of Stock'), findsOneWidget);

      // And the list agrees once it is saved.
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: _tileFor('Banarasi Silk Saree'),
          matching: find.text('Out of Stock'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the placeholder colour is part of the listing', (
      tester,
    ) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await _openEditor(tester, 'Banarasi Silk Saree');
      await tester.tap(find.bySemanticsLabel('Placeholder colour 4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      final tile = tester.widget<ProductTile>(
        _tileFor('Banarasi Silk Saree').first,
      );
      expect(tile.product.swatchIndex, 3);
    });

    group('rejects', () {
      Future<void> attempt(
        WidgetTester tester,
        String label,
        String value,
      ) async {
        _tallPhone(tester);
        await tester.pumpWidget(_host());
        await tester.pumpAndSettle();

        await _openEditor(tester, 'Banarasi Silk Saree');
        await tester.enterText(_field(label), value);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();
      }

      testWidgets('a blank name', (tester) async {
        await attempt(tester, 'Product Name', '');

        expect(find.text('Give the product a name.'), findsOneWidget);
        // Still on the form; nothing was saved.
        expect(find.text('Edit Product'), findsOneWidget);
      });

      testWidgets('a blank SKU', (tester) async {
        await attempt(tester, 'SKU Code', '');

        expect(find.text('A SKU is required.'), findsOneWidget);
        expect(find.text('Edit Product'), findsOneWidget);
      });

      testWidgets("a SKU another listing already has", (tester) async {
        await attempt(tester, 'SKU Code', 'SS-1026');

        expect(find.text('SKU SS-1026 is already in use.'), findsOneWidget);
        expect(find.text('Edit Product'), findsOneWidget);
      });

      testWidgets('a price of zero', (tester) async {
        await attempt(tester, 'Price (₹)', '0');

        expect(find.text('Price must be more than zero.'), findsOneWidget);
        expect(find.text('Edit Product'), findsOneWidget);
      });

      testWidgets('negative stock', (tester) async {
        await attempt(tester, 'Stock Qty', '-4');

        expect(find.text('Stock cannot be negative.'), findsOneWidget);
        expect(find.text('Edit Product'), findsOneWidget);
      });
    });

    testWidgets('keeping its own SKU is not a clash', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await _openEditor(tester, 'Banarasi Silk Saree');
      // Only the name changes; the SKU stays exactly as it was.
      await tester.enterText(_field('Product Name'), 'Banarasi Silk Classic');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Banarasi Silk Classic'), findsOneWidget);
      expect(find.textContaining('already in use'), findsNothing);
    });
  });

  group('leaving the form', () {
    testWidgets('warns when there are unsaved changes', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await _openEditor(tester, 'Banarasi Silk Saree');
      await tester.enterText(_field('Product Name'), 'Half typed');
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      // Thinking better of it puts you back in the form, edit intact.
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Product'), findsOneWidget);
      expect(
        tester.widget<TextField>(_field('Product Name')).controller!.text,
        'Half typed',
      );

      // Discarding leaves, and the catalogue is untouched.
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Banarasi Silk Saree'), findsOneWidget);
      expect(find.text('Half typed'), findsNothing);
    });

    testWidgets('leaves quietly when nothing was changed', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await _openEditor(tester, 'Banarasi Silk Saree');
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Products'), findsOneWidget);
    });

    testWidgets('does not warn after a save', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await _openEditor(tester, 'Banarasi Silk Saree');
      await tester.enterText(_field('Product Name'), 'Saved Name');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Saved Name'), findsOneWidget);
    });
  });

  group('deleting', () {
    testWidgets('asks first, naming the product', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(_action('Cotton Daily Saree', Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete this product?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('Cotton Daily Saree'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('SS-1026'),
        ),
        findsOneWidget,
      );

      // One tap has removed nothing.
      expect(find.text('5 total'), findsOneWidget);
    });

    testWidgets('backing out of the dialog changes nothing', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(_action('Cotton Daily Saree', Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductTile), findsNWidgets(5));
      expect(find.text('5 total'), findsOneWidget);
    });

    testWidgets('confirming removes it and moves the count', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(_action('Cotton Daily Saree', Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Cotton Daily Saree'), findsNothing);
      expect(find.byType(ProductTile), findsNWidgets(4));
      expect(find.text('4 total'), findsOneWidget);
    });

    testWidgets('undo puts it back where it was', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(_action('Cotton Daily Saree', Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      // Settle first: a dialog still animating out would swallow the tap on
      // the SnackBar behind it.
      await tester.pumpAndSettle();

      expect(find.text('Cotton Daily Saree deleted'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductTile), findsNWidgets(5));
      expect(find.text('5 total'), findsOneWidget);

      // Third again, not shuffled to the end.
      final names = tester
          .widgetList<ProductTile>(find.byType(ProductTile))
          .map((tile) => tile.product.name)
          .toList();
      expect(names[2], 'Cotton Daily Saree');
    });

    testWidgets('emptying the catalogue says so', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(
        _host(
          overrides: [productStoreProvider.overrideWith(_OneProductStore.new)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 total'), findsOneWidget);

      await tester.tap(_action('Only Saree', Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // An empty catalogue reads as empty, not as a blank screen.
      expect(find.text('No products yet.'), findsOneWidget);
      expect(find.text('0 total'), findsOneWidget);
      expect(find.byType(ProductTile), findsNothing);
    });
  });
}
