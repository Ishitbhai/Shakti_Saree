import 'package:flutter/material.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../resources/imagestrings.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'product_list_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 8 Categories based on design
    final List<Map<String, dynamic>> categories = [
      {'title': 'Silk Saree', 'items': '248 items', 'image': image1},
      {'title': 'Banarasi', 'items': '182 items', 'image': image2},
      {'title': 'Cotton Saree', 'items': '320 items', 'image': image3},
      {'title': 'Georgette', 'items': '156 items', 'image': image4},
      {'title': 'Kanjivaram', 'items': '94 items', 'image': image5},
      {'title': 'Designer', 'items': '210 items', 'image': image6},
      {'title': 'Bridal Wear', 'items': '68 items', 'image': image7},
      {'title': 'Daily Wear', 'items': '412 items', 'image': image8},
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: SizedBox(
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centered Titles
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Categories',
                          style: AppTextStyles.pageTitle.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Fabric & occasion wise',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    // Back Button on the left
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(
                        onTap: () {
                          final tabController = DefaultTabController.maybeOf(
                            context,
                          );
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else if (tabController != null) {
                            tabController.animateTo(0);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ================= CATEGORIES GRID =================
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProductListScreen(),
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

  // ================= IMAGE + DETAILS CARD WIDGET =================
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
              // Top section with image
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

              // Bottom white section with details
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
