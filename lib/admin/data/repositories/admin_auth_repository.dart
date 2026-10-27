import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../api_exception.dart';
import '../firestore/firestore_schema.dart';
import '../../models/admin_profile.dart';

/// Who is signed in to the admin panel.
class AdminSession {
  const AdminSession({required this.uid, required this.profile});

  /// Their Firebase Authentication uid — and the id of their `users`
  /// document, which is what the security rules look up to decide whether a
  /// write is an admin's.
  final String uid;

  final AdminProfile profile;
}

/// Signs an admin in with Firebase Authentication, and keeps everyone else
/// out.
///
/// A correct password is not enough: the account's `users/{uid}` document
/// has to say `user_type: 'admin'`. That is the same document the Firestore
/// rules check, so the panel never lets in someone the database would then
/// refuse.
class AdminAuthRepository {
  const AdminAuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Future<AdminSession> signIn({
    required String email,
    required String password,
  }) async {
    final UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw _signInFailure(error);
    }

    final user = credential.user!;
    try {
      final doc = await _db.collection(Fs.users).doc(user.uid).get();
      final data = doc.data();
      if (data == null ||
          Fs.stringOf(data[Fs.userType]).toLowerCase() != Fs.adminType) {
        throw const BadRequest(403, 'This account does not have admin access.');
      }
      return AdminSession(
        uid: user.uid,
        profile: profileOf(data, fallbackEmail: user.email ?? email),
      );
    } on FirebaseException catch (error) {
      await _auth.signOut();
      throw apiExceptionFor(error);
    } on ApiException {
      // Signed back out, so a refused account is not left half in.
      await _auth.signOut();
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// A `users` document as the profile screens see it.
  static AdminProfile profileOf(
    Map<String, dynamic> data, {
    String fallbackEmail = '',
  }) {
    final role = Fs.stringOf(data[Fs.userType]);
    final gender = Fs.stringOf(data[Fs.gender]).toLowerCase();
    return AdminProfile(
      name: Fs.stringOf(data[Fs.name]),
      email: Fs.optionalString(data[Fs.email]) ?? fallbackEmail,
      // 'admin' as stored; 'Admin' as a label.
      role: role.isEmpty ? '' : role[0].toUpperCase() + role.substring(1),
      mobile: Fs.stringOf(data[Fs.phone]),
      dateOfBirth: Fs.dateOf(data[Fs.dateOfBirth]),
      gender: Gender.values.where((g) => g.name == gender).firstOrNull,
    );
  }

  static ApiException _signInFailure(FirebaseAuthException error) {
    // A project where Authentication was never switched on answers every
    // sign-in like this; Android reports it as an internal error, so the
    // message is checked as well as the code.
    if (error.code == 'configuration-not-found' ||
        (error.message ?? '').contains('CONFIGURATION_NOT_FOUND')) {
      return const BadRequest(
        400,
        'Firebase Authentication is not set up for this project yet. '
        'Enable Email/Password sign-in in the Firebase console.',
      );
    }
    return _signInFailureByCode(error);
  }

  static ApiException _signInFailureByCode(
    FirebaseAuthException error,
  ) => switch (error.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-email' => const BadRequest(401, 'Incorrect email or password.'),
    'user-disabled' => const BadRequest(403, 'This account has been disabled.'),
    'too-many-requests' => const BadRequest(
      429,
      'Too many attempts. Please wait a moment and try again.',
    ),
    'network-request-failed' => const NetworkUnavailable(),
    'operation-not-allowed' => const BadRequest(
      400,
      'Email sign-in is not enabled for this Firebase project.',
    ),
    _ => UnknownApiException(error.message ?? 'Sign-in failed. Please retry.'),
  };
}
