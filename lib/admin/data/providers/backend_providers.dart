import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The database the admin panel reads and writes, or null to run on the
/// in-memory stores instead.
///
/// The one switch between the two. `main.dart` hands it the real Firestore;
/// the tests leave it alone and get the sample data, so none of them needs a
/// network or a Firebase project to run. Every repository provider reads
/// this and picks its implementation from it.
final firestoreProvider = Provider<FirebaseFirestore?>((ref) => null);

/// Firebase Authentication, or null alongside the in-memory stores — where
/// the admin login goes straight in, as it always has.
final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) => null);

/// Ticks each time a collection changes after it was first read.
///
/// Providers that read a collection watch this for it, so a write from
/// anywhere — this panel, the customer app placing an order, the console —
/// re-runs them without a screen having to invalidate anything. That is the
/// job the in-memory stores' own state does for the sample data.
///
/// The first snapshot is skipped: it is the data the provider is already
/// fetching, and counting it would read everything twice on every launch.
final collectionChangesProvider = StreamProvider.family<int, String>((
  ref,
  collection,
) {
  final db = ref.watch(firestoreProvider);
  if (db == null) return const Stream.empty();

  var changes = 0;
  return db.collection(collection).snapshots().skip(1).map((_) => ++changes);
});

/// Makes the calling provider re-run whenever any of [collections] changes.
void watchCollections(Ref ref, List<String> collections) {
  if (ref.watch(firestoreProvider) == null) return;
  for (final collection in collections) {
    ref.watch(collectionChangesProvider(collection));
  }
}
