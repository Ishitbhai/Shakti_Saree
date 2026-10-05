import 'package:flutter/material.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'product_list_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 8 Categories based on design
    final List<Map<String, dynamic>> categories = [
      {
        'title': 'Silk Saree',
        'items': '248 items',
        'topColor': const Color(0xFF9A2046),
        'bottomColor': const Color(0xFF5E1229),
      },
      {
        'title': 'Banarasi',
        'items': '182 items',
        'topColor': const Color(0xFFFFA500),
        'bottomColor': const Color(0xFFA56600),
      },
      {
        'title': 'Cotton Saree',
        'items': '320 items',
        'topColor': const Color(0xFF86E38A),
        'bottomColor': const Color(0xFF4C8C50),
      },
      {
        'title': 'Georgette',
        'items': '156 items',
        'topColor': const Color(0xFF0084FF),
        'bottomColor': const Color(0xFF004D99),
      },
      {
        'title': 'Kanjivaram',
        'items': '94 items',
        'topColor': const Color(0xFFD86546),
        'bottomColor': const Color(0xFF803320),
      },
      {
        'title': 'Designer',
        'items': '210 items',
        'topColor': const Color(0xFF800080),
        'bottomColor': const Color(0xFF4A004A),
      },
      {
        'title': 'Bridal Wear',
        'items': '68 items',
        'topColor': const Color(0xFF9A2046),
        'bottomColor': const Color(0xFF5E1229),
      },
      {
        'title': 'Daily Wear',
        'items': '412 items',
        'topColor': const Color(0xFF008F11),
        'bottomColor': const Color(0xFF00520A),
      },
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
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(),
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
                    topColor: cat['topColor'] as Color,
                    bottomColor: cat['bottomColor'] as Color,
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

      // ================= BOTTOM NAVIGATION BAR =================
      bottomNavigationBar: const AppBottomNavBar(selectedIndex: 1),
    );
  }

  // ================= DUAL-TONE CARD WIDGET =================
  Widget _buildCategoryCard({
    required String title,
    required String items,
    required Color topColor,
    required Color bottomColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Top colored section
            Expanded(
              flex: 6,
              child: Container(width: double.infinity, color: topColor),
            ),

            // Bottom dark section with details
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                color: bottomColor,
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
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white.withOpacity(0.8),
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
    );
  }
}
