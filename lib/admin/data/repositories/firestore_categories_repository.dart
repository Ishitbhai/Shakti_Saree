import 'package:cloud_firestore/cloud_firestore.dart';

import '../api_exception.dart';
import '../firestore/firestore_schema.dart';
import '../../models/category.dart';
import '../../styles/swatches.dart';
import 'categories_repository.dart';

/// Serves the groupings from the `categories` collection.
///
/// Products point at a category by its `category_id`, not its name, so a
/// rename here is a change to one document: nothing has to be carried
/// across, unlike the in-memory sample where products store the name.
class FirestoreCategoriesRepository implements CategoriesRepository {
  const FirestoreCategoriesRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection(Fs.categories);

  @override
  Future<List<CategoryListing>> fetchCategories() => guardFirestore(() async {
    final (categories, products) = await (
      _categories.get(),
      _db.collection(Fs.products).get(),
    ).wait;

    final counts = <String, int>{};
    for (final product in products.docs) {
      final id = Fs.stringOf(product.data()[Fs.categoryId]);
      counts[id] = (counts[id] ?? 0) + 1;
    }

    // Oldest first, as the in-memory list reads; the id breaks ties, and
    // places a category with no date at all ahead of the rest.
    final docs = [...categories.docs]
      ..sort((a, b) {
        final at = Fs.dateOf(a.data()[Fs.createdAt]);
        final bt = Fs.dateOf(b.data()[Fs.createdAt]);
        if (at != null && bt != null && at != bt) return at.compareTo(bt);
        if ((at == null) != (bt == null)) return at == null ? -1 : 1;
        return _idOf(a).compareTo(_idOf(b));
      });

    return [
      for (final doc in docs)
        CategoryListing(
          category: categoryOf(doc),
          productCount: counts[_idOf(doc)] ?? 0,
        ),
    ];
  });

  @override
  Future<Category> createCategory(Category category) =>
      guardFirestore(() async {
        final name = _requireName(category.name);
        final all = (await _categories.get()).docs;
        if (_isTaken(all, name)) {
          throw BadRequest(409, 'There is already a $name category.');
        }

        await _categories.add({
          Fs.categoryId: Fs.nextId('CAT', all.map(_idOf)),
          Fs.categoryName: name,
          Fs.createdAt: FieldValue.serverTimestamp(),
          if (category.image != null) Fs.image: category.image!,
          Fs.swatchIndex: category.swatchIndex,
          Fs.isHidden: category.isHidden,
        });
        return category.copyWith(name: name);
      });

  @override
  Future<Category> updateCategory({
    required String originalName,
    required Category category,
  }) => guardFirestore(() async {
    final name = _requireName(category.name);
    final all = (await _categories.get()).docs;
    final doc = _named(all, originalName);
    if (_isTaken(all, name, except: doc)) {
      throw BadRequest(409, 'There is already a $name category.');
    }

    await doc.reference.update({
      Fs.categoryName: name,
      Fs.swatchIndex: category.swatchIndex,
      Fs.isHidden: category.isHidden,
      if (category.image != null) Fs.image: category.image!,
    });
    return category.copyWith(name: name);
  });

  @override
  Future<Category> setHidden(String name, {required bool isHidden}) =>
      guardFirestore(() async {
        final doc = _named((await _categories.get()).docs, name);
        await doc.reference.update({Fs.isHidden: isHidden});
        return categoryOf(doc).copyWith(isHidden: isHidden);
      });

  @override
  Future<RemovedCategory> deleteCategory(String name) =>
      guardFirestore(() async {
        final doc = _named((await _categories.get()).docs, name);
        final held = await _db
            .collection(Fs.products)
            .where(Fs.categoryId, isEqualTo: _idOf(doc))
            .get();
        final count = held.docs.length;
        if (count > 0) {
          // Refused rather than orphaning them, exactly as the in-memory
          // repository does.
          throw BadRequest(
            409,
            '$name still holds '
            '${count == 1 ? '1 product' : '$count products'}. '
            'Move or delete those first.',
          );
        }

        await doc.reference.delete();
        return RemovedCategory(
          category: categoryOf(doc),
          index: 0,
          stored: (id: doc.id, data: doc.data()),
        );
      });

  @override
  Future<void> restoreCategory(RemovedCategory removed) =>
      guardFirestore(() async {
        final name = removed.category.name;
        if (_isTaken((await _categories.get()).docs, name)) {
          throw BadRequest(
            409,
            'There is a $name category again — it cannot be restored.',
          );
        }
        final stored = removed.stored;
        if (stored == null) {
          await createCategory(removed.category);
          return;
        }
        // Same id, same category_id: any product still pointing at it finds
        // it again.
        await _categories.doc(stored.id).set(stored.data);
      });

  static Category categoryOf(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.fields;
    return Category(
      name: Fs.stringOf(data[Fs.categoryName]),
      swatchIndex: Fs.swatchFor(
        data[Fs.swatchIndex],
        Fs.stringOf(data[Fs.categoryId]),
        Swatches.count,
      ),
      isHidden: data[Fs.isHidden] == true,
      image: Fs.optionalString(data[Fs.image]),
    );
  }

  static String _idOf(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Fs.stringOf(doc.fields[Fs.categoryId]);

  static QueryDocumentSnapshot<Map<String, dynamic>> _named(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String name,
  ) {
    for (final doc in docs) {
      if (Fs.stringOf(doc.data()[Fs.categoryName]) == name) return doc;
    }
    throw const NotFound();
  }

  /// Case-blind, as the in-memory store is: 'silk' and 'Silk' side by side
  /// would be two dropdown entries nobody could tell apart.
  static bool _isTaken(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String name, {
    QueryDocumentSnapshot<Map<String, dynamic>>? except,
  }) => docs.any(
    (doc) =>
        doc.id != except?.id &&
        Fs.stringOf(doc.data()[Fs.categoryName]).toLowerCase() ==
            name.toLowerCase(),
  );

  static String _requireName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const BadRequest(400, 'A category needs a name.');
    }
    return trimmed;
  }
}
