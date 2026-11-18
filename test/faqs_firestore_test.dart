import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/data/api_exception.dart';
import 'package:shakti_saree/admin/data/providers/backend_providers.dart';
import 'package:shakti_saree/admin/data/repositories/firestore_faqs_repository.dart';
import 'package:shakti_saree/admin/models/faq.dart';
import 'package:shakti_saree/admin/screens/help_support_screen.dart';
import 'package:shakti_saree/admin/styles/app_theme.dart';
import 'package:shakti_saree/admin/widgets/common/labelled_field.dart';
import 'package:shakti_saree/admin/widgets/support/faq_tile.dart';

const _shipping = Faq(
  question: 'Do you ship abroad?',
  answer: 'Not yet, orders go to Indian addresses only.',
);
const _returns = Faq(
  question: 'Can I return a saree?',
  answer: 'Yes, within seven days of delivery.',
);

Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _docs(
  FakeFirebaseFirestore db,
) async => (await db.collection('support').get()).docs;

Matcher _refusedWith(int code) => throwsA(
  isA<BadRequest>().having((error) => error.statusCode, 'statusCode', code),
);

void main() {
  group('the repository', () {
    late FakeFirebaseFirestore db;
    late FirestoreFaqsRepository repository;

    setUp(() {
      db = FakeFirebaseFirestore();
      repository = FirestoreFaqsRepository(db);
    });

    test('has nothing to list until something is added', () async {
      expect(await repository.fetchFaqs(), isEmpty);
    });

    test('stores a new question in support, as subject and message', () async {
      await repository.createFaq(_shipping);

      final stored = (await _docs(db)).single.data();
      expect(stored['support_id'], 'SUP_001');
      expect(stored['subject'], _shipping.question);
      expect(stored['message'], _shipping.answer);
      expect(stored['created_at'], isA<Timestamp>());

      final listed = (await repository.fetchFaqs()).single;
      expect(listed.question, _shipping.question);
      expect(listed.answer, _shipping.answer);
    });

    test('numbers each one after the highest', () async {
      await repository.createFaq(_shipping);
      await repository.createFaq(_returns);

      expect((await _docs(db)).map((doc) => doc.data()['support_id']), {
        'SUP_001',
        'SUP_002',
      });
    });

    test('stores what was typed without the stray spaces', () async {
      await repository.createFaq(
        const Faq(question: '  Do you ship abroad?  ', answer: '  Not yet.  '),
      );

      final stored = (await _docs(db)).single.data();
      expect(stored['subject'], 'Do you ship abroad?');
      expect(stored['message'], 'Not yet.');
    });

    test('refuses a question already asked, in any case', () async {
      await repository.createFaq(_shipping);

      await expectLater(
        repository.createFaq(
          const Faq(question: 'DO YOU SHIP ABROAD?', answer: 'Yes.'),
        ),
        _refusedWith(409),
      );
      expect(await _docs(db), hasLength(1));
    });

    test('refuses half an entry', () async {
      await expectLater(
        repository.createFaq(const Faq(question: '  ', answer: 'An answer')),
        _refusedWith(400),
      );
      await expectLater(
        repository.createFaq(const Faq(question: 'A question', answer: ' ')),
        _refusedWith(400),
      );
      expect(await _docs(db), isEmpty);
    });

    test('lists the oldest first', () async {
      Timestamp at(int day) => Timestamp.fromDate(DateTime.utc(2026, 11, day));
      await db.collection('support').doc('b').set({
        'support_id': 'SUP_002',
        'subject': 'Newer',
        'message': 'B',
        'created_at': at(9),
      });
      await db.collection('support').doc('a').set({
        'support_id': 'SUP_001',
        'subject': 'Older',
        'message': 'A',
        'created_at': at(2),
      });

      expect((await repository.fetchFaqs()).map((faq) => faq.question), [
        'Older',
        'Newer',
      ]);
    });

    test('lists one with no date yet at the end', () async {
      await db.collection('support').doc('pending').set({
        'support_id': 'SUP_002',
        'subject': 'Just added',
        'message': 'B',
        'created_at': null,
      });
      await db.collection('support').doc('dated').set({
        'support_id': 'SUP_001',
        'subject': 'Already there',
        'message': 'A',
        'created_at': Timestamp.fromDate(DateTime.utc(2026, 11, 2)),
      });

      expect((await repository.fetchFaqs()).map((faq) => faq.question), [
        'Already there',
        'Just added',
      ]);
    });

    test('a new question lands after one written by hand', () async {
      await db.collection('support').doc('byHand').set({
        'subject': 'this is question',
        'message': 'this is an answer',
      });

      await repository.createFaq(_shipping);
      await repository.createFaq(_returns);

      expect((await repository.fetchFaqs()).map((faq) => faq.question), [
        'this is question',
        _shipping.question,
        _returns.question,
      ]);
    });

    test('a change of case may not land on a near duplicate', () async {
      await db.collection('support').doc('lower').set({
        'subject': 'do you ship abroad?',
        'message': 'Old',
      });
      await db.collection('support').doc('upper').set({
        'subject': 'DO YOU SHIP ABROAD?',
        'message': 'Other',
      });

      await expectLater(
        repository.updateFaq(
          originalQuestion: 'do you ship abroad?',
          faq: const Faq(question: 'DO YOU SHIP ABROAD?', answer: 'Old'),
        ),
        _refusedWith(409),
      );

      final stored = await db.collection('support').doc('lower').get();
      expect(stored.data()?['subject'], 'do you ship abroad?');
    });

    test('a question on its own may change its case', () async {
      await repository.createFaq(_shipping);

      await repository.updateFaq(
        originalQuestion: _shipping.question,
        faq: _shipping.copyWith(question: 'DO YOU SHIP ABROAD?'),
      );

      expect((await _docs(db)).single.data()['subject'], 'DO YOU SHIP ABROAD?');
    });

    test('will not guess between two entries asking the same', () async {
      for (final id in ['one', 'two']) {
        await db.collection('support').doc(id).set({
          'subject': 'Do you ship abroad?',
          'message': 'Answer in $id',
        });
      }

      await expectLater(
        repository.deleteFaq('Do you ship abroad?'),
        _refusedWith(409),
      );
      await expectLater(
        repository.updateFaq(
          originalQuestion: 'Do you ship abroad?',
          faq: _shipping.copyWith(answer: 'Changed'),
        ),
        _refusedWith(409),
      );

      final answers = (await _docs(db)).map((doc) => doc.data()['message']);
      expect(answers, unorderedEquals(['Answer in one', 'Answer in two']));
    });

    test('an answer can be corrected beside a near duplicate', () async {
      await db.collection('support').doc('lower').set({
        'subject': 'Do you ship abroad?',
        'message': 'Old',
      });
      await db.collection('support').doc('upper').set({
        'subject': 'DO YOU SHIP ABROAD?',
        'message': 'Other',
      });

      await repository.updateFaq(
        originalQuestion: 'Do you ship abroad?',
        faq: const Faq(question: 'Do you ship abroad?', answer: 'Corrected'),
      );

      final stored = await db.collection('support').doc('lower').get();
      expect(stored.data()?['message'], 'Corrected');
    });

    test('leaves out a document with nothing to ask', () async {
      await db.collection('support').doc('blank').set({'message': 'Orphaned'});

      expect(await repository.fetchFaqs(), isEmpty);
    });

    test('an edit changes the same document', () async {
      await repository.createFaq(_shipping);
      final before = (await _docs(db)).single;

      await repository.updateFaq(
        originalQuestion: _shipping.question,
        faq: const Faq(question: 'Do you deliver abroad?', answer: 'No.'),
      );

      final after = (await _docs(db)).single;
      expect(after.id, before.id);
      expect(after.data()['support_id'], 'SUP_001');
      expect(after.data()['created_at'], before.data()['created_at']);
      expect(after.data()['subject'], 'Do you deliver abroad?');
      expect(after.data()['message'], 'No.');
    });

    test('an edit may keep its own question', () async {
      await repository.createFaq(_shipping);

      await repository.updateFaq(
        originalQuestion: _shipping.question,
        faq: _shipping.copyWith(answer: 'A better answer.'),
      );

      expect((await _docs(db)).single.data()['message'], 'A better answer.');
    });

    test('an edit may not take another question', () async {
      await repository.createFaq(_shipping);
      await repository.createFaq(_returns);

      await expectLater(
        repository.updateFaq(
          originalQuestion: _returns.question,
          faq: _returns.copyWith(question: _shipping.question),
        ),
        _refusedWith(409),
      );
    });

    test('something no longer there is a 404', () async {
      await expectLater(
        repository.updateFaq(originalQuestion: 'Gone', faq: _shipping),
        throwsA(isA<NotFound>()),
      );
      await expectLater(repository.deleteFaq('Gone'), throwsA(isA<NotFound>()));
    });

    test('deleting removes the document', () async {
      await repository.createFaq(_shipping);

      await repository.deleteFaq(_shipping.question);

      expect(await _docs(db), isEmpty);
    });

    test('undo brings back the same document, in its place', () async {
      Timestamp at(int day) => Timestamp.fromDate(DateTime.utc(2026, 11, day));
      for (final (index, name) in ['First', 'Second', 'Third'].indexed) {
        await db.collection('support').doc('doc$index').set({
          'support_id': 'SUP_00${index + 1}',
          'subject': name,
          'message': 'An answer',
          'created_at': at(index + 1),
        });
      }
      final before = (await db.collection('support').doc('doc1').get()).data();

      final removed = await repository.deleteFaq('Second');
      expect(removed.index, 1);
      await repository.restoreFaq(removed);

      final after = await db.collection('support').doc('doc1').get();
      expect(after.data(), before);
      expect((await repository.fetchFaqs()).map((faq) => faq.question), [
        'First',
        'Second',
        'Third',
      ]);
    });

    test('undo takes a new number if its old one was reused', () async {
      await repository.createFaq(_shipping);
      await repository.createFaq(_returns);
      final removed = await repository.deleteFaq(_returns.question);
      await repository.createFaq(
        const Faq(question: 'Do you gift wrap?', answer: 'On request.'),
      );

      await repository.restoreFaq(removed);

      expect(
        (await _docs(db)).map((doc) => doc.data()['support_id']),
        unorderedEquals(['SUP_001', 'SUP_002', 'SUP_003']),
      );
    });

    test('undo is refused once the question is asked again', () async {
      await repository.createFaq(_shipping);
      final removed = await repository.deleteFaq(_shipping.question);
      await repository.createFaq(_shipping);

      await expectLater(repository.restoreFaq(removed), _refusedWith(409));
      expect(await _docs(db), hasLength(1));
    });

    group('a document written by hand with only the two fields', () {
      setUp(
        () => db.collection('support').doc('byHand').set({
          'subject': 'this is question',
          'message': 'this is an answer',
        }),
      );

      test('is listed', () async {
        final listed = (await repository.fetchFaqs()).single;

        expect(listed.question, 'this is question');
        expect(listed.answer, 'this is an answer');
      });

      test('can be corrected, and gains no other field', () async {
        await repository.updateFaq(
          originalQuestion: 'this is question',
          faq: const Faq(question: 'this is question', answer: 'a better one'),
        );

        final stored = await db.collection('support').doc('byHand').get();
        expect(stored.data(), {
          'subject': 'this is question',
          'message': 'a better one',
        });
      });

      test('comes back whole after a delete and undo', () async {
        final removed = await repository.deleteFaq('this is question');
        await repository.restoreFaq(removed);

        final stored = await db.collection('support').doc('byHand').get();
        expect(stored.data(), {
          'subject': 'this is question',
          'message': 'this is an answer',
        });
      });
    });

    group('beside a query from a customer', () {
      const query = {
        'support_id': 'SUP_007',
        'user_id': 'testCustomerUid0004',
        'subject': 'Do you ship abroad?',
        'message': 'I live in Dubai.',
      };

      setUp(() => db.collection('support').doc('query').set(query));

      test('does not list it', () async {
        expect(await repository.fetchFaqs(), isEmpty);
      });

      test('numbers on from it', () async {
        await repository.createFaq(_returns);

        expect(
          (await _docs(db)).map((doc) => doc.data()['support_id']),
          unorderedEquals(['SUP_007', 'SUP_008']),
        );
      });

      test('may answer the same subject', () async {
        await repository.createFaq(_shipping);

        expect((await repository.fetchFaqs()).single.answer, _shipping.answer);
      });

      test('cannot change or remove it', () async {
        await expectLater(
          repository.updateFaq(
            originalQuestion: query['subject']!,
            faq: _shipping,
          ),
          throwsA(isA<NotFound>()),
        );
        await expectLater(
          repository.deleteFaq(query['subject']!),
          throwsA(isA<NotFound>()),
        );

        final stored = await db.collection('support').doc('query').get();
        expect(stored.data(), query);
      });
    });
  });

  group('the screen', () {
    late FakeFirebaseFirestore db;

    Widget app() => ProviderScope(
      overrides: [firestoreProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const HelpSupportScreen(),
      ),
    );

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
    }

    Finder field(String label) => find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(LabelledField),
      ),
      matching: find.byType(TextField),
    );

    Future<void> addFromTheScreen(WidgetTester tester, Faq faq) async {
      await tester.tap(find.bySemanticsLabel('Add question'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Subject'), faq.question);
      await tester.enterText(field('Message'), faq.answer);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Question'));
      await tester.pumpAndSettle();
    }

    setUp(() => db = FakeFirebaseFirestore());

    testWidgets('shows no sample questions on an empty database', (
      tester,
    ) async {
      await open(tester);

      expect(find.byType(FaqTile), findsNothing);
      expect(find.text('No questions answered yet.'), findsOneWidget);
    });

    testWidgets('the form asks for a subject and a message', (tester) async {
      await open(tester);

      await tester.tap(find.bySemanticsLabel('Add question'));
      await tester.pumpAndSettle();

      expect(find.text('Subject'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
      expect(find.text('Question'), findsNothing);
      expect(find.text('Answer'), findsNothing);
    });

    testWidgets('lists the admin question and no customer query', (
      tester,
    ) async {
      await db.collection('support').doc('query').set({
        'user_id': 'testCustomerUid0004',
        'subject': 'Where is my parcel?',
        'message': 'It has been a week.',
      });
      await db.collection('support').doc('byHand').set({
        'subject': 'this is question',
        'message': 'this is an answer',
      });

      await open(tester);

      expect(find.textContaining('Customer Queries'), findsNothing);
      expect(find.text('Where is my parcel?'), findsNothing);
      expect(find.text('this is question'), findsOneWidget);
      expect(find.byType(FaqTile), findsOneWidget);
    });

    testWidgets('a question added here goes to the database', (tester) async {
      await open(tester);

      await addFromTheScreen(tester, _shipping);

      final stored = (await _docs(db)).single.data();
      expect(stored['subject'], _shipping.question);
      expect(stored['message'], _shipping.answer);
      expect(find.text(_shipping.question), findsOneWidget);
    });

    testWidgets('it is still there after the app starts again', (tester) async {
      await open(tester);
      await addFromTheScreen(tester, _shipping);

      // A new scope holds nothing over from the last one but the database.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text(_shipping.question), findsOneWidget);
    });

    testWidgets('an edit made here reaches the database', (tester) async {
      await FirestoreFaqsRepository(db).createFaq(_shipping);
      await open(tester);

      await tester.tap(find.text(_shipping.question));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Edit ${_shipping.question}'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Message'), 'A better answer.');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect((await _docs(db)).single.data()['message'], 'A better answer.');
      expect(find.text('A better answer.'), findsOneWidget);
    });

    testWidgets('deleting here removes it, and undo puts it back', (
      tester,
    ) async {
      await FirestoreFaqsRepository(db).createFaq(_shipping);
      final id = (await _docs(db)).single.id;
      await open(tester);

      await tester.tap(find.text(_shipping.question));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Delete ${_shipping.question}'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(await _docs(db), isEmpty);
      expect(find.text(_shipping.question), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect((await _docs(db)).single.id, id);
      expect(find.text(_shipping.question), findsOneWidget);
    });

    testWidgets('a question added elsewhere turns up while it is open', (
      tester,
    ) async {
      await open(tester);

      await FirestoreFaqsRepository(db).createFaq(_returns);
      await tester.pumpAndSettle();

      expect(find.text(_returns.question), findsOneWidget);
    });

    testWidgets('a repeated question says why and keeps the typing', (
      tester,
    ) async {
      await FirestoreFaqsRepository(db).createFaq(_shipping);
      await open(tester);

      await addFromTheScreen(tester, _shipping);

      expect(
        find.text('That question is already answered here.'),
        findsOneWidget,
      );
      expect(await _docs(db), hasLength(1));
    });
  });
}
