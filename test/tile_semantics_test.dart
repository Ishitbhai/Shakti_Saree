import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shakti_saree/admin/categories/category.dart';
import 'package:shakti_saree/admin/categories/widgets/category_tile.dart';
import 'package:shakti_saree/admin/more/admin_profile.dart';
import 'package:shakti_saree/admin/more/widgets/gender_selector.dart';
import 'package:shakti_saree/admin/products/product.dart';
import 'package:shakti_saree/admin/products/widgets/product_tile.dart';
import 'package:shakti_saree/admin/shared/widgets/swatches.dart';
import 'package:shakti_saree/admin/support/faq.dart';
import 'package:shakti_saree/admin/support/widgets/faq_tile.dart';
import 'package:shakti_saree/core/theme/app_theme.dart';

/// The rows carry an edit and a delete button each, an open help question
/// carries the same two, and the profile form carries three gender buttons.
/// All of them have to reach a screen reader as controls of their own —
/// wrapping the lot in a MergeSemantics folds them into one node and leaves a
/// sentence with nothing to press.
///
/// Four screens have had this bug already, which is why the cases live
/// together: a new control that can be merged away belongs in here.
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

  testWidgets('an open help question keeps its actions reachable', (
    tester,
  ) async {
    _phone(tester);
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        FaqTile(
          faq: const Faq(
            question: 'How much is the delivery charge?',
            answer: 'Free on anything paid for up front.',
          ),
          isExpanded: true,
          onToggle: () {},
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    _expectOwnButton(tester, 'Edit How much is the delivery charge?');
    _expectOwnButton(tester, 'Delete How much is the delivery charge?');

    // And the question itself is the control that opened them, carrying the
    // state a sighted admin reads off the chevron.
    final question = tester.getSemantics(
      find.bySemanticsLabel('How much is the delivery charge?'),
    );
    expect(question.flagsCollection.isButton, isTrue);
    expect(question.flagsCollection.isExpanded, ui.Tristate.isTrue);

    handle.dispose();
  });

  testWidgets('the gender buttons are three nodes, not one sentence', (
    tester,
  ) async {
    _phone(tester);
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(GenderSelector(selected: Gender.male, onSelect: (_) {})),
    );
    await tester.pumpAndSettle();

    for (final gender in Gender.values) {
      _expectOwnButton(tester, gender.label);
    }

    // Which one is chosen is state a screen reader has to be able to hear,
    // and a maroon fill is not something it can see.
    for (final gender in Gender.values) {
      final node = tester.getSemantics(find.bySemanticsLabel(gender.label));
      expect(
        node.flagsCollection.isSelected,
        gender == Gender.male ? ui.Tristate.isTrue : ui.Tristate.isFalse,
        reason: gender.label,
      );
    }

    handle.dispose();
  });
}
