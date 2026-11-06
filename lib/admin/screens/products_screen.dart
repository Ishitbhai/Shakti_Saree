import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../styles/app_colors.dart';
import '../styles/app_spacing.dart';
import '../styles/app_typography.dart';
import '../utils/formatters.dart';
import '../widgets/common/admin_page_header.dart';
import '../widgets/common/async_content.dart';
import 'add_product_screen.dart';
import 'inventory_screen.dart';
import '../models/product.dart';
import '../styles/swatches.dart';
import '../data/providers/products_providers.dart';
import '../widgets/products/confirm_delete_dialog.dart';
import '../widgets/products/product_tile.dart';
import '../widgets/navigation/admin_route.dart';

/// Admin product catalogue: search, then a scrolling list of products.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  static const double _screenPadding = AppSpacing.x5;

  /// How long undo stays on offer after a deletion.
  static const Duration undoWindow = Duration(seconds: 6);

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  static const double _screenPadding = ProductsScreen._screenPadding;

  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim().toLowerCase();

  /// Everything whose name, SKU or category holds what has been typed.
  List<Product> _matching(List<Product> products) {
    if (_query.isEmpty) return products;
    return products
        .where(
          (product) =>
              product.name.toLowerCase().contains(_query) ||
              product.sku.toLowerCase().contains(_query) ||
              product.category.toLowerCase().contains(_query),
        )
        .toList();
  }

  /// Opens the form on an existing listing.
  Future<void> _edit(BuildContext context, Product product) {
    return Navigator.of(context).push(
      AdminRoute<void>(builder: (_) => AddProductScreen(product: product)),
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
            duration: ProductsScreen.undoWindow,
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
  Widget build(BuildContext context) {
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
              secondaryAction: AdminHeaderAction(
                icon: Icons.inventory_2_outlined,
                label: 'Inventory',
                onTap: () => Navigator.of(context).push(
                  AdminRoute<void>(builder: (_) => const InventoryScreen()),
                ),
              ),
              action: AdminHeaderAction(
                icon: Icons.add,
                label: 'Add product',
                onTap: () => Navigator.of(context).push(
                  AdminRoute<void>(builder: (_) => const AddProductScreen()),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _screenPadding,
                AppSpacing.x2,
                _screenPadding,
                AppSpacing.x4,
              ),
              child: _SearchField(controller: _search),
            ),
            Expanded(
              child: AsyncContent<List<Product>>(
                state: products,
                onRetry: () => ref.invalidate(productsProvider),
                isEmpty: (loaded) => loaded.isEmpty,
                emptyMessage: 'No products yet.',
                builder: (context, all) => _buildList(context, _matching(all)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Product> loaded) {
    if (loaded.isEmpty) {
      return AsyncMessage(text: 'Nothing matches "${_search.text.trim()}"');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        _screenPadding,
        0,
        _screenPadding,
        AppSpacing.x6,
      ),
      itemCount: loaded.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x3),
      itemBuilder: (context, index) {
        final product = loaded[index];
        return ProductTile(
          product: product,
          // The product's own tint, so it keeps its colour
          // wherever it ends up in the list.
          swatch: Swatches.at(product.swatchIndex),
          onEdit: () => _edit(context, product),
          onDelete: () => _delete(context, ref, product),
        );
      },
    );
  }
}

/// Filters by name, SKU or category as the admin types.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search product or SKU',
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: AppColors.textGrey,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.textGrey,
                tooltip: 'Clear search',
                onPressed: controller.clear,
              ),
      ),
      style: AppTypography.bodyMedium,
    );
  }
}
