import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_schema.dart';
import '../mock/faq_store.dart';
import '../../models/faq.dart';
import '../repositories/faqs_repository.dart';
import '../repositories/firestore_faqs_repository.dart';
import 'backend_providers.dart';

/// The help source: Firestore when the app has one, the in-memory sample
/// otherwise. Overridden in tests.
final faqsRepositoryProvider = Provider<FaqsRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  if (db != null) return FirestoreFaqsRepository(db);
  return InMemoryFaqsRepository(ref.watch(faqStoreProvider.notifier));
});

/// Every help question, newest last.
///
/// Watches the store, or the collection behind it, so an entry added, reworded
/// or deleted redraws the list without anyone telling it to.
final faqsProvider = FutureProvider<List<Faq>>((ref) {
  ref.watch(faqStoreProvider);
  watchCollections(ref, const [Fs.faqs]);
  return ref.watch(faqsRepositoryProvider).fetchFaqs();
});
