import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mock/product_store.dart';
import 'product.dart';
import 'products_repository.dart';

/// The catalogue source. Overridden in tests and, later, swapped for the HTTP
/// implementation in one place.
final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => InMemoryProductsRepository(ref.watch(productStoreProvider.notifier)),
);

/// The catalogue.
///
/// Watches the stored list, so an edit saved from the form is on the list
/// screen by the time the form closes.
final productsProvider = FutureProvider<List<Product>>((ref) {
  ref.watch(productStoreProvider);
  return ref.watch(productsRepositoryProvider).fetchProducts();
});
