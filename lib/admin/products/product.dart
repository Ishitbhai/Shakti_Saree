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

  /// Which placeholder tint stands in for the product photo.
  ///
  /// An index rather than a colour, so the model stays clear of anything
  /// visual; `ProductSwatches` turns it into one.
  final int swatchIndex;

  Product copyWith({
    String? name,
    String? sku,
    int? pricePaise,
    int? stock,
    String? category,
    int? swatchIndex,
  }) => Product(
    name: name ?? this.name,
    sku: sku ?? this.sku,
    pricePaise: pricePaise ?? this.pricePaise,
    stock: stock ?? this.stock,
    category: category ?? this.category,
    swatchIndex: swatchIndex ?? this.swatchIndex,
  );

  /// At or below this, a product is flagged as running low.
  static const int lowStockThreshold = 5;

  StockLevel get level => switch (stock) {
    <= 0 => StockLevel.outOfStock,
    <= lowStockThreshold => StockLevel.lowStock,
    _ => StockLevel.inStock,
  };
}
