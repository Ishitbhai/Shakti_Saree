import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mock/faq_store.dart';
import 'faq.dart';
import 'faqs_repository.dart';

/// The help source. Overridden in tests and, later, swapped for the HTTP
/// implementation in one place.
final faqsRepositoryProvider = Provider<FaqsRepository>(
  (ref) => InMemoryFaqsRepository(ref.watch(faqStoreProvider.notifier)),
);

/// Every help question, newest last.
///
/// Watches the store, so an entry added, reworded or deleted redraws the list
/// without anyone telling it to.
final faqsProvider = FutureProvider<List<Faq>>((ref) {
  ref.watch(faqStoreProvider);
  return ref.watch(faqsRepositoryProvider).fetchFaqs();
});
