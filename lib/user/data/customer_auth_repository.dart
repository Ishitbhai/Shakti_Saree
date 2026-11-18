import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../admin/data/api_exception.dart';
import '../../admin/data/firestore/firestore_schema.dart';
import '../../admin/data/repositories/admin_auth_repository.dart';
import 'shop_repository.dart';

/// Signs customers in and registers new ones.
///
/// Anyone may shop, with one exception: an admin belongs in the panel, so an
/// admin account is refused here just as a customer is refused at the admin
/// login. An account with no `users` document is treated as a customer.
class CustomerAuthRepository {
  const CustomerAuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Future<void> signIn({required String email, required String password}) async {
    final UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AdminAuthRepository.signInFailure(error);
    }

    try {
      final admin = await AdminAuthRepository(
        _auth,
        _db,
      ).sessionFor(credential.user!);
      if (admin != null) {
        throw const BadRequest(
          403,
          'This is an admin account. Please use Admin Login.',
        );
      }
    } on FirebaseException catch (error) {
      // Without the role there is no telling which side this account belongs on.
      await _auth.signOut();
      throw shopFailureOf(error);
    } on ApiException {
      await _auth.signOut();
      rethrow;
    }
  }

  /// Creates the account and its `users` document, or neither.
  ///
  /// The document's id is the account's uid, because that is where the
  /// security rules look for it, and `user_type` has to be 'customer' for them
  /// to allow it at all.
  Future<void> register({
    required String name,
    required String email,
    required String mobile,
    required String password,
  }) async {
    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw _registerFailure(error);
    }

    final user = credential.user!;
    try {
      await _db.collection(Fs.users).doc(user.uid).set({
        Fs.userId: user.uid,
        Fs.name: name,
        Fs.email: email,
        Fs.phone: mobile,
        Fs.address: '',
        Fs.status: Fs.activeStatus,
        Fs.userType: Fs.customerType,
        Fs.registeredAt: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      // Left in place, the half-made account would turn the customer's retry
      // into "that email is already in use", with no way forward.
      try {
        await user.delete();
      } on FirebaseException {
        // Nothing more can be done from here; they can still log in with it.
      }
      throw shopFailureOf(error);
    }

    // Creating an account signs it in, but registering goes on to the login
    // screen. Left signed in, the next launch would skip that login.
    await _auth.signOut();
  }

  Future<void> signOut() => _auth.signOut();

  /// [BadRequest] 409 is how the register screen knows to show the message
  /// under the email field.
  static ApiException _registerFailure(FirebaseAuthException error) =>
      switch (error.code) {
        'email-already-in-use' => const BadRequest(
          409,
          'An account with this email already exists. Please login instead.',
        ),
        'invalid-email' => const BadRequest(
          400,
          'Enter a valid email address.',
        ),
        'weak-password' => const BadRequest(
          400,
          'That password is too weak. Please choose a stronger one.',
        ),
        _ => AdminAuthRepository.signInFailure(error),
      };
}
