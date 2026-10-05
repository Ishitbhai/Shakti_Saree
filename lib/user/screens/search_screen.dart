import 'package:flutter/material.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'MainNavigationScreen.dart';
import 'product_detail_screen.dart';
import 'product_list_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController(
    text: 'banarasi saree',
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(initialIndex: 0),
        ),
        (route) => false,
      );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= TOP SEARCH BAR =================
              Row(
                children: [
                  AppBackButton(onTap: _handleBackNavigation),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.black.withOpacity(0.8),
                          width: 1.2,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) => _navigateToProductList(),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.black,
                            size: 20,
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: const Icon(
                              Icons.cancel_outlined,
                              color: AppColors.black,
                              size: 18,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _handleBackNavigation,
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ================= RECENT SEARCHES =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
                  ),
                  Text(
                    'Clear all',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  _buildRecentChip('silk saree'),
                  _buildRecentChip('red bandhej'),
                  _buildRecentChip('cotton daily wear'),
                  _buildRecentChip('bridal saree'),
                ],
              ),

              const SizedBox(height: 24),

              // ================= TRENDING SEARCHES =================
              Text(
                'Trending Searches',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
              ),

              const SizedBox(height: 14),

              _buildTrendingItem(
                title: 'Banarasi silk saree',
                searches: '1.2k searches',
              ),
              const SizedBox(height: 14),
              _buildTrendingItem(
                title: 'Kanjivaram wedding saree',
                searches: '980 searches',
              ),
              const SizedBox(height: 14),
              _buildTrendingItem(
                title: 'Georgette party wear',
                searches: '740 searches',
              ),
              const SizedBox(height: 14),
              _buildTrendingItem(
                title: 'Cotton saree under 1500',
                searches: '610 searches',
              ),

              const SizedBox(height: 24),

              // ================= SUGGESTED PRODUCTS =================
              Text(
                'Suggested Products',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
              ),

              const SizedBox(height: 14),

              _buildSuggestedCard(
                title: 'Banarasi Silk Saree',
                price: '₹2,499',
                swatchColor: const Color(0xFF9A2046),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductDetailScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSuggestedCard(
                title: 'Banarasi Zari Border',
                price: '₹3,150',
                swatchColor: const Color(0xFFD49657),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductDetailScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSuggestedCard(
                title: 'Banarasi Cotton Silk',
                price: '₹1,899',
                swatchColor: const Color(0xFF3F9B73),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductDetailScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HELPER WIDGETS =================
  Widget _buildRecentChip(String label) {
    return GestureDetector(
      onTap: _navigateToProductList,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.black.withOpacity(0.6), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, size: 15, color: AppColors.black),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.black,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.close, size: 14, color: AppColors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingItem({required String title, required String searches}) {
    return GestureDetector(
      onTap: _navigateToProductList,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.pink,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            searches,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedCard({
    required String title,
    required String price,
    required Color swatchColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.black.withOpacity(0.6), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: swatchColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: AppTextStyles.price.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
