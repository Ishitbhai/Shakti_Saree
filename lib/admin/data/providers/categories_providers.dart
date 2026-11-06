import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_schema.dart';
import '../mock/category_store.dart';
import '../mock/product_store.dart';
import '../repositories/categories_repository.dart';
import '../repositories/firestore_categories_repository.dart';
import '../../models/category.dart';
import 'backend_providers.dart';

/// The category source: Firestore when the app has one, the in-memory stores
/// otherwise. Overridden in tests.
final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  if (db != null) return FirestoreCategoriesRepository(db);
  return InMemoryCategoriesRepository(
    ref.watch(categoryStoreProvider.notifier),
    ref.watch(productStoreProvider.notifier),
  );
});

/// Every category with its product count.
///
/// Watches both sources, because the row is made of both: renaming a category
/// changes this, and so does a listing moving into or out of one.
final categoriesProvider = FutureProvider<List<CategoryListing>>((ref) {
  ref
    ..watch(categoryStoreProvider)
    ..watch(productStoreProvider);
  watchCollections(ref, const [Fs.categories, Fs.products]);
  return ref.watch(categoriesRepositoryProvider).fetchCategories();
});

/// The names a product can be filed under, for the form's dropdown.
///
/// Hidden categories are left out: they are not on offer, so nothing new
/// should be going into one. On Firestore the names come from the loaded
/// list, and are empty for the moment it takes to arrive.
final categoryNamesProvider = Provider<List<String>>((ref) {
  if (ref.watch(firestoreProvider) != null) {
    return [
      for (final listing in ref.watch(categoriesProvider).value ?? const [])
        if (!listing.isHidden) listing.name,
    ];
  }
  return [
    for (final category in ref.watch(categoryStoreProvider))
      if (!category.isHidden) category.name,
  ];
});
