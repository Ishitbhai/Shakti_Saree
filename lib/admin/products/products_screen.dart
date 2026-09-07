import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../shared/widgets/admin_page_header.dart';
import '../shared/widgets/async_content.dart';
import 'add_product_screen.dart';
import 'product.dart';
import 'products_repository.dart';
import 'widgets/product_tile.dart';

/// Admin product catalogue: search, then a scrolling list of products.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, this.repository});

  /// Injectable so tests can supply their own catalogue or a failing one.
  final ProductsRepository? repository;

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
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductsRepository _repository =
      widget.repository ?? const InMemoryProductsRepository();

  List<Product>? _products;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final products = await _repository.fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AdminPageHeader(
              title: 'Products',
              // Blank until the count is known, so the header keeps its
              // height instead of jumping when the catalogue arrives.
              subtitle: products == null
                  ? ''
                  : '${Formatters.count(products.length)} total',
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
                ProductsScreen._screenPadding,
                AppSpacing.x2,
                ProductsScreen._screenPadding,
                AppSpacing.x4,
              ),
              child: _SearchField(),
            ),
            Expanded(child: _buildBody(products)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Product>? products) {
    return AsyncContent<List<Product>>(
      value: products,
      error: _error,
      onRetry: _load,
      isEmpty: (loaded) => loaded.isEmpty,
      emptyMessage: 'No products yet.',
      builder: (context, loaded) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          ProductsScreen._screenPadding,
          0,
          ProductsScreen._screenPadding,
          AppSpacing.x6,
        ),
        itemCount: loaded.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x3),
        itemBuilder: (context, index) => ProductTile(
          product: loaded[index],
          swatch:
              ProductsScreen._swatches[index % ProductsScreen._swatches.length],
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
