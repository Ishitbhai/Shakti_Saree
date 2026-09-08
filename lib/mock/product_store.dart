import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/products/product.dart';
import '../core/errors/api_exception.dart';
import 'mock_data.dart';

/// The app's one copy of the catalogue, standing in for the backend's table.
///
/// The same arrangement as the order store: writing replaces the whole list,
/// so the catalogue screen and the dashboard's product count both recompute
/// without anyone telling them to.
///
/// State lives only as long as the process; a restart re-seeds from
/// [MockData].
///
/// A SKU is the identity here, since the sample records have no id of their
/// own. Whether a given edit is allowed is the repository's business, not
/// this one's.
class ProductStore extends Notifier<List<Product>> {
  @override
  List<Product> build() => MockData.products();

  /// Everything the store holds.
  List<Product> get products => List.unmodifiable(state);

  /// The stored product, or a [NotFound] if no such SKU.
  Product find(String sku) => state[_indexOf(sku)];

  /// Whether [sku] is already taken by something other than [exceptSku].
  ///
  /// The exception is what lets an edit keep its own SKU without colliding
  /// with itself.
  bool isSkuTaken(String sku, {String? exceptSku}) =>
      state.any((product) => product.sku == sku && product.sku != exceptSku);

  /// Replaces the product stored under [originalSku].
  ///
  /// The replacement may carry a different SKU — renaming is an edit like any
  /// other — so the row is found by where it came from, not by where it is
  /// going.
  Product replace(String originalSku, Product updated) {
    final index = _indexOf(originalSku);
    state = [...state]..[index] = updated;
    return updated;
  }

  /// Takes a product out, answering with where it was.
  ///
  /// The position comes back because undo has to put it where it came from
  /// rather than on the end — a list that reshuffles itself on undo has not
  /// really undone anything.
  ({Product product, int index}) remove(String sku) {
    final index = _indexOf(sku);
    final removed = state[index];
    state = [...state]..removeAt(index);
    return (product: removed, index: index);
  }

  /// Puts a removed product back where it was.
  ///
  /// The index is clamped: the list may have been edited in the meantime, and
  /// landing at the end is better than throwing.
  void insert(int index, Product product) {
    final at = index.clamp(0, state.length);
    state = [...state]..insert(at, product);
  }

  int _indexOf(String sku) {
    final index = state.indexWhere((candidate) => candidate.sku == sku);
    if (index == -1) throw const NotFound();
    return index;
  }
}

/// The single catalogue, alive for as long as the app is.
final productStoreProvider = NotifierProvider<ProductStore, List<Product>>(
  ProductStore.new,
);
