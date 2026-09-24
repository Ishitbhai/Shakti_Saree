import '../../core/errors/api_exception.dart';
import '../../mock/faq_store.dart';
import 'faq.dart';

/// Reads and writes the help questions.
///
/// The support screen depends on this, never on a data source, so the
/// in-memory sample below can be swapped for an HTTP implementation without
/// the screen changing. Failures surface as `ApiException` from `core/errors`.
abstract interface class FaqsRepository {
  /// Every entry, in the order the screen lists them.
  Future<List<Faq>> fetchFaqs();

  /// Adds an entry. Rejects a question already asked.
  Future<Faq> createFaq(Faq faq);

  /// Saves an edited entry.
  ///
  /// [originalQuestion] identifies the row; [faq] may ask something
  /// different, since rewording a question is an ordinary edit.
  Future<Faq> updateFaq({required String originalQuestion, required Faq faq});

  /// Removes an entry, answering with enough to put it back.
  Future<RemovedFaq> deleteFaq(String question);

  /// Puts back an entry that was just removed, where it was.
  Future<void> restoreFaq(RemovedFaq removed);
}

/// An entry that has been deleted, and the position it held.
///
/// Carrying the position is what makes undo an undo: the row returns to where
/// it was rather than to the end of the list.
class RemovedFaq {
  const RemovedFaq({required this.faq, required this.index});

  final Faq faq;
  final int index;
}

/// Serves the help questions from the shared in-memory store.
///
/// Stands in until the backend exists. Holds no entries of its own — it is
/// handed the store the rest of the app reads from, and decides which writes
/// to it are allowed.
class InMemoryFaqsRepository implements FaqsRepository {
  const InMemoryFaqsRepository(this._store);

  final FaqStore _store;

  @override
  Future<List<Faq>> fetchFaqs() async => _store.faqs;

  @override
  Future<Faq> createFaq(Faq faq) async {
    _require(faq);
    if (_store.isQuestionTaken(faq.question)) {
      throw const BadRequest(409, 'That question is already answered here.');
    }
    return _store.add(faq);
  }

  @override
  Future<Faq> updateFaq({
    required String originalQuestion,
    required Faq faq,
  }) async {
    _require(faq);
    // Its own wording does not count against it, or an edit that only
    // changed the answer would be blocked by itself.
    if (_store.isQuestionTaken(
      faq.question,
      exceptQuestion: originalQuestion,
    )) {
      throw const BadRequest(409, 'That question is already answered here.');
    }
    return _store.replace(originalQuestion, faq);
  }

  @override
  Future<RemovedFaq> deleteFaq(String question) async {
    final removed = _store.remove(question);
    return RemovedFaq(faq: removed.faq, index: removed.index);
  }

  @override
  Future<void> restoreFaq(RemovedFaq removed) async {
    if (_store.isQuestionTaken(removed.faq.question)) {
      throw const BadRequest(
        409,
        'That question is being asked again — it cannot be restored.',
      );
    }
    _store.insert(removed.index, removed.faq);
  }

  /// An entry with no question answers nothing, and one with no answer is
  /// worse than not being listed at all.
  void _require(Faq faq) {
    if (faq.question.trim().isEmpty) {
      throw const BadRequest(400, 'An entry needs a question.');
    }
    if (faq.answer.trim().isEmpty) {
      throw const BadRequest(400, 'An entry needs an answer.');
    }
  }
}
