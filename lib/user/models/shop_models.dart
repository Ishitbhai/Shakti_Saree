import 'package:cloud_firestore/cloud_firestore.dart';

import '../../admin/data/firestore/firestore_schema.dart';

/// One `products` document, as a shopper sees it.
///
/// Carries both of a product's ids, because they do different jobs: [docId]
/// is what the product screen opens the document by, and [productId] is what
/// the rest of the database knows it as — a cart line points at a product by
/// its `product_id`, never by its document id.
class ShopProduct {
  const ShopProduct({
    required this.docId,
    required this.productId,
    required this.name,
    required this.description,
    required this.pricePaise,
    required this.stock,
    required this.categoryId,
    this.image,
  });

  factory ShopProduct.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.fields;
    final stored = Fs.stringOf(data[Fs.productId]);
    return ShopProduct(
      docId: doc.id,
      // A document written without a product_id is still listed, under the
      // only id it has, as it is in the admin panel.
      productId: stored.isEmpty ? doc.id : stored,
      name: Fs.stringOf(data[Fs.productName]),
      description: Fs.stringOf(data[Fs.description]),
      pricePaise: Fs.paiseOf(data[Fs.price]),
      stock: Fs.intOf(data[Fs.stockQuantity]),
      categoryId: Fs.stringOf(data[Fs.categoryId]),
      image: Fs.optionalString(data[Fs.image]),
    );
  }

  final String docId;
  final String productId;
  final String name;
  final String description;
  final int pricePaise;
  final int stock;
  final String categoryId;

  /// A URL or a path into the app's assets, or null for a listing with no
  /// picture. `ShopImage` knows what to do with each.
  final String? image;

  bool get inStock => stock > 0;

  /// Whether the name holds every word of [query], in any order or case.
  ///
  /// Done here rather than in a query because Firestore has no substring
  /// search, and the database keeps no lowercase copy of the name to run even
  /// a prefix match against. Word by word, so 'banarasi saree' still finds a
  /// 'Banarasi Silk Saree'.
  bool matches(String query) {
    final name = this.name.toLowerCase();
    return query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .every(name.contains);
  }
}

/// One `categories` document, and how much of the catalogue sits in it.
class ShopCategory {
  const ShopCategory({
    required this.id,
    required this.name,
    this.image,
    this.isHidden = false,
    this.createdAt,
    this.productCount = 0,
  });

  factory ShopCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.fields;
    final stored = Fs.stringOf(data[Fs.categoryId]);
    return ShopCategory(
      id: stored.isEmpty ? doc.id : stored,
      name: Fs.stringOf(data[Fs.categoryName]),
      image: Fs.optionalString(data[Fs.image]),
      isHidden: data[Fs.isHidden] == true,
      createdAt: Fs.dateOf(data[Fs.createdAt]),
    );
  }

  final String id;
  final String name;
  final String? image;
  final bool isHidden;
  final DateTime? createdAt;

  /// Worked out from the products rather than stored, so it cannot go stale.
  final int productCount;

  ShopCategory withCount(int count) => ShopCategory(
    id: id,
    name: name,
    image: image,
    isHidden: isHidden,
    createdAt: createdAt,
    productCount: count,
  );
}

/// One `cart_items` document.
class CartLine {
  const CartLine({
    required this.docId,
    required this.productId,
    required this.quantity,
  });

  factory CartLine.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.fields;
    return CartLine(
      docId: doc.id,
      productId: Fs.stringOf(data[Fs.productId]),
      quantity: Fs.intOf(data[Fs.quantity]),
    );
  }

  final String docId;
  final String productId;
  final int quantity;
}

/// A cart line and the product it points at.
///
/// The database stores only the product's id on the line, so the name, price
/// and picture are always today's, read from the product itself.
class CartEntry {
  const CartEntry({required this.line, this.product});

  final CartLine line;

  /// Null when the listing has been deleted since it went in the cart. The
  /// line stays on screen, unpriced, so the customer can see what happened
  /// and take it out.
  final ShopProduct? product;

  int get lineTotalPaise => (product?.pricePaise ?? 0) * line.quantity;
}
