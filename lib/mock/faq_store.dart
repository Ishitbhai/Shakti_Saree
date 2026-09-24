import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/support/faq.dart';
import '../core/errors/api_exception.dart';
import 'mock_data.dart';

/// The app's one copy of the help questions, on the same footing as the
/// order, product, category and profile stores.
///
/// The question is the identity, because that is what the list is read by and
/// what an edit is found by. Whether a given write is allowed — a question
/// already asked, an answer left blank — is the repository's business, not
/// this one's.
class FaqStore extends Notifier<List<Faq>> {
  @override
  List<Faq> build() => MockData.faqs();

  /// Everything the store holds.
  List<Faq> get faqs => List.unmodifiable(state);

  /// The stored entry, or a [NotFound] if nothing asks that.
  Faq find(String question) => state[_indexOf(question)];

  /// Whether [question] is already asked by something other than
  /// [exceptQuestion].
  ///
  /// The exception is what lets an edit keep its own wording without
  /// colliding with itself.
  bool isQuestionTaken(String question, {String? exceptQuestion}) => state.any(
    (faq) =>
        faq.question.toLowerCase() == question.toLowerCase() &&
        faq.question != exceptQuestion,
  );

  /// Adds an entry at the end of the list.
  Faq add(Faq faq) {
    state = [...state, faq];
    return faq;
  }

  /// Replaces the entry stored under [originalQuestion].
  ///
  /// The replacement may ask something different — rewording is an edit like
  /// any other — so the row is found by where it came from.
  Faq replace(String originalQuestion, Faq updated) {
    final index = _indexOf(originalQuestion);
    state = [...state]..[index] = updated;
    return updated;
  }

  /// Takes an entry out, answering with where it was so undo can put it back
  /// in place rather than on the end.
  ({Faq faq, int index}) remove(String question) {
    final index = _indexOf(question);
    final removed = state[index];
    state = [...state]..removeAt(index);
    return (faq: removed, index: index);
  }

  /// Puts a removed entry back where it was.
  void insert(int index, Faq faq) {
    final at = index.clamp(0, state.length);
    state = [...state]..insert(at, faq);
  }

  int _indexOf(String question) {
    final index = state.indexWhere(
      (candidate) => candidate.question == question,
    );
    if (index == -1) throw const NotFound();
    return index;
  }
}

/// The single help list, alive for as long as the app is.
final faqStoreProvider = NotifierProvider<FaqStore, List<Faq>>(FaqStore.new);
