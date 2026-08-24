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
  });

  final String name;
  final String sku;
  final int pricePaise;
  final int stock;

  /// At or below this, a product is flagged as running low.
  static const int lowStockThreshold = 5;

  StockLevel get level => switch (stock) {
    <= 0 => StockLevel.outOfStock,
    <= lowStockThreshold => StockLevel.lowStock,
    _ => StockLevel.inStock,
  };
}
