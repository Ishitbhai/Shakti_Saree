import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/categories/category.dart';
import '../core/errors/api_exception.dart';
import 'mock_data.dart';

/// The app's one copy of the categories, on the same footing as the order and
/// product stores.
///
/// The name is the identity, because that is what a product stores to say
/// where it belongs. Whether a given write is allowed — a name already taken,
/// a rename that has to carry the products with it — is the repository's
/// business, not this one's.
class CategoryStore extends Notifier<List<Category>> {
  @override
  List<Category> build() => MockData.categories();

  /// Everything the store holds.
  List<Category> get categories => List.unmodifiable(state);

  /// The stored category, or a [NotFound] if there is no such name.
  Category find(String name) => state[_indexOf(name)];

  /// Whether [name] is already taken by something other than [exceptName].
  bool isNameTaken(String name, {String? exceptName}) => state.any(
    (category) =>
        category.name.toLowerCase() == name.toLowerCase() &&
        category.name != exceptName,
  );

  /// Adds a grouping at the end of the list.
  Category add(Category category) {
    state = [...state, category];
    return category;
  }

  /// Replaces the category stored under [originalName].
  ///
  /// The replacement may carry a different name — renaming is an edit like
  /// any other — so the row is found by where it came from.
  Category replace(String originalName, Category updated) {
    final index = _indexOf(originalName);
    state = [...state]..[index] = updated;
    return updated;
  }

  /// Takes a category out, answering with where it was so undo can put it
  /// back in place rather than on the end.
  ({Category category, int index}) remove(String name) {
    final index = _indexOf(name);
    final removed = state[index];
    state = [...state]..removeAt(index);
    return (category: removed, index: index);
  }

  /// Puts a removed category back where it was.
  void insert(int index, Category category) {
    final at = index.clamp(0, state.length);
    state = [...state]..insert(at, category);
  }

  int _indexOf(String name) {
    final index = state.indexWhere((candidate) => candidate.name == name);
    if (index == -1) throw const NotFound();
    return index;
  }
}

/// The single category list, alive for as long as the app is.
final categoryStoreProvider = NotifierProvider<CategoryStore, List<Category>>(
  CategoryStore.new,
);
