import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shakti_saree/admin/categories/categories_providers.dart';
import 'package:shakti_saree/admin/categories/categories_screen.dart';
import 'package:shakti_saree/admin/categories/widgets/category_tile.dart';
import 'package:shakti_saree/admin/products/products_providers.dart';
import 'package:shakti_saree/core/theme/app_theme.dart';

Widget _host() => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light,
    home: const MediaQuery(
      data: MediaQueryData(padding: EdgeInsets.only(top: 47)),
      child: CategoriesScreen(),
    ),
  ),
);

void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// The row carrying a given category name.
Finder _tileFor(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(CategoryTile));

Finder _action(String name, IconData icon) =>
    find.descendant(of: _tileFor(name), matching: find.byIcon(icon));

ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(
      tester.element(find.byType(CategoriesScreen)),
      listen: false,
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the list', () {
    testWidgets('shows every grouping and how full it is', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      expect(find.text('Manage Categories'), findsOneWidget);
      expect(find.text('12 categories'), findsOneWidget);

      // Counted off the catalogue, not stored on the category: one sample
      // product sits in Banarasi, and none in Bridal Wear.
      expect(
        find.descendant(
          of: _tileFor('Banarasi'),
          matching: find.text('1 product'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _tileFor('Bridal Wear'),
          matching: find.text('0 products'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('says which are on offer', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: _tileFor('Kanjivaram'),
          matching: find.text('Hidden'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _tileFor('Banarasi'),
          matching: find.text('Active'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the count follows the catalogue', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // Delete the one Banarasi listing from the products side.
      final container = _containerOf(tester);
      await container.read(productsRepositoryProvider).deleteProduct('SS-1024');
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: _tileFor('Banarasi'),
          matching: find.text('0 products'),
        ),
        findsOneWidget,
      );
    });
  });

  group('adding', () {
    testWidgets('a new grouping lands on the list', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Add category'));
      await tester.pumpAndSettle();
      expect(find.text('New Category'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Tussar');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Category'));
      await tester.pumpAndSettle();

      expect(find.text('13 categories'), findsOneWidget);
      expect(_tileFor('Tussar'), findsOneWidget);
    });

    testWidgets('a name already in use is refused', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Add category'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Banarasi');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Category'));
      await tester.pumpAndSettle();

      // Still open, saying why, with the typed name intact.
      expect(
        find.text('There is already a Banarasi category.'),
        findsOneWidget,
      );
      expect(find.text('New Category'), findsOneWidget);
      // Nothing was added: the count behind the sheet has not moved.
      expect(find.text('12 categories'), findsOneWidget);
    });

    testWidgets('an empty name will not save', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Add category'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Add Category'),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('editing', () {
    testWidgets('a rename carries its products across', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(_action('Banarasi', Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Edit Category'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Banarasi Silk');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // The listing came with it, rather than being left pointing at a
      // category that no longer exists.
      expect(
        find.descendant(
          of: _tileFor('Banarasi Silk'),
          matching: find.text('1 product'),
        ),
        findsOneWidget,
      );

      final products = await _containerOf(
        tester,
      ).read(productsRepositoryProvider).fetchProducts();
      expect(
        products.firstWhere((p) => p.sku == 'SS-1024').category,
        'Banarasi Silk',
      );
    });

    testWidgets('hiding and showing again', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: _tileFor('Banarasi'),
          matching: find.byIcon(Icons.more_horiz),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hide from store'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: _tileFor('Banarasi'),
          matching: find.text('Hidden'),
        ),
        findsOneWidget,
      );
    });
  });

  group('deleting', () {
    testWidgets('an empty grouping goes, and undo brings it back', (
      tester,
    ) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // Bridal Wear holds nothing, so it may go.
      await tester.tap(_action('Bridal Wear', Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Delete this category?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('11 categories'), findsOneWidget);
      expect(find.text('Bridal Wear deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('12 categories'), findsOneWidget);
      // Back in its old place, sixth in the list.
      final names = tester
          .widgetList<CategoryTile>(find.byType(CategoryTile))
          .map((tile) => tile.listing.name)
          .toList();
      expect(names[5], 'Bridal Wear');
    });

    testWidgets('one that still holds listings is refused', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(_action('Banarasi', Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Still there, and the reason is on screen.
      expect(
        find.text(
          'Banarasi still holds 1 product. Move or delete those first.',
        ),
        findsOneWidget,
      );
      expect(find.text('12 categories'), findsOneWidget);
      expect(_tileFor('Banarasi'), findsOneWidget);
    });

    testWidgets('keeping it changes nothing', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(_action('Bridal Wear', Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();

      expect(find.text('12 categories'), findsOneWidget);
    });
  });

  group('the product form', () {
    test('is only offered the groupings on offer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final names = container.read(categoryNamesProvider);

      // Two of the twelve are seeded hidden, and nothing new should be
      // filed into one.
      expect(names, hasLength(10));
      expect(names, isNot(contains('Kanjivaram')));
      expect(names, contains('Banarasi'));
    });
  });
}
