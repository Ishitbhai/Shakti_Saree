import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore/firestore_schema.dart';
import '../../models/support_ticket.dart';
import 'firestore_orders_repository.dart';

/// Reads the queries customers have sent in.
abstract interface class SupportRepository {
  /// Every query, newest first.
  Future<List<SupportTicket>> fetchTickets();
}

/// The in-memory sample has no customer queries, so there is nothing to
/// list and the section stays out of the way.
class InMemorySupportRepository implements SupportRepository {
  const InMemorySupportRepository();

  @override
  Future<List<SupportTicket>> fetchTickets() async => const [];
}

/// Serves the `support` collection, with each sender's name looked up from
/// `users`.
class FirestoreSupportRepository implements SupportRepository {
  const FirestoreSupportRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<List<SupportTicket>> fetchTickets() => guardFirestore(() async {
    final (tickets, users) = await (
      _db.collection(Fs.support).get(),
      _db.collection(Fs.users).get(),
    ).wait;
    final people = FirestoreOrdersRepository.usersById(users.docs);

    final list = [
      for (final doc in tickets.docs)
        () {
          final data = doc.data();
          final userId = Fs.stringOf(data[Fs.userId]);
          final name = Fs.stringOf(people[userId]?[Fs.name]);
          return SupportTicket(
            id: Fs.optionalString(data[Fs.supportId]) ?? doc.id,
            customer: name.isNotEmpty
                ? name
                : (userId.isEmpty ? 'Unknown customer' : userId),
            subject: Fs.stringOf(data[Fs.subject]),
            message: Fs.stringOf(data[Fs.message]),
            createdAt: Fs.dateOf(data[Fs.createdAt]),
          );
        }(),
    ];
    list.sort((a, b) {
      final at = a.createdAt, bt = b.createdAt;
      if (at == null || bt == null) return at == null ? 1 : -1;
      return bt.compareTo(at);
    });
    return list;
  });
}
