import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_schema.dart';
import '../../models/support_ticket.dart';
import '../repositories/support_repository.dart';
import 'backend_providers.dart';

/// The customer-query source: Firestore's `support` collection when the app
/// has a database, nothing otherwise. Overridden in tests.
final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  if (db != null) return FirestoreSupportRepository(db);
  return const InMemorySupportRepository();
});

/// Every query customers have sent in, newest first, kept live so a new one
/// turns up while the screen is open.
final supportTicketsProvider = FutureProvider<List<SupportTicket>>((ref) {
  watchCollections(ref, const [Fs.support]);
  return ref.watch(supportRepositoryProvider).fetchTickets();
});
