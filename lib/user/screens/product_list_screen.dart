import 'package:flutter/material.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../resources/imagestrings.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // State variables for header title, count, filters, and products[cite: 21]
  String categoryTitle = 'Silk Sarees';
  int totalProductsCount = 128;
  int _selectedFilterIndex = 0;

  late final List<String> _filters;
  late List<Map<String, dynamic>> _products;

  @override
  void initState() {
    super.initState();
    _filters = ['All', 'Under ₹2000', 'Banarasi', 'New'];

    _products = [
      {
        'title': 'Banarasi Silk Saree',
        'price': '₹2,499',
        'originalPrice': '₹4,999',
        'discount': '-50%',
        'imagePath': image1,
      },
      {
        'title': 'Kanjivaram Pure Silk',
        'price': '₹3,299',
        'originalPrice': '₹5,499',
        'discount': '-45%',
        'imagePath': image2,
      },
      {
        'title': 'Mysore Silk Saree',
        'price': '₹1,899',
        'originalPrice': '₹3,299',
        'discount': '-42%',
        'imagePath': image3,
      },
      {
        'title': 'Paithani Silk Saree',
        'price': '₹4,150',
        'originalPrice': '₹6,999',
        'discount': '-41%',
        'imagePath': image4,
      },
    ];
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
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================[cite: 21]
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
                          '$totalProductsCount products',
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

            // ================= FILTER CHIPS ROW =================[cite: 21]
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

            // ================= SORT & FILTER BUTTONS =================[cite: 21]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionCapsule(
                      icon: Icons.tune,
                      label: 'Sort by',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildActionCapsule(
                      icon: Icons.filter_list,
                      label: 'Filter',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ================= PRODUCT GRID =================[cite: 21]
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                itemCount: _products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) {
                  final item = _products[index];
                  return _buildProductCard(
                    discount: item['discount'] as String,
                    imagePath: item['imagePath'] as String,
                    title: item['title'] as String,
                    price: item['price'] as String,
                    originalPrice: item['originalPrice'] as String,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProductDetailScreen(),
                        ),
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

  // ================= HELPER WIDGETS =================[cite: 21]
  Widget _buildActionCapsule({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.black.withOpacity(0.65),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.black),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
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
          border: Border.all(color: AppColors.black.withOpacity(0.7), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview Container with Discount Tag[cite: 21]
            Expanded(
              child: Container(
                width: double.infinity,
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
