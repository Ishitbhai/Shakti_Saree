import 'product.dart';

/// Reads and writes the product catalogue.
///
/// Screens depend on this, never on a data source, so the in-memory sample
/// below can be swapped for an HTTP implementation without a screen changing.
/// Failures surface as `ApiException` from `core/network`.
abstract interface class ProductsRepository {
  /// The whole catalogue, newest listing last.
  Future<List<Product>> fetchProducts();
}

/// Serves the sample catalogue from memory.
///
/// Stands in until the backend exists. The API implementation belongs beside
/// this one and takes a `DioClient`, calling `getList('/products')` and
/// mapping each row onto [Product]; nothing above this file changes when it
/// arrives.
class InMemoryProductsRepository implements ProductsRepository {
  const InMemoryProductsRepository();

  /// Moved here out of the screen — presentation should not carry data.
  static const List<Product> _catalogue = [
    Product(
      name: 'Banarasi Silk Saree',
      sku: 'SS-1024',
      pricePaise: 249900,
      stock: 24,
    ),
    Product(
      name: 'Kanjivaram Pure Silk',
      sku: 'SS-1025',
      pricePaise: 329900,
      stock: 12,
    ),
    Product(
      name: 'Cotton Daily Saree',
      sku: 'SS-1026',
      pricePaise: 169900,
      stock: 4,
    ),
    Product(
      name: 'Georgette Party Wear',
      sku: 'SS-1027',
      pricePaise: 189900,
      stock: 0,
    ),
    Product(
      name: 'Paithani Silk Saree',
      sku: 'SS-1028',
      pricePaise: 415000,
      stock: 8,
    ),
  ];

  @override
  Future<List<Product>> fetchProducts() async => _catalogue;
}
