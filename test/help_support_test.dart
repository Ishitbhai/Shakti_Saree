import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/more/more_screen.dart';
import 'package:shakti_saree/admin/shared/widgets/labelled_field.dart';
import 'package:shakti_saree/admin/support/faq.dart';
import 'package:shakti_saree/admin/support/faqs_providers.dart';
import 'package:shakti_saree/admin/support/help_support_screen.dart';
import 'package:shakti_saree/admin/support/widgets/faq_tile.dart';
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

/// Tall enough that the whole list builds — a ListView only makes what fits.
void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// The first question in the sample list, and the one the design shows open.
const String _tracking = 'How to see status of my orders?';
const String _trackingAnswer =
    'Go to Profile > My Orders. Every order there carries its live status '
    'and a tracking link. Tracking starts working about 24 hours after the '
    'order is placed.';

const String _delivery = 'How much is the delivery charge?';

/// The card carrying a given question.
Finder _tileFor(String question) =>
    find.ancestor(of: find.text(question), matching: find.byType(FaqTile));

/// The text input under a given form label.
Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(LabelledField)),
  matching: find.byType(TextField),
);

/// A button inside the confirmation dialog, where the card underneath has one
/// saying the same word.
Finder _inDialog(String label) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(label));

ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );

Future<List<Faq>> _stored(WidgetTester tester) =>
    _containerOf(tester).read(faqsRepositoryProvider).fetchFaqs();

void main() {
  Future<void> openSupport(WidgetTester tester) async {
    _tallPhone(tester);
    await tester.pumpWidget(_host(const HelpSupportScreen()));
    await tester.pumpAndSettle();
  }

  /// Opens the answer to a question.
  Future<void> open(WidgetTester tester, String question) async {
    await tester.tap(find.text(question));
    await tester.pumpAndSettle();
  }

  group('the page', () {
    testWidgets('the More row opens it', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host(const MoreScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Help & Support'));
      await tester.pumpAndSettle();

      expect(find.byType(HelpSupportScreen), findsOneWidget);
    });

    testWidgets('says whose panel it is and lists the questions', (
      tester,
    ) async {
      await openSupport(tester);

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Guides for managing your panel'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('Frequently Asked Questions'), findsOneWidget);

      expect(find.byType(FaqTile), findsNWidgets(6));
      expect(find.text(_tracking), findsOneWidget);
      expect(find.text(_delivery), findsOneWidget);
    });

    testWidgets('opens closed, so the page is a list of questions', (
      tester,
    ) async {
      await openSupport(tester);

      expect(find.text(_trackingAnswer), findsNothing);
    });
  });

  group('reading an answer', () {
    testWidgets('a question opens on being tapped', (tester) async {
      await openSupport(tester);
      await open(tester, _tracking);

      expect(find.text(_trackingAnswer), findsOneWidget);
    });

    testWidgets('tapping the open one closes it again', (tester) async {
      await openSupport(tester);
      await open(tester, _tracking);
      await open(tester, _tracking);

      expect(find.text(_trackingAnswer), findsNothing);
    });

    testWidgets('only one answer is open at a time', (tester) async {
      await openSupport(tester);
      await open(tester, _tracking);
      await open(tester, _delivery);

      expect(find.text(_trackingAnswer), findsNothing);
      expect(
        find.textContaining('Delivery is ₹99 on Cash on Delivery'),
        findsOneWidget,
      );
    });
  });

  group('adding', () {
    Future<void> add(
      WidgetTester tester, {
      required String question,
      required String answer,
    }) async {
      await tester.tap(find.bySemanticsLabel('Add question'));
      await tester.pumpAndSettle();

      await tester.enterText(_field('Question'), question);
      await tester.enterText(_field('Answer'), answer);
      await tester.pumpAndSettle();
    }

    testWidgets('a new question lands on the list, open', (tester) async {
      await openSupport(tester);
      await add(
        tester,
        question: 'Do you ship abroad?',
        answer: 'Not yet — orders go to Indian addresses only.',
      );

      await tester.tap(find.text('Add Question'));
      await tester.pumpAndSettle();

      expect(find.byType(FaqTile), findsNWidgets(7));
      expect(find.text('Do you ship abroad?'), findsOneWidget);
      // Opened on arrival, so what was just written can be read back.
      expect(
        find.text('Not yet — orders go to Indian addresses only.'),
        findsOneWidget,
      );
      expect(await _stored(tester), hasLength(7));
    });

    testWidgets('half an entry cannot be added', (tester) async {
      await openSupport(tester);
      await add(tester, question: 'Do you ship abroad?', answer: '');

      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Add Question'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('a question already answered is refused, keeping the typing', (
      tester,
    ) async {
      await openSupport(tester);
      await add(tester, question: _tracking, answer: 'Somewhere else.');

      await tester.tap(find.text('Add Question'));
      await tester.pumpAndSettle();

      expect(
        find.text('That question is already answered here.'),
        findsOneWidget,
      );
      // Still on the sheet, with what was typed still in it.
      expect(find.text('Add Question'), findsOneWidget);
      expect(await _stored(tester), hasLength(6));
    });
  });

  group('editing', () {
    testWidgets('an answer can be rewritten', (tester) async {
      await openSupport(tester);
      await open(tester, _delivery);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(_field('Answer'), 'Delivery is free this month.');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Delivery is free this month.'), findsOneWidget);
      expect(find.byType(FaqTile), findsNWidgets(6));
    });

    testWidgets('a reworded question stays open on its answer', (tester) async {
      await openSupport(tester);
      await open(tester, _delivery);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(_field('Question'), 'What does delivery cost?');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('What does delivery cost?'), findsOneWidget);
      expect(find.text(_delivery), findsNothing);
      expect(
        find.textContaining('Delivery is ₹99 on Cash on Delivery'),
        findsOneWidget,
      );
    });
  });

  group('deleting', () {
    Future<void> tapDelete(WidgetTester tester, String question) async {
      await tester.tap(
        find.descendant(of: _tileFor(question), matching: find.text('Delete')),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('asks first, and keeping it changes nothing', (tester) async {
      await openSupport(tester);
      await open(tester, _delivery);
      await tapDelete(tester, _delivery);

      expect(find.text('Delete this question?'), findsOneWidget);
      await tester.tap(_inDialog('Keep it'));
      await tester.pumpAndSettle();

      expect(find.byType(FaqTile), findsNWidgets(6));
      expect(await _stored(tester), hasLength(6));
    });

    testWidgets('confirming removes it', (tester) async {
      await openSupport(tester);
      await open(tester, _delivery);
      await tapDelete(tester, _delivery);
      await tester.tap(_inDialog('Delete'));
      await tester.pumpAndSettle();

      expect(find.text(_delivery), findsNothing);
      expect(find.byType(FaqTile), findsNWidgets(5));
      expect(find.text('Question deleted'), findsOneWidget);
    });

    testWidgets('undo puts it back where it was', (tester) async {
      await openSupport(tester);
      await open(tester, _delivery);
      await tapDelete(tester, _delivery);
      await tester.tap(_inDialog('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      final stored = await _stored(tester);
      expect(stored, hasLength(6));
      // Back in its old place, not on the end.
      expect(stored[3].question, _delivery);
    });
  });
}
