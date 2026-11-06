import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore/firestore_schema.dart';
import '../mock/profile_store.dart';
import '../../models/admin_profile.dart';

/// Saves the signed-in admin's own details.
abstract interface class ProfileRepository {
  /// Stores [profile] and answers with what was stored.
  Future<AdminProfile> saveProfile(AdminProfile profile);
}

/// Keeps the profile in the shared in-memory store.
class InMemoryProfileRepository implements ProfileRepository {
  const InMemoryProfileRepository(this._store);

  final ProfileStore _store;

  @override
  Future<AdminProfile> saveProfile(AdminProfile profile) async =>
      _store.save(profile);
}

/// Writes the profile to the admin's own `users/{uid}` document, then to
/// the store every screen reads it from.
///
/// The photo stays on the device: the project has no file storage set up,
/// and a picture as raw bytes does not belong in a Firestore document. The
/// email saved here is the one shown on the panel; the address the admin
/// signs in with is Firebase Authentication's, and changing that needs a
/// verification step this form does not have.
class FirestoreProfileRepository implements ProfileRepository {
  const FirestoreProfileRepository(this._db, this._uid, this._store);

  final FirebaseFirestore _db;
  final String _uid;
  final ProfileStore _store;

  @override
  Future<AdminProfile> saveProfile(AdminProfile profile) =>
      guardFirestore(() async {
        final dateOfBirth = profile.dateOfBirth;
        await _db.collection(Fs.users).doc(_uid).update({
          Fs.name: profile.name,
          Fs.email: profile.email,
          Fs.phone: profile.mobile,
          Fs.dateOfBirth: dateOfBirth == null
              ? FieldValue.delete()
              : Timestamp.fromDate(dateOfBirth),
          Fs.gender: profile.gender?.name ?? FieldValue.delete(),
        });
        return _store.save(profile);
      });
}
