import '../../core/errors/api_exception.dart';
import '../../mock/product_store.dart';
import 'product.dart';

/// Reads and writes the product catalogue.
///
/// Screens depend on this, never on a data source, so the in-memory sample
/// below can be swapped for an HTTP implementation without a screen changing.
/// Failures surface as `ApiException` from `core/errors`.
abstract interface class ProductsRepository {
  /// The whole catalogue, newest listing last.
  Future<List<Product>> fetchProducts();

  /// Saves an edited listing and answers with what was stored.
  ///
  /// [originalSku] identifies the row being edited; [product] may carry a
  /// different SKU, since a listing can be renumbered. An implementation must
  /// reject a SKU already in use by another listing rather than quietly
  /// creating a duplicate.
  Future<Product> updateProduct({
    required String originalSku,
    required Product product,
  });

  /// Removes a listing, answering with enough to put it back.
  Future<RemovedProduct> deleteProduct(String sku);

  /// Puts back a listing that was just removed, where it was.
  Future<void> restoreProduct(RemovedProduct removed);
}

/// A listing that has been deleted, and the position it held.
///
/// Carrying the position is what makes undo an undo: the row returns to where
/// it was rather than to the end of the list.
class RemovedProduct {
  const RemovedProduct({required this.product, required this.index});

  final Product product;
  final int index;
}

/// Serves the catalogue from the shared in-memory store.
///
/// Stands in until the backend exists. The API implementation belongs beside
/// this one, brings its own HTTP client and maps each row onto [Product];
/// nothing above this file changes when it arrives.
///
/// Holds no products of its own — it is handed the store the rest of the app
/// reads from, and decides which writes to it are allowed.
class InMemoryProductsRepository implements ProductsRepository {
  const InMemoryProductsRepository(this._store);

  final ProductStore _store;

  @override
  Future<List<Product>> fetchProducts() async => _store.products;

  @override
  Future<Product> updateProduct({
    required String originalSku,
    required Product product,
  }) async {
    // The form checks this too, so the admin hears about it while typing;
    // this is the backstop, and the one a real backend would enforce.
    if (_store.isSkuTaken(product.sku, exceptSku: originalSku)) {
      throw BadRequest(409, 'SKU ${product.sku} is already in use.');
    }
    return _store.replace(originalSku, product);
  }

  @override
  Future<RemovedProduct> deleteProduct(String sku) async {
    final removed = _store.remove(sku);
    return RemovedProduct(product: removed.product, index: removed.index);
  }

  @override
  Future<void> restoreProduct(RemovedProduct removed) async {
    // Undo is only offered for a moment, but the SKU could have been taken by
    // an edit in the meantime; refusing is better than two rows claiming it.
    if (_store.isSkuTaken(removed.product.sku)) {
      throw BadRequest(
        409,
        'SKU ${removed.product.sku} is in use again — it cannot be restored.',
      );
    }
    _store.insert(removed.index, removed.product);
  }
}
