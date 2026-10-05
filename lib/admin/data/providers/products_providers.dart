import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mock/product_store.dart';
import '../../models/product.dart';
import '../repositories/products_repository.dart';

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

/// The catalogue's photographs, by SKU.
///
/// Worked out from the catalogue rather than copied onto the order line, for
/// the same reason a category does not store its own product count: an order
/// then shows whatever picture the listing wears today, and a photo swapped
/// on the product form is on every order that line appears in without
/// anything being told to update.
///
/// A SKU with nothing behind it is simply absent — a listing deleted after
/// the order was placed, or one that never had a photo — and the frame falls
/// back to its tint.
final productImagesProvider = Provider<Map<String, String>>((ref) {
  final products = ref.watch(productsProvider).value ?? const <Product>[];

  return {
    for (final product in products)
      if (product.image != null) product.sku: product.image!,
  };
});
