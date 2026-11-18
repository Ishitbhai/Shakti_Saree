import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../../admin/utils/formatters.dart';
import '../data/shop_providers.dart';
import '../models/shop_models.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../widgets/shop_async_view.dart';
import '../widgets/shop_image.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    this.searchQuery,
  });

  /// Narrows the list to one category. Left out, it is the whole catalogue.
  final String? categoryId;
  final String? categoryName;

  /// Narrows the list to the products whose names match.
  final String? searchQuery;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  // State variables for filters[cite: 19]
  int _selectedFilterIndex = 0;

  late final List<String> _filters;

  @override
  void initState() {
    super.initState();
    _filters = ['All', 'Under ₹2000', 'Banarasi', 'New'];
  }

  String get categoryTitle {
    final query = widget.searchQuery;
    if (query != null) return '"$query"';
    return widget.categoryName ?? 'All Products';
  }

  // The category or search this screen was opened for, then the selected chip
  List<ShopProduct> _shownFrom(List<ShopProduct> products) {
    final categoryId = widget.categoryId;
    final query = widget.searchQuery;
    final inScope = products.where(
      (product) =>
          (categoryId == null || product.categoryId == categoryId) &&
          (query == null || product.matches(query)),
    );

    return switch (_selectedFilterIndex) {
      1 => inScope.where((product) => product.pricePaise < 200000).toList(),
      2 => inScope.where((product) => product.matches('banarasi')).toList(),
      // No date on a product, so the running id stands in for one
      3 => inScope.toList()..sort((a, b) => b.productId.compareTo(a.productId)),
      _ => inScope.toList(),
    };
  }

  void _handleBackNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      final tabController = DefaultTabController.maybeOf(context);
      if (tabController != null) {
        tabController.animateTo(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = ref.watch(shopProductsProvider).whenData(_shownFrom);
    final totalProductsCount = shown.value?.length;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================[cite: 19]
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: SizedBox(
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          categoryTitle,
                          style: AppTextStyles.pageTitle.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          switch (totalProductsCount) {
                            null => '',
                            1 => '1 product',
                            final count => '$count products',
                          },
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(onTap: _handleBackNavigation),
                    ),
                  ],
                ),
              ),
            ),

            // ================= FILTER CHIPS ROW =================[cite: 19]
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final bool isSelected = _selectedFilterIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilterIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.black.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _filters[index],
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected ? AppColors.white : AppColors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // ================= PRODUCT GRID =================[cite: 19]
            Expanded(
              child: ShopAsyncView<List<ShopProduct>>(
                state: shown,
                onRetry: () => ref.invalidate(allProductsProvider),
                builder: (context, products) {
                  if (products.isEmpty) {
                    final query = widget.searchQuery;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          query == null
                              ? 'No products found'
                              : 'No products found for "$query"',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    itemCount: products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.68,
                        ),
                    itemBuilder: (context, index) {
                      final item = products[index];
                      return _buildProductCard(
                        imagePath: item.image,
                        title: item.name,
                        price: Formatters.rupeesFromPaise(item.pricePaise),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(productDocId: item.docId),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPER WIDGETS =================[cite: 19]
  Widget _buildProductCard({
    required String? imagePath,
    required String title,
    required String price,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.black.withOpacity(0.7), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ShopImage(
                    path: imagePath,
                    fallback: Container(
                      color: AppColors.muted.withOpacity(0.2),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              price,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Free Delivery',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
