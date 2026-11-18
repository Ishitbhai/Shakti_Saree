import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/data/api_exception.dart';
import '../../admin/utils/formatters.dart';
import '../data/shop_providers.dart';
import '../models/shop_models.dart';
import '../resources/imagestrings.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../widgets/shop_async_view.dart';
import '../widgets/shop_image.dart';
import 'categories_screen.dart';
import 'product_detail_screen.dart';
import 'product_list_screen.dart';
import 'search_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // State variables for content[cite: 19]
  final String greetingPrefix = 'Namaste';
  final String heroTitle = 'Find saree that suits you';

  // How many of each the page has room for; "See all" leads to the rest
  static const int categoriesShown = 4;
  static const int trendingShown = 2;

  Future<void> _addToCart(ShopProduct product) async {
    String message;
    try {
      await ref.read(shopRepositoryProvider).addToCart(product);
      message = 'Added to Cart';
    } on ApiException catch (error) {
      message = error.message;
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _navigateToCategoryTab(BuildContext context) {
    final tabController = DefaultTabController.maybeOf(context);
    if (tabController != null) {
      tabController.animateTo(
        1,
      ); // Switches smoothly to Category Tab (Tab 1)[cite: 19]
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CategoriesScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(customerNameProvider).value ?? '';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= FULL-WIDTH MAROON HEADER =================[cite: 19]
            Container(
              width: double.infinity,
              color: AppColors.primary,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName.isEmpty
                            ? greetingPrefix
                            : '$greetingPrefix, $userName',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        heroTitle,
                        style: AppTextStyles.pageTitle.copyWith(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Search bar[cite: 19]
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          readOnly: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchScreen(),
                              ),
                            );
                          },
                          decoration: InputDecoration(
                            hintText: 'Search sarees, lehenga, kurti...',
                            hintStyle: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.muted,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.muted,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ================= SHOP BY CATEGORY =================[cite: 19]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shop by Category',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToCategoryTab(context),
                    child: Text(
                      'See all',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ShopAsyncView<List<ShopCategory>>(
                state: ref.watch(shopCategoriesProvider),
                placeholderHeight: 90,
                onRetry: () => ref.invalidate(allCategoriesProvider),
                builder: (context, categories) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final cat in categories.take(categoriesShown))
                      _buildCategoryCircle(
                        label: cat.name,
                        imagePath: cat.image,
                        onTap: () => _navigateToCategoryTab(context),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ================= PROMO BANNER =================[cite: 19]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 140,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage(image5),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      AppColors.primary.withOpacity(0.7),
                      BlendMode.srcATop,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _navigateToCategoryTab(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Shop Now',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 110,
                        height: double.infinity,
                        color: AppColors.yellowStatus,
                        child: Image.asset(
                          image6,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ================= TRENDING NOW =================[cite: 19]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trending Now',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProductListScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'See all',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ShopAsyncView<List<ShopProduct>>(
                state: ref.watch(shopProductsProvider),
                placeholderHeight: 200,
                onRetry: () => ref.invalidate(allProductsProvider),
                builder: (context, products) {
                  final trending = products.take(trendingShown).toList();
                  if (trending.isEmpty) {
                    return Text(
                      'No products available yet',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    );
                  }
                  return Row(
                    children: [
                      for (int i = 0; i < trending.length; i++) ...[
                        Expanded(
                          child: _buildProductCard(
                            imagePath: trending[i].image,
                            title: trending[i].name,
                            price: Formatters.rupeesFromPaise(
                              trending[i].pricePaise,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(
                                    productDocId: trending[i].docId,
                                  ),
                                ),
                              );
                            },
                            onAddToCart: trending[i].inStock
                                ? () => _addToCart(trending[i])
                                : null,
                          ),
                        ),
                        if (i != trending.length - 1) const SizedBox(width: 14),
                      ],
                      // A lone product keeps a card's width, not the page's
                      if (trending.length == 1) ...[
                        const SizedBox(width: 14),
                        const Expanded(child: SizedBox.shrink()),
                      ],
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ================= HELPER WIDGETS =================[cite: 19]
  Widget _buildCategoryCircle({
    required String label,
    required String? imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.muted.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipOval(
              child: ShopImage(
                path: imagePath,
                fallback: Container(
                  color: AppColors.muted.withOpacity(0.2),
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.muted,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Sized because a real category's name can outgrow its circle
          SizedBox(
            width: 72,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.black,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required String? imagePath,
    required String title,
    required String price,
    required VoidCallback onTap,
    VoidCallback? onAddToCart,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.black.withOpacity(0.75),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
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
                  if (onAddToCart != null)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
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
