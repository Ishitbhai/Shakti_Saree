import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mock/profile_store.dart';
import '../repositories/admin_auth_repository.dart';
import '../repositories/profile_repository.dart';
import 'backend_providers.dart';

/// The admin who signed in, or null before anyone has — and always null on
/// the in-memory stores, which have no sign-in.
class AdminSessionNotifier extends Notifier<AdminSession?> {
  @override
  AdminSession? build() => null;

  void start(AdminSession session) => state = session;

  void end() => state = null;
}

final adminSessionProvider =
    NotifierProvider<AdminSessionNotifier, AdminSession?>(
      AdminSessionNotifier.new,
    );

/// Firebase sign-in for the admin panel, or null on the in-memory stores,
/// where the login screen lets an admin straight in as it always has.
final adminAuthRepositoryProvider = Provider<AdminAuthRepository?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final db = ref.watch(firestoreProvider);
  if (auth == null || db == null) return null;
  return AdminAuthRepository(auth, db);
});

/// Where the profile form saves to.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final store = ref.watch(profileStoreProvider.notifier);
  final db = ref.watch(firestoreProvider);
  final session = ref.watch(adminSessionProvider);
  if (db == null || session == null) return InMemoryProfileRepository(store);
  return FirestoreProfileRepository(db, session.uid, store);
});
