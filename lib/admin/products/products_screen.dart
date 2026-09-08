import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../shared/widgets/admin_page_header.dart';
import '../shared/widgets/async_content.dart';
import 'add_product_screen.dart';
import 'product.dart';
import 'products_providers.dart';
import 'widgets/product_tile.dart';

/// Admin product catalogue: search, then a scrolling list of products.
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  static const double _screenPadding = AppSpacing.x5;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AdminPageHeader(
              title: 'Products',
              // Blank until the count is known, so the header keeps its
              // height instead of jumping when the catalogue arrives.
              subtitle: products.maybeWhen(
                data: (loaded) => '${Formatters.count(loaded.length)} total',
                orElse: () => '',
              ),
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
              child: AsyncContent<List<Product>>(
                state: products,
                onRetry: () => ref.invalidate(productsProvider),
                isEmpty: (loaded) => loaded.isEmpty,
                emptyMessage: 'No products yet.',
                builder: (context, loaded) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    _screenPadding,
                    0,
                    _screenPadding,
                    AppSpacing.x6,
                  ),
                  itemCount: loaded.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.x3),
                  itemBuilder: (context, index) => ProductTile(
                    product: loaded[index],
                    swatch: _swatches[index % _swatches.length],
                  ),
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
