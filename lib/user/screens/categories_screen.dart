import 'package:flutter/material.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../resources/imagestrings.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'product_list_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // State variables for header texts and category list[cite: 20]
  final String pageTitle = 'Categories';
  final String pageSubtitle = 'Fabric & occasion wise';
  late final List<Map<String, dynamic>> categories;

  @override
  void initState() {
    super.initState();
    // 8 Categories initialized as state data[cite: 20]
    categories = [
      {'title': 'Silk Saree', 'items': '248 items', 'image': image1},
      {'title': 'Banarasi', 'items': '182 items', 'image': image2},
      {'title': 'Cotton Saree', 'items': '320 items', 'image': image3},
      {'title': 'Georgette', 'items': '156 items', 'image': image4},
      {'title': 'Kanjivaram', 'items': '94 items', 'image': image5},
      {'title': 'Designer', 'items': '210 items', 'image': image6},
      {'title': 'Bridal Wear', 'items': '68 items', 'image': image7},
      {'title': 'Daily Wear', 'items': '412 items', 'image': image8},
    ];
  }

  void _handleBackNavigation() {
    final tabController = DefaultTabController.maybeOf(context);
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else if (tabController != null) {
      tabController.animateTo(0);
    }
  }

  void _navigateToProductList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================[cite: 20]
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: SizedBox(
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centered Titles[cite: 20]
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          pageTitle,
                          style: AppTextStyles.pageTitle.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pageSubtitle,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    // Back Button on the left[cite: 20]
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(onTap: _handleBackNavigation),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ================= CATEGORIES GRID =================[cite: 20]
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return _buildCategoryCard(
                    title: cat['title'] as String,
                    items: cat['items'] as String,
                    imagePath: cat['image'] as String,
                    onTap: _navigateToProductList,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= IMAGE + DETAILS CARD WIDGET =================[cite: 20]
  Widget _buildCategoryCard({
    required String title,
    required String items,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.black.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Top section with image[cite: 20]
              Expanded(
                flex: 6,
                child: SizedBox(
                  width: double.infinity,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.muted.withOpacity(0.2),
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.muted,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom white section with details[cite: 20]
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  color: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
