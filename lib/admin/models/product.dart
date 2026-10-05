/// How much of a product is left, as shown on its stock pill.
enum StockLevel { inStock, lowStock, outOfStock }

/// One row of the admin product catalogue.
///
/// Price is held as paise; formatting happens at the widget.
class Product {
  const Product({
    required this.name,
    required this.sku,
    required this.pricePaise,
    required this.stock,
    this.swatchIndex = 0,
    this.category = '',
    this.image,
  });

  final String name;
  final String sku;
  final int pricePaise;
  final int stock;

  /// The grouping this listing belongs to, by name.
  ///
  /// Empty means uncategorised, which is what a listing created before the
  /// groupings existed looks like.
  final String category;

  /// Which tint stands in where there is no photo.
  ///
  /// An index rather than a colour, so the model stays clear of anything
  /// visual; `Swatches` turns it into one.
  final int swatchIndex;

  /// The listing's picture, as a path into the app's own assets, or null for
  /// a listing that has none.
  ///
  /// A bundled path rather than a URL: this app loads no pictures over a
  /// network. A listing created in the app has no photo to point at yet, so
  /// null is the ordinary case rather than an error — the tile falls back to
  /// [swatchIndex] and carries on.
  final String? image;

  Product copyWith({
    String? name,
    String? sku,
    int? pricePaise,
    int? stock,
    String? category,
    int? swatchIndex,
    String? image,
  }) => Product(
    name: name ?? this.name,
    sku: sku ?? this.sku,
    pricePaise: pricePaise ?? this.pricePaise,
    stock: stock ?? this.stock,
    category: category ?? this.category,
    swatchIndex: swatchIndex ?? this.swatchIndex,
    image: image ?? this.image,
  );

  /// At or below this, a product is flagged as running low.
  static const int lowStockThreshold = 5;

  StockLevel get level => switch (stock) {
    <= 0 => StockLevel.outOfStock,
    <= lowStockThreshold => StockLevel.lowStock,
    _ => StockLevel.inStock,
  };
}
