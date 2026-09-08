import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'product.dart';
import 'products_repository.dart';

/// The catalogue source. Overridden in tests and, later, swapped for the HTTP
/// implementation in one place.
final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => const InMemoryProductsRepository(),
);

/// The catalogue. `ref.invalidate` on this re-reads it.
final productsProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(productsRepositoryProvider).fetchProducts(),
);
