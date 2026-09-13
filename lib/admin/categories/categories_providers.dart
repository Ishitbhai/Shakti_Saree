import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mock/category_store.dart';
import '../../mock/product_store.dart';
import 'categories_repository.dart';
import 'category.dart';

/// The category source. Overridden in tests and, later, swapped for the HTTP
/// implementation in one place.
final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => InMemoryCategoriesRepository(
    ref.watch(categoryStoreProvider.notifier),
    ref.watch(productStoreProvider.notifier),
  ),
);

/// Every category with its product count.
///
/// Watches both stores, because the row is made of both: renaming a category
/// changes this, and so does a listing moving into or out of one.
final categoriesProvider = FutureProvider<List<CategoryListing>>((ref) {
  ref
    ..watch(categoryStoreProvider)
    ..watch(productStoreProvider);
  return ref.watch(categoriesRepositoryProvider).fetchCategories();
});

/// The names a product can be filed under, for the form's dropdown.
///
/// Hidden categories are left out: they are not on offer, so nothing new
/// should be going into one.
final categoryNamesProvider = Provider<List<String>>((ref) {
  return [
    for (final category in ref.watch(categoryStoreProvider))
      if (!category.isHidden) category.name,
  ];
});
