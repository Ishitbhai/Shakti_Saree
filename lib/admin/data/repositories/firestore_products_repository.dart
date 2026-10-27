import 'package:cloud_firestore/cloud_firestore.dart';

import '../api_exception.dart';
import '../firestore/firestore_schema.dart';
import '../../models/product.dart';
import '../../styles/swatches.dart';
import 'products_repository.dart';

/// Serves the catalogue from the `products` collection.
///
/// The SKU the screens work with is the document's `product_id`; the
/// document id itself is Firestore's own and is never shown. A product names
/// its category by `category_id`, so every read looks the categories up to
/// turn that into the name the screens file products under, and every write
/// turns it back.
class FirestoreProductsRepository implements ProductsRepository {
  const FirestoreProductsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(Fs.products);

  @override
  Future<List<Product>> fetchProducts() => guardFirestore(() async {
    final (products, names) = await (_products.get(), _categoryNames()).wait;

    // No creation date on a product, so the running id stands in for one:
    // PROD_001 before PROD_002 keeps the list reading newest last.
    return [for (final doc in products.docs) productOf(doc, names)]
      ..sort((a, b) => a.sku.compareTo(b.sku));
  });

  @override
  Future<Product> createProduct(Product product) => guardFirestore(() async {
    _require(product);
    if (await _find(product.sku) != null) {
      throw BadRequest(409, 'SKU ${product.sku} is already in use.');
    }
    await _products.add({
      Fs.productId: product.sku,
      ...await _fieldsOf(product),
      if (product.image != null) Fs.image: product.image!,
    });
    return product;
  });

  @override
  Future<Product> updateProduct({
    required String originalSku,
    required Product product,
  }) => guardFirestore(() async {
    _require(product);
    final doc = await _findOr404(originalSku);
    final renumbered = product.sku != originalSku;
    if (renumbered && await _find(product.sku) != null) {
      throw BadRequest(409, 'SKU ${product.sku} is already in use.');
    }

    final batch = _db.batch()
      ..update(doc.reference, {
        Fs.productId: product.sku,
        ...await _fieldsOf(product),
        // Only ever set, never cleared: the form has no way to remove a
        // picture, so a null here means "unchanged".
        if (product.image != null) Fs.image: product.image!,
      });

    if (renumbered) {
      // Carts and orders point at a product by its id, so a renumbered
      // listing takes them with it rather than leaving them pointing at
      // nothing.
      for (final collection in [Fs.cartItems, Fs.orderItems]) {
        final lines = await _db
            .collection(collection)
            .where(Fs.productId, isEqualTo: originalSku)
            .get();
        for (final line in lines.docs) {
          batch.update(line.reference, {Fs.productId: product.sku});
        }
      }
    }

    await batch.commit();
    return product;
  });

  @override
  Future<int> updateStock(Map<String, int> bySku) => guardFirestore(() async {
    final negative = bySku.entries.where((entry) => entry.value < 0);
    if (negative.isNotEmpty) {
      throw BadRequest(
        400,
        'Stock cannot be negative: check ${negative.first.key}.',
      );
    }
    if (bySku.isEmpty) return 0;

    final batch = _db.batch();
    var changed = 0;
    for (final doc in (await _products.get()).docs) {
      final stock = bySku[Fs.stringOf(doc.data()[Fs.productId])];
      // Unknown SKUs and unchanged figures are skipped, as the in-memory
      // store does: a listing deleted meanwhile is no reason to lose the
      // rest of the edit.
      if (stock == null || stock == Fs.intOf(doc.data()[Fs.stockQuantity])) {
        continue;
      }
      batch.update(doc.reference, {Fs.stockQuantity: stock});
      changed++;
    }
    if (changed > 0) await batch.commit();
    return changed;
  });

  @override
  Future<RemovedProduct> deleteProduct(String sku) => guardFirestore(() async {
    final doc = await _findOr404(sku);
    final product = productOf(doc, await _categoryNames());
    await doc.reference.delete();
    return RemovedProduct(
      product: product,
      // The list is sorted on every read, so a position would mean nothing.
      index: 0,
      stored: (id: doc.id, data: doc.data()),
    );
  });

  @override
  Future<void> restoreProduct(RemovedProduct removed) =>
      guardFirestore(() async {
        if (await _find(removed.product.sku) != null) {
          throw BadRequest(
            409,
            'SKU ${removed.product.sku} is in use again — it cannot be '
            'restored.',
          );
        }
        final stored = removed.stored;
        if (stored == null) {
          await createProduct(removed.product);
          return;
        }
        // The same document id and every field it had — undo puts back what
        // was there, not a copy of it.
        await _products.doc(stored.id).set(stored.data);
      });

  /// One document as the screens see it.
  static Product productOf(
    DocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, String> categoryNames,
  ) {
    final data = doc.fields;
    final stored = Fs.stringOf(data[Fs.productId]);
    // A document written without a product_id is still listed, under the
    // only id it has.
    final sku = stored.isEmpty ? doc.id : stored;
    final categoryId = Fs.stringOf(data[Fs.categoryId]);

    return Product(
      name: Fs.stringOf(data[Fs.productName]),
      sku: sku,
      pricePaise: Fs.paiseOf(data[Fs.price]),
      stock: Fs.intOf(data[Fs.stockQuantity]),
      // An id with no category behind it is shown as itself, so the admin
      // can see something is wrong rather than the product looking
      // uncategorised.
      category: categoryNames[categoryId] ?? categoryId,
      swatchIndex: Fs.swatchFor(data[Fs.swatchIndex], sku, Swatches.count),
      image: Fs.optionalString(data[Fs.image]),
      description: Fs.stringOf(data[Fs.description]),
    );
  }

  /// Everything the form edits, in the database's spelling.
  Future<Map<String, Object>> _fieldsOf(Product product) async {
    final ids = {
      for (final entry in (await _categoryNames()).entries)
        entry.value: entry.key,
    };
    return {
      Fs.productName: product.name.trim(),
      Fs.description: product.description.trim(),
      Fs.price: Fs.rupeesOf(product.pricePaise),
      Fs.stockQuantity: product.stock,
      // A name with no category behind it is the raw id the read fell back
      // to; written back as it was rather than lost.
      Fs.categoryId: ids[product.category] ?? product.category,
      Fs.swatchIndex: product.swatchIndex,
    };
  }

  /// category_id → category_name.
  Future<Map<String, String>> _categoryNames() async => {
    for (final doc in (await _db.collection(Fs.categories).get()).docs)
      Fs.stringOf(doc.data()[Fs.categoryId]): Fs.stringOf(
        doc.data()[Fs.categoryName],
      ),
  };

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _find(String sku) async {
    final found = await _products
        .where(Fs.productId, isEqualTo: sku)
        .limit(1)
        .get();
    return found.docs.isEmpty ? null : found.docs.first;
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>> _findOr404(
    String sku,
  ) async => await _find(sku) ?? (throw const NotFound());

  /// The backstop behind the form's own checks.
  void _require(Product product) {
    if (product.name.trim().isEmpty) {
      throw const BadRequest(400, 'A product needs a name.');
    }
    if (product.sku.trim().isEmpty) {
      throw const BadRequest(400, 'A product needs a SKU.');
    }
    if (product.pricePaise <= 0) {
      throw const BadRequest(400, 'Price must be more than zero.');
    }
    if (product.stock < 0) {
      throw const BadRequest(400, 'Stock cannot be negative.');
    }
  }
}
