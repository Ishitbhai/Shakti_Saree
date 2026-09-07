import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../shared/widgets/admin_page_header.dart';
import '../domain/product.dart';
import 'add_product_screen.dart';
import 'widgets/product_tile.dart';

/// Admin product catalogue: search, then a scrolling list of products.
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  static const double _screenPadding = AppSpacing.x5;

  /// Hardcoded until the repository lands.
  static const List<Product> _products = [
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

  /// Placeholder photo tints, cycled by list position so the same product
  /// always gets the same colour. Every entry is an existing token.
  static const List<Color> _swatches = [
    AppColors.primary,
    AppColors.warning,
    AppColors.success,
    AppColors.info,
    AppColors.primaryLight,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AdminPageHeader(
              title: 'Products',
              subtitle: '${Formatters.count(_products.length)} total',
              action: AdminHeaderAction(
                icon: Icons.add,
                label: 'Add product',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddProductScreen(),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                _screenPadding,
                AppSpacing.x2,
                _screenPadding,
                AppSpacing.x4,
              ),
              child: _SearchField(),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  _screenPadding,
                  0,
                  _screenPadding,
                  AppSpacing.x6,
                ),
                itemCount: _products.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.x3),
                itemBuilder: (context, index) => ProductTile(
                  product: _products[index],
                  swatch: _swatches[index % _swatches.length],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      // Filtering arrives with the repository.
      decoration: const InputDecoration(
        hintText: 'Search product or SKU',
        prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textGrey),
      ),
      style: AppTypography.bodyMedium,
    );
  }
}
