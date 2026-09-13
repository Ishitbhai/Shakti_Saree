import '../../core/errors/api_exception.dart';
import '../../mock/category_store.dart';
import '../../mock/product_store.dart';
import 'category.dart';

/// Reads and writes the catalogue's groupings.
abstract interface class CategoriesRepository {
  /// Every category, each with how many listings sit in it.
  Future<List<CategoryListing>> fetchCategories();

  /// Adds a grouping. Rejects a name already in use.
  Future<Category> createCategory(Category category);

  /// Saves an edited grouping.
  ///
  /// [originalName] identifies the row; [category] may carry a different
  /// name. An implementation has to carry the products across with it — they
  /// store the category by name, so a rename that does not would leave them
  /// filed under something that no longer exists.
  Future<Category> updateCategory({
    required String originalName,
    required Category category,
  });

  /// Shows or hides a grouping without otherwise changing it.
  Future<Category> setHidden(String name, {required bool isHidden});

  /// Removes a grouping, answering with enough to put it back.
  Future<RemovedCategory> deleteCategory(String name);

  /// Puts back a grouping that was just removed, where it was.
  Future<void> restoreCategory(RemovedCategory removed);
}

/// A category that has been deleted, and the position it held.
class RemovedCategory {
  const RemovedCategory({required this.category, required this.index});

  final Category category;
  final int index;
}

/// Serves the groupings from the shared in-memory stores.
///
/// Reads both: the categories are its own, but the count beside each one is
/// the catalogue's, so this is the place the two meet.
class InMemoryCategoriesRepository implements CategoriesRepository {
  const InMemoryCategoriesRepository(this._categories, this._products);

  final CategoryStore _categories;
  final ProductStore _products;

  @override
  Future<List<CategoryListing>> fetchCategories() async => [
    for (final category in _categories.categories)
      CategoryListing(
        category: category,
        productCount: _products.countInCategory(category.name),
      ),
  ];

  @override
  Future<Category> createCategory(Category category) async {
    _requireName(category.name);
    if (_categories.isNameTaken(category.name)) {
      throw BadRequest(409, 'There is already a ${category.name} category.');
    }
    return _categories.add(category);
  }

  @override
  Future<Category> updateCategory({
    required String originalName,
    required Category category,
  }) async {
    _requireName(category.name);
    if (_categories.isNameTaken(category.name, exceptName: originalName)) {
      throw BadRequest(409, 'There is already a ${category.name} category.');
    }

    final saved = _categories.replace(originalName, category);
    if (category.name != originalName) {
      // The products come too, or they end up filed under a category that is
      // no longer there.
      _products.moveCategory(originalName, category.name);
    }
    return saved;
  }

  @override
  Future<Category> setHidden(String name, {required bool isHidden}) async {
    final current = _categories.find(name);
    return _categories.replace(name, current.copyWith(isHidden: isHidden));
  }

  @override
  Future<RemovedCategory> deleteCategory(String name) async {
    final count = _products.countInCategory(name);
    if (count > 0) {
      // Refused rather than silently orphaning them. Deleting the grouping
      // would leave every one of those listings pointing at nothing, and the
      // admin would have no way of telling which.
      throw BadRequest(
        409,
        '$name still holds ${count == 1 ? '1 product' : '$count products'}. '
        'Move or delete those first.',
      );
    }

    final removed = _categories.remove(name);
    return RemovedCategory(category: removed.category, index: removed.index);
  }

  @override
  Future<void> restoreCategory(RemovedCategory removed) async {
    if (_categories.isNameTaken(removed.category.name)) {
      throw BadRequest(
        409,
        'There is a ${removed.category.name} category again — it cannot be '
        'restored.',
      );
    }
    _categories.insert(removed.index, removed.category);
  }

  void _requireName(String name) {
    if (name.trim().isEmpty) {
      throw const BadRequest(400, 'A category needs a name.');
    }
  }
}
