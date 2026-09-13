/// One grouping in the catalogue.
///
/// The name is the identity — it is what a product stores to say which
/// grouping it belongs to, and what the dropdown on the product form offers.
/// Renaming one is therefore a change two places have to agree on, which is
/// the repository's job rather than the model's.
class Category {
  const Category({
    required this.name,
    this.swatchIndex = 0,
    this.isHidden = false,
  });

  final String name;

  /// Which tint stands in for the category's artwork.
  ///
  /// An index rather than a colour, so the model stays clear of anything
  /// visual; `Swatches` turns it into one.
  final int swatchIndex;

  /// Hidden categories stay in the catalogue but are not offered to
  /// shoppers. They are still shown here, greyed, because an admin has to be
  /// able to find one again to bring it back.
  final bool isHidden;

  Category copyWith({String? name, int? swatchIndex, bool? isHidden}) =>
      Category(
        name: name ?? this.name,
        swatchIndex: swatchIndex ?? this.swatchIndex,
        isHidden: isHidden ?? this.isHidden,
      );
}

/// A category and how much of the catalogue sits in it.
///
/// The count is worked out from the products rather than stored on the
/// category, so it cannot go stale when a listing moves or is deleted.
class CategoryListing {
  const CategoryListing({required this.category, required this.productCount});

  final Category category;
  final int productCount;

  String get name => category.name;

  bool get isHidden => category.isHidden;

  int get swatchIndex => category.swatchIndex;
}
