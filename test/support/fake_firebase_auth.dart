import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Just enough of Firebase Authentication for the customer screens: accounts
/// held in memory, failing with the codes the real one fails with, and sign-in
/// state reported the way the real one reports it. Nothing touches the network.
class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  final Map<String, ({String password, String uid})> _accounts = {};
  final StreamController<User?> _changes = StreamController<User?>.broadcast();
  User? _current;

  /// Set to hold the next sign-in open, to see what the screen shows meanwhile.
  Completer<void>? signInGate;

  /// Set to have [authStateChanges] never answer, to see what waits on it.
  bool stuck = false;

  /// How many times something asked to sign out. A session only ends when
  /// someone logs out, so this is how a test notices anything else doing it.
  int signOutCalls = 0;

  void addAccount(String email, String password, {required String uid}) {
    _accounts[email] = (password: password, uid: uid);
  }

  bool hasAccount(String email) => _accounts.containsKey(email);

  /// Signs an existing session in without going through a screen.
  void signInAs(String uid, {String email = 'someone@example.com'}) {
    _setUser(_FakeUser(this, uid, email));
  }

  void _setUser(User? user) {
    _current = user;
    _changes.add(user);
  }

  @override
  User? get currentUser => _current;

  @override
  Stream<User?> authStateChanges() async* {
    if (stuck) await Completer<void>().future;
    yield _current;
    yield* _changes.stream;
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await signInGate?.future;
    final account = _accounts[email];
    if (account == null || account.password != password) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    final user = _FakeUser(this, account.uid, email);
    _setUser(user);
    return _FakeCredential(user);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_accounts.containsKey(email)) {
      throw FirebaseAuthException(code: 'email-already-in-use');
    }
    final uid = 'uid_${_accounts.length + 1}';
    _accounts[email] = (password: password, uid: uid);
    final user = _FakeUser(this, uid, email);
    _setUser(user);
    return _FakeCredential(user);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _setUser(null);
  }
}

class _FakeUser extends Fake implements User {
  _FakeUser(this._auth, this.uid, this.email);

  final FakeFirebaseAuth _auth;

  @override
  final String uid;

  @override
  final String email;

  @override
  Future<void> delete() async {
    _auth._accounts.remove(email);
    _auth._setUser(null);
  }
}

class _FakeCredential extends Fake implements UserCredential {
  _FakeCredential(this.user);

  @override
  final User user;
}
