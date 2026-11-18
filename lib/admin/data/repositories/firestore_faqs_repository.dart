import 'package:cloud_firestore/cloud_firestore.dart';

import '../api_exception.dart';
import '../firestore/firestore_schema.dart';
import '../../models/faq.dart';
import 'faqs_repository.dart';

typedef _FaqDoc = QueryDocumentSnapshot<Map<String, dynamic>>;

/// Keeps the admin's help questions in the `support` collection, each question
/// in `subject` and its answer in `message`.
///
/// A query from a customer would carry a `user_id`. Nothing here shows or
/// changes one of those.
///
/// The screen knows an entry by its question, so that is what an edit or a
/// deletion finds the document by.
class FirestoreFaqsRepository implements FaqsRepository {
  const FirestoreFaqsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _support =>
      _db.collection(Fs.support);

  @override
  Future<List<Faq>> fetchFaqs() => guardFirestore(() async {
    final entries = _entriesIn((await _support.get()).docs)..sort(_oldestFirst);
    return [
      for (final doc in entries)
        // One made by hand in the console with nothing to ask is not listed.
        if (_questionOf(doc).isNotEmpty) _faqOf(doc),
    ];
  });

  @override
  Future<Faq> createFaq(Faq faq) => guardFirestore(() async {
    final entry = _required(faq);
    final all = (await _support.get()).docs;
    if (_isTaken(_entriesIn(all), entry.question)) throw _alreadyAnswered;

    await _support.add({
      // Numbered across the whole collection, customers' queries included.
      Fs.supportId: Fs.nextId('SUP', all.map(_idOf)),
      Fs.subject: entry.question,
      Fs.message: entry.answer,
      Fs.createdAt: FieldValue.serverTimestamp(),
    });
    return entry;
  });

  @override
  Future<Faq> updateFaq({required String originalQuestion, required Faq faq}) =>
      guardFirestore(() async {
        final entry = _required(faq);
        final entries = _entriesIn((await _support.get()).docs);
        final doc = _asking(entries, originalQuestion);
        // Only a new wording can collide. Correcting an answer always may.
        final reworded = entry.question != originalQuestion;
        if (reworded && _isTaken(entries, entry.question, except: doc)) {
          throw _alreadyAnswered;
        }

        await doc.reference.update({
          Fs.subject: entry.question,
          Fs.message: entry.answer,
        });
        return entry;
      });

  @override
  Future<RemovedFaq> deleteFaq(String question) => guardFirestore(() async {
    final entries = _entriesIn((await _support.get()).docs)..sort(_oldestFirst);
    final doc = _asking(entries, question);

    await doc.reference.delete();
    return RemovedFaq(
      faq: _faqOf(doc),
      index: entries.indexOf(doc),
      stored: (id: doc.id, data: doc.data()),
    );
  });

  @override
  Future<void> restoreFaq(RemovedFaq removed) => guardFirestore(() async {
    final all = (await _support.get()).docs;
    if (_isTaken(_entriesIn(all), removed.faq.question)) {
      throw const BadRequest(
        409,
        'That question is being asked again — it cannot be restored.',
      );
    }
    final stored = removed.stored;
    if (stored == null) {
      await createFaq(removed.faq);
      return;
    }
    // The same document with the same date, so it returns to the same place.
    // Its number comes back too, unless a newer entry has since taken it.
    final number = Fs.stringOf(stored.data[Fs.supportId]);
    final taken = all.map(_idOf).toSet();
    await _support.doc(stored.id).set({
      ...stored.data,
      if (number.isNotEmpty && taken.contains(number))
        Fs.supportId: Fs.nextId('SUP', taken),
    });
  });

  static const BadRequest _alreadyAnswered = BadRequest(
    409,
    'That question is already answered here.',
  );

  /// The admin's own entries among everything in the collection.
  static List<_FaqDoc> _entriesIn(List<_FaqDoc> docs) => [
    for (final doc in docs)
      if (!Fs.isCustomerQuery(doc.data())) doc,
  ];

  static String _questionOf(_FaqDoc doc) => Fs.stringOf(doc.data()[Fs.subject]);

  static String _idOf(_FaqDoc doc) => Fs.stringOf(doc.data()[Fs.supportId]);

  static Faq _faqOf(_FaqDoc doc) => Faq(
    question: _questionOf(doc),
    answer: Fs.stringOf(doc.data()[Fs.message]),
  );

  /// Oldest first, so a new question lands at the end of the list.
  ///
  /// A document written by hand with no `created_at` counts as the oldest. One
  /// whose date is still blank is a question just added, waiting for the
  /// server to confirm it, so it counts as the newest. The id breaks ties.
  static int _oldestFirst(_FaqDoc a, _FaqDoc b) {
    final byAge = _ageOf(a).compareTo(_ageOf(b));
    if (byAge != 0) return byAge;
    final at = Fs.dateOf(a.data()[Fs.createdAt]);
    final bt = Fs.dateOf(b.data()[Fs.createdAt]);
    if (at != null && bt != null && at != bt) return at.compareTo(bt);
    return _idOf(a).compareTo(_idOf(b));
  }

  /// 0 for never dated, 1 for dated, 2 for a date still on its way.
  static int _ageOf(_FaqDoc doc) {
    if (!doc.data().containsKey(Fs.createdAt)) return 0;
    return Fs.dateOf(doc.data()[Fs.createdAt]) == null ? 2 : 1;
  }

  /// The one document asking [question].
  ///
  /// Two asking the same thing can only be told apart in the database, so an
  /// edit or a deletion is refused rather than landing on the wrong one.
  static _FaqDoc _asking(List<_FaqDoc> docs, String question) {
    final asking = docs.where((doc) => _questionOf(doc) == question).toList();
    if (asking.isEmpty) throw const NotFound();
    if (asking.length > 1) {
      throw const BadRequest(
        409,
        'More than one entry asks this question. Remove the extra one from '
        'the database first.',
      );
    }
    return asking.single;
  }

  /// Case-blind, as the in-memory store is.
  static bool _isTaken(
    List<_FaqDoc> docs,
    String question, {
    _FaqDoc? except,
  }) => docs.any(
    (doc) =>
        doc.id != except?.id &&
        _questionOf(doc).toLowerCase() == question.toLowerCase(),
  );

  /// An entry with no question answers nothing, and one with no answer is
  /// worse than not being listed at all.
  static Faq _required(Faq faq) {
    final question = faq.question.trim();
    final answer = faq.answer.trim();
    if (question.isEmpty) {
      throw const BadRequest(400, 'An entry needs a question.');
    }
    if (answer.isEmpty) {
      throw const BadRequest(400, 'An entry needs an answer.');
    }
    return Faq(question: question, answer: answer);
  }
}
