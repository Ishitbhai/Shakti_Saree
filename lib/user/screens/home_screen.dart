import 'package:flutter/material.dart';

import '../resources/imagestrings.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'categories_screen.dart';
import 'product_detail_screen.dart';
import 'product_list_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToCategoryTab(BuildContext context) {
    final tabController = DefaultTabController.maybeOf(context);
    if (tabController != null) {
      tabController.animateTo(1); // Switches smoothly to Category Tab (Tab 1)
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CategoriesScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= FULL-WIDTH MAROON HEADER =================
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
                        'Namaste, Vivek',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find saree that suits you',
                        style: AppTextStyles.pageTitle.copyWith(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Search bar
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

            // ================= SHOP BY CATEGORY =================
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCategoryCircle(
                    label: 'Silk',
                    imagePath: image1,
                    onTap: () => _navigateToCategoryTab(context),
                  ),
                  _buildCategoryCircle(
                    label: 'Banarasi',
                    imagePath: image2,
                    onTap: () => _navigateToCategoryTab(context),
                  ),
                  _buildCategoryCircle(
                    label: 'Cotton',
                    imagePath: image3,
                    onTap: () => _navigateToCategoryTab(context),
                  ),
                  _buildCategoryCircle(
                    label: 'Designer',
                    imagePath: image4,
                    onTap: () => _navigateToCategoryTab(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ================= PROMO BANNER =================
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

            // ================= TRENDING NOW =================
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
              child: Row(
                children: [
                  Expanded(
                    child: _buildProductCard(
                      discount: '-50%',
                      imagePath: image7,
                      title: 'Banarasi Silk Saree',
                      price: '₹2,499',
                      originalPrice: '₹4,999',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProductDetailScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildProductCard(
                      discount: '-45%',
                      imagePath: image8,
                      title: 'Kanjivaram Pure Silk',
                      price: '₹3,299',
                      originalPrice: '₹5,499',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProductDetailScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ================= HELPER WIDGETS =================
  Widget _buildCategoryCircle({
    required String label,
    required String imagePath,
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
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
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
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.black,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required String discount,
    required String imagePath,
    required String title,
    required String price,
    required String originalPrice,
    required VoidCallback onTap,
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
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.muted.withOpacity(0.2),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        discount,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
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
            Row(
              children: [
                Text(
                  price,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  originalPrice,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.muted,
                    decoration: TextDecoration.lineThrough,
                    fontSize: 10,
                  ),
                ),
              ],
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
