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
import 'product_swatch.dart';
import 'products_providers.dart';
import 'widgets/confirm_delete_dialog.dart';
import 'widgets/product_tile.dart';

/// Admin product catalogue: search, then a scrolling list of products.
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  static const double _screenPadding = AppSpacing.x5;

  /// How long undo stays on offer after a deletion.
  static const Duration undoWindow = Duration(seconds: 6);

  /// Opens the form on an existing listing.
  Future<void> _edit(BuildContext context, Product product) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddProductScreen(product: product),
      ),
    );
  }

  /// Confirms, deletes, then offers to put it back.
  ///
  /// Deleting takes effect immediately rather than waiting out the undo
  /// window — the list has to tell the truth about what it holds, and undo
  /// restores rather than cancels.
  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final confirmed = await confirmProductDeletion(context, product: product);
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(productsRepositoryProvider);

    try {
      final removed = await repository.deleteProduct(product.sku);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${product.name} deleted'),
            duration: undoWindow,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                try {
                  await repository.restoreProduct(removed);
                } catch (error) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(AsyncContent.messageFor(error))),
                  );
                }
              },
            ),
          ),
        );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(AsyncContent.messageFor(error))),
      );
    }
  }

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
                  itemBuilder: (context, index) {
                    final product = loaded[index];
                    return ProductTile(
                      product: product,
                      // The product's own tint, so it keeps its colour
                      // wherever it ends up in the list.
                      swatch: ProductSwatches.at(product.swatchIndex),
                      onEdit: () => _edit(context, product),
                      onDelete: () => _delete(context, ref, product),
                    );
                  },
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
