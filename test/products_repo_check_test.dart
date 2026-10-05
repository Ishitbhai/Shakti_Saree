import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/models/product.dart';
import 'package:shakti_saree/admin/data/providers/products_providers.dart';
import 'package:shakti_saree/admin/data/repositories/products_repository.dart';
import 'package:shakti_saree/admin/screens/products_screen.dart';
import 'package:shakti_saree/admin/widgets/products/product_tile.dart';
import 'package:shakti_saree/admin/data/api_exception.dart';
import 'package:shakti_saree/admin/styles/app_theme.dart';

/// Reads only. Subclasses say what the read does; a test that reaches a write
/// fails loudly rather than quietly passing.
class _ReadOnlyRepository implements ProductsRepository {
  @override
  Future<List<Product>> fetchProducts() async => const [];

  @override
  Future<Product> createProduct(Product product) => throw UnimplementedError();

  @override
  Future<Product> updateProduct({
    required String originalSku,
    required Product product,
  }) => throw UnimplementedError();

  @override
  Future<int> updateStock(Map<String, int> bySku) => throw UnimplementedError();

  @override
  Future<RemovedProduct> deleteProduct(String sku) =>
      throw UnimplementedError();

  @override
  Future<void> restoreProduct(RemovedProduct removed) =>
      throw UnimplementedError();
}

class _FailingRepository extends _ReadOnlyRepository {
  @override
  Future<List<Product>> fetchProducts() async =>
      throw const NetworkUnavailable();
}

class _EmptyRepository extends _ReadOnlyRepository {}

class _SlowRepository extends _ReadOnlyRepository {
  final completer = Completer<List<Product>>();

  @override
  Future<List<Product>> fetchProducts() => completer.future;
}

Widget _host(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 47)),
          child: child,
        ),
      ),
    );

/// Swaps the catalogue source for one the test controls.
List<Override> _using(ProductsRepository repository) => [
  productsRepositoryProvider.overrideWithValue(repository),
];

void main() {
  testWidgets('renders the catalogue exactly as before', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(const ProductsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Products'), findsOneWidget);
    expect(find.text('25 total'), findsOneWidget);
    // A lower bound rather than the full count: the list is lazy, so only
    // the screenful builds, and how many that is depends on the viewport.
    expect(find.byType(ProductTile), findsAtLeastNWidgets(5));
    expect(find.text('Banarasi Silk Saree'), findsOneWidget);
    expect(find.text('₹2,499'), findsOneWidget);
    expect(find.text('In Stock 24'), findsOneWidget);
    expect(find.text('Low Stock'), findsWidgets);
    expect(find.text('Out of Stock'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows a spinner while the repository is working', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repository = _SlowRepository();
    await tester.pumpWidget(
      _host(const ProductsScreen(), overrides: _using(repository)),
    );
    await tester.pump();

    // Header stays put; only the list area waits.
    expect(find.text('Products'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ProductTile), findsNothing);

    repository.completer.complete(const []);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('surfaces the failure message with a retry', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(const ProductsScreen(), overrides: _using(_FailingRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text(const NetworkUnavailable().message), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(ProductTile), findsNothing);
  });

  testWidgets('says so when the catalogue is empty', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(const ProductsScreen(), overrides: _using(_EmptyRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('No products yet.'), findsOneWidget);
    expect(find.text('0 total'), findsOneWidget);
  });
}
