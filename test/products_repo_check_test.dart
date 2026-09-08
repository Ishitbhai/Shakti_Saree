import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shakti_saree/admin/products/product.dart';
import 'package:shakti_saree/admin/products/products_providers.dart';
import 'package:shakti_saree/admin/products/products_repository.dart';
import 'package:shakti_saree/admin/products/products_screen.dart';
import 'package:shakti_saree/admin/products/widgets/product_tile.dart';
import 'package:shakti_saree/core/network/api_exception.dart';
import 'package:shakti_saree/core/theme/app_theme.dart';

class _FailingRepository implements ProductsRepository {
  @override
  Future<List<Product>> fetchProducts() async =>
      throw const NetworkUnavailable();
}

class _EmptyRepository implements ProductsRepository {
  @override
  Future<List<Product>> fetchProducts() async => const [];
}

class _SlowRepository implements ProductsRepository {
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
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders the catalogue exactly as before', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(const ProductsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Products'), findsOneWidget);
    expect(find.text('5 total'), findsOneWidget);
    expect(find.byType(ProductTile), findsNWidgets(5));
    expect(find.text('Banarasi Silk Saree'), findsOneWidget);
    expect(find.text('₹2,499'), findsOneWidget);
    expect(find.text('In Stock 24'), findsOneWidget);
    expect(find.text('Low Stock'), findsOneWidget);
    expect(find.text('Out of Stock'), findsOneWidget);
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
