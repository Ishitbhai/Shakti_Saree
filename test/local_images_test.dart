import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/models/category.dart';
import 'package:shakti_saree/admin/widgets/categories/category_tile.dart';
import 'package:shakti_saree/admin/models/order_detail.dart';
import 'package:shakti_saree/admin/screens/order_detail_screen.dart';
import 'package:shakti_saree/admin/models/product.dart';
import 'package:shakti_saree/admin/widgets/products/product_tile.dart';
import 'package:shakti_saree/admin/styles/swatches.dart';
import 'package:shakti_saree/admin/resources/app_assets.dart';
import 'package:shakti_saree/admin/styles/app_colors.dart';
import 'package:shakti_saree/admin/styles/app_theme.dart';
import 'package:shakti_saree/admin/widgets/common/local_asset_image.dart';
import 'package:shakti_saree/admin/data/mock/mock_data.dart';

/// Pictures come from the bundle and nowhere else, and a frame without one is
/// a frame with a tint in it rather than a crash.

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(8), child: child),
  ),
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// The assets section of the pubspec, as plain text — enough to tell whether
/// a folder is declared.
String _pubspec() => File('pubspec.yaml').readAsStringSync();

void main() {
  group('the asset list', () {
    test('every path in AppAssets is a file that exists', () {
      for (final path in AppAssets.images) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '$path is referenced but not on disk',
        );
      }
    });

    test('every image folder is declared in the pubspec', () {
      final pubspec = _pubspec();
      final folders = {
        for (final path in AppAssets.images)
          path.substring(0, path.lastIndexOf('/') + 1),
      };

      for (final folder in folders) {
        expect(
          pubspec.contains('- $folder'),
          isTrue,
          reason: '$folder holds bundled images but is not in pubspec.yaml',
        );
      }
    });

    test('the seeded catalogue and groupings all carry a picture', () {
      for (final product in MockData.products()) {
        expect(product.image, isNotNull, reason: product.name);
        expect(AppAssets.images, contains(product.image), reason: product.name);
      }
      for (final category in MockData.categories()) {
        expect(category.image, isNotNull, reason: category.name);
      }
    });

    test('no asset path points anywhere but at this app', () {
      for (final path in AppAssets.images) {
        expect(path.startsWith('assets/'), isTrue, reason: path);
        expect(path.contains('://'), isFalse, reason: path);
      }
    });
  });

  group('a frame with no picture', () {
    testWidgets('falls back to the tint rather than an empty box', (
      tester,
    ) async {
      _phone(tester);

      await tester.pumpWidget(
        _host(
          const LocalAssetImage(
            assetPath: null,
            size: 56,
            tint: AppColors.primary,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nothing was asked of the bundle, and the frame is still filled.
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      // Scoped to the frame: the scaffold around it paints boxes of its own.
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byType(LocalAssetImage),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        AppColors.primary,
      );
    });

    testWidgets('a path that is not in the bundle falls back too', (
      tester,
    ) async {
      _phone(tester);

      await tester.pumpWidget(
        _host(
          const LocalAssetImage(
            assetPath: 'assets/images/products/not_shipped.png',
            size: 56,
            tint: AppColors.warning,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The failed load is reported once; swallowing it here keeps the
      // test honest about what the widget does with it.
      tester.takeException();

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });
  });

  group('the rows', () {
    testWidgets('a listing with a picture shows it', (tester) async {
      _phone(tester);
      final product = MockData.products().first;

      await tester.pumpWidget(
        _host(
          ProductTile(
            product: product,
            swatch: Swatches.at(product.swatchIndex),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      expect((image.image as AssetImage).assetName, product.image);
      expect(find.byIcon(Icons.image_outlined), findsNothing);
    });

    testWidgets('a listing made in the app wears its tint', (tester) async {
      _phone(tester);

      await tester.pumpWidget(
        _host(
          const ProductTile(
            product: Product(
              name: 'Ajrakh Modal Silk',
              sku: 'SS-1090',
              pricePaise: 229900,
              stock: 6,
            ),
            swatch: AppColors.success,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('a grouping with artwork shows it', (tester) async {
      _phone(tester);
      final category = MockData.categories().first;

      await tester.pumpWidget(
        _host(
          CategoryTile(
            listing: CategoryListing(category: category, productCount: 3),
            onEdit: () {},
            onDelete: () {},
            onToggleHidden: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, category.image);
    });
  });

  group('an order line', () {
    /// The detail screen on its own, with the seeded catalogue behind it.
    Future<void> openOrder(WidgetTester tester, OrderDetail detail) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: OrderDetailScreen(detail: detail),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// The thumbnail in the line carrying a given product name. The closest
    /// Row around the name is the line itself.
    LocalAssetImage thumbOf(WidgetTester tester, String name) =>
        tester.widget<LocalAssetImage>(
          find.descendant(
            of: find
                .ancestor(of: find.text(name), matching: find.byType(Row))
                .first,
            matching: find.byType(LocalAssetImage),
          ),
        );

    testWidgets('wears the photo its SKU carries in the catalogue', (
      tester,
    ) async {
      // #SS20260914 opens on Banarasi Silk Saree, SS-1024.
      final detail = MockData.orders().first;
      await openOrder(tester, detail);

      expect(find.text('Banarasi Silk Saree'), findsOneWidget);
      final thumb = thumbOf(tester, 'Banarasi Silk Saree');
      expect(thumb.assetPath, isNotNull);
      expect(
        thumb.assetPath,
        MockData.products().firstWhere((p) => p.sku == 'SS-1024').image,
      );
    });

    testWidgets('falls back to its tint when the SKU is not in the catalogue', (
      tester,
    ) async {
      // A listing deleted since the order was placed: the line stays, the
      // photo cannot be found, and the row still draws.
      final detail = MockData.orders().first;
      await openOrder(
        tester,
        OrderDetail(
          id: detail.id,
          customer: detail.customer,
          phone: detail.phone,
          address: detail.address,
          placedAt: detail.placedAt,
          status: detail.status,
          reachedAt: detail.reachedAt,
          paidVia: detail.paidVia,
          lines: const [
            OrderLine(
              name: 'Withdrawn Saree',
              sku: 'SS-0000',
              quantity: 1,
              pricePaise: 100000,
            ),
          ],
        ),
      );

      final thumb = thumbOf(tester, 'Withdrawn Saree');
      expect(thumb.assetPath, isNull);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });
  });

  group('edits keep the picture', () {
    test('a renamed listing carries its image across', () {
      final product = MockData.products().first;
      final renamed = product.copyWith(name: 'Banarasi Silk Saree (Zari)');

      expect(renamed.image, product.image);
    });

    test('a renamed grouping carries its artwork across', () {
      final category = MockData.categories().first;

      expect(category.copyWith(name: 'Silk').image, category.image);
    });
  });
}
