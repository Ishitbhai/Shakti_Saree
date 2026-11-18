import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../admin/data/api_exception.dart';
import '../../admin/data/firestore/firestore_schema.dart';
import '../models/shop_models.dart';

/// The customer's side of the database: the catalogue to browse, and their own
/// cart.
///
/// Streams rather than one-off reads, so a price or stock figure changed in the
/// admin panel is on the shopper's screen without anything being refreshed.
///
/// Every cart write finds its cart from whoever Firebase Authentication says
/// is signed in. No screen passes a user id in, so none of them can reach
/// somebody else's cart by mistake.
class ShopRepository {
  const ShopRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth? _auth;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(Fs.products);

  CollectionReference<Map<String, dynamic>> get _carts =>
      _db.collection(Fs.carts);

  CollectionReference<Map<String, dynamic>> get _cartItems =>
      _db.collection(Fs.cartItems);

  // -------------------------------------------------------------- catalogue
  Stream<List<ShopProduct>> watchProducts() => _products
      .snapshots()
      .map(
        (snapshot) =>
            [for (final doc in snapshot.docs) ShopProduct.fromDoc(doc)]
              // No creation date on a product, so the running id stands in
              // for one, as it does on the admin panel's list.
              ..sort((a, b) => a.productId.compareTo(b.productId)),
      )
      .worded;

  /// One product by its document id; null if there is no such document.
  Stream<ShopProduct?> watchProduct(String docId) => _products
      .doc(docId)
      .snapshots()
      .map((doc) => doc.exists ? ShopProduct.fromDoc(doc) : null)
      .worded;

  Stream<List<ShopCategory>> watchCategories() => _db
      .collection(Fs.categories)
      .snapshots()
      .map(
        (snapshot) =>
            [for (final doc in snapshot.docs) ShopCategory.fromDoc(doc)]
              ..sort(_oldestFirst),
      )
      .worded;

  /// The same order the admin panel lists them in: oldest first, the id
  /// breaking ties, and a category with no date ahead of the rest.
  static int _oldestFirst(ShopCategory a, ShopCategory b) {
    final (at, bt) = (a.createdAt, b.createdAt);
    if (at != null && bt != null && at != bt) return at.compareTo(bt);
    if ((at == null) != (bt == null)) return at == null ? -1 : 1;
    return a.id.compareTo(b.id);
  }

  // --------------------------------------------------------------- customer
  /// Their `users/{uid}` document's name, or blank for an account without
  /// one, such as one made in the Firebase console.
  Stream<String> watchCustomerName(String uid) => _db
      .collection(Fs.users)
      .doc(uid)
      .snapshots()
      .map((doc) => Fs.stringOf(doc.fields[Fs.name]))
      .worded;

  // ------------------------------------------------------------------- cart
  /// The `cart_id` of this customer's cart, or null until they have one.
  ///
  /// Filtered on `user_id` because the security rules insist on it: a query
  /// that could return someone else's cart is refused outright.
  Stream<String?> watchCartId(String uid) => _carts
      .where(Fs.userId, isEqualTo: uid)
      .limit(1)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.isEmpty ? null : _cartIdOf(snapshot.docs.first),
      )
      .worded;

  Stream<List<CartLine>> watchCartLines(String cartId) => _cartItems
      .where(Fs.cartId, isEqualTo: cartId)
      .snapshots()
      .map(
        (snapshot) => [for (final doc in snapshot.docs) CartLine.fromDoc(doc)],
      )
      .worded;

  /// Puts one of [product] in the signed-in customer's cart, on the line it
  /// already has if there is one.
  Future<void> addToCart(ShopProduct product) => _guard(() async {
    if (!product.inStock) {
      throw BadRequest(409, '${product.name} is out of stock.');
    }
    final cartId = await _ownCartId();

    final existing = await _cartItems
        .where(Fs.cartId, isEqualTo: cartId)
        .where(Fs.productId, isEqualTo: product.productId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      final line = CartLine.fromDoc(existing.docs.first);
      _requireStock(product, line.quantity + 1);
      await existing.docs.first.reference.update({
        Fs.quantity: FieldValue.increment(1),
      });
      return;
    }

    // Named after the cart and the product, so two quick taps land on one
    // line rather than making two. Encoded because a SKU is free text, and a
    // slash in a document id would read as a path.
    final id = '${cartId}_${Uri.encodeComponent(product.productId)}';
    await _cartItems.doc(id).set({
      Fs.cartItemId: id,
      Fs.cartId: cartId,
      Fs.productId: product.productId,
      Fs.quantity: 1,
    });
  });

  /// Only asking for more is held to the stock: a customer whose line is over
  /// what is left still has to be able to come down.
  Future<void> setQuantity(CartLine line, ShopProduct product, int quantity) =>
      _guard(() async {
        if (quantity > line.quantity) _requireStock(product, quantity);
        await _cartItems.doc(line.docId).update({Fs.quantity: quantity});
      });

  Future<void> removeLine(CartLine line) =>
      _guard(() => _cartItems.doc(line.docId).delete());

  /// Takes every line out. The `carts` document stays, ready for the next one.
  Future<void> clearCart(List<CartLine> lines) => _guard(() async {
    final batch = _db.batch();
    for (final line in lines) {
      batch.delete(_cartItems.doc(line.docId));
    }
    await batch.commit();
  });

  /// The signed-in customer's cart, made the first time they need one.
  Future<String> _ownCartId() async {
    final uid = _auth?.currentUser?.uid;
    if (uid == null) {
      throw const BadRequest(401, 'Please log in to use your cart.');
    }

    final found = await _carts.where(Fs.userId, isEqualTo: uid).limit(1).get();
    if (found.docs.isNotEmpty) return _cartIdOf(found.docs.first);

    // Named after the customer rather than the next CART_00n: the rules do
    // not let a customer read other carts to count them, and this way one
    // customer can only ever have one, however two taps happen to race.
    final id = 'CART_$uid';
    await _carts.doc(id).set({
      Fs.cartId: id,
      Fs.userId: uid,
      Fs.createdAt: FieldValue.serverTimestamp(),
    });
    return id;
  }

  static String _cartIdOf(DocumentSnapshot<Map<String, dynamic>> doc) {
    final stored = Fs.stringOf(doc.fields[Fs.cartId]);
    return stored.isEmpty ? doc.id : stored;
  }

  static void _requireStock(ShopProduct product, int quantity) {
    if (quantity > product.stock) {
      throw BadRequest(
        409,
        'Only ${product.stock} of ${product.name} left in stock.',
      );
    }
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseException catch (error) {
      throw shopFailureOf(error);
    }
  }
}

/// A Firestore failure in words for a shopper.
///
/// The shared wording for a refused request tells the reader to use an admin
/// account, which is no use to a customer.
ApiException shopFailureOf(FirebaseException error) => switch (error.code) {
  'permission-denied' || 'unauthenticated' => const BadRequest(
    403,
    'Please log in again to continue.',
  ),
  _ => apiExceptionFor(error),
};

extension _Worded<T> on Stream<T> {
  /// The stream with its Firestore failures turned into [ApiException]s, the
  /// only kind the screens know how to word.
  Stream<T> get worded => handleError(
    (Object error, StackTrace stack) => Error.throwWithStackTrace(
      shopFailureOf(error as FirebaseException),
      stack,
    ),
    test: (error) => error is FirebaseException,
  );
}
