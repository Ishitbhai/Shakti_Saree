import 'package:cloud_firestore/cloud_firestore.dart';

import '../api_exception.dart';
import '../firestore/firestore_schema.dart';
import '../../models/faq.dart';
import 'faqs_repository.dart';

typedef _FaqDoc = QueryDocumentSnapshot<Map<String, dynamic>>;

/// Keeps the help questions in the `faqs` collection.
///
/// The screen knows an entry by its question, so that is what an edit or a
/// deletion finds the document by. Each one also carries a `faq_id`, as every
/// other collection carries its own business id.
class FirestoreFaqsRepository implements FaqsRepository {
  const FirestoreFaqsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _faqs =>
      _db.collection(Fs.faqs);

  @override
  Future<List<Faq>> fetchFaqs() => guardFirestore(() async {
    final docs = [...(await _faqs.get()).docs]..sort(_oldestFirst);
    return [
      for (final doc in docs)
        // One made by hand in the console with nothing to ask is not listed.
        if (_questionOf(doc).isNotEmpty) _faqOf(doc),
    ];
  });

  @override
  Future<Faq> createFaq(Faq faq) => guardFirestore(() async {
    final entry = _required(faq);
    final all = (await _faqs.get()).docs;
    if (_isTaken(all, entry.question)) throw _alreadyAnswered;

    await _faqs.add({
      Fs.faqId: Fs.nextId('FAQ', all.map(_idOf)),
      Fs.question: entry.question,
      Fs.answer: entry.answer,
      Fs.createdAt: FieldValue.serverTimestamp(),
    });
    return entry;
  });

  @override
  Future<Faq> updateFaq({required String originalQuestion, required Faq faq}) =>
      guardFirestore(() async {
        final entry = _required(faq);
        final all = (await _faqs.get()).docs;
        final doc = _asking(all, originalQuestion);
        if (_isTaken(all, entry.question, except: doc)) throw _alreadyAnswered;

        await doc.reference.update({
          Fs.question: entry.question,
          Fs.answer: entry.answer,
        });
        return entry;
      });

  @override
  Future<RemovedFaq> deleteFaq(String question) => guardFirestore(() async {
    final all = [...(await _faqs.get()).docs]..sort(_oldestFirst);
    final doc = _asking(all, question);

    await doc.reference.delete();
    return RemovedFaq(
      faq: _faqOf(doc),
      index: all.indexOf(doc),
      stored: (id: doc.id, data: doc.data()),
    );
  });

  @override
  Future<void> restoreFaq(RemovedFaq removed) => guardFirestore(() async {
    if (_isTaken((await _faqs.get()).docs, removed.faq.question)) {
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
    await _faqs.doc(stored.id).set(stored.data);
  });

  static const BadRequest _alreadyAnswered = BadRequest(
    409,
    'That question is already answered here.',
  );

  static String _questionOf(_FaqDoc doc) =>
      Fs.stringOf(doc.data()[Fs.question]);

  static String _idOf(_FaqDoc doc) => Fs.stringOf(doc.data()[Fs.faqId]);

  static Faq _faqOf(_FaqDoc doc) => Faq(
    question: _questionOf(doc),
    answer: Fs.stringOf(doc.data()[Fs.answer]),
  );

  /// Oldest first, so a new question lands at the end of the list. The id
  /// breaks ties, and one with no date at all goes ahead of the rest.
  static int _oldestFirst(_FaqDoc a, _FaqDoc b) {
    final at = Fs.dateOf(a.data()[Fs.createdAt]);
    final bt = Fs.dateOf(b.data()[Fs.createdAt]);
    if (at != null && bt != null && at != bt) return at.compareTo(bt);
    if ((at == null) != (bt == null)) return at == null ? -1 : 1;
    return _idOf(a).compareTo(_idOf(b));
  }

  static _FaqDoc _asking(List<_FaqDoc> docs, String question) {
    for (final doc in docs) {
      if (_questionOf(doc) == question) return doc;
    }
    throw const NotFound();
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
