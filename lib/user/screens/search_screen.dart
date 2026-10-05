import 'package:flutter/material.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../resources/imagestrings.dart';
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
  late final TextEditingController _searchController;

  // State variables for search query, validation error, and list data[cite: 23]
  String currentSearchQuery = 'banarasi saree';
  String? searchError;
  late List<String> recentSearches;
  late final List<Map<String, String>> trendingSearches;
  late final List<Map<String, dynamic>> suggestedProducts;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: currentSearchQuery);

    recentSearches = [
      'silk saree',
      'red bandhej',
      'cotton daily wear',
      'bridal saree',
    ];

    trendingSearches = [
      {'title': 'Banarasi silk saree', 'searches': '1.2k searches'},
      {'title': 'Kanjivaram wedding saree', 'searches': '980 searches'},
      {'title': 'Georgette party wear', 'searches': '740 searches'},
      {'title': 'Cotton saree under 1500', 'searches': '610 searches'},
    ];

    suggestedProducts = [
      {'title': 'Banarasi Silk Saree', 'price': '₹2,499', 'imagePath': image1},
      {'title': 'Banarasi Zari Border', 'price': '₹3,150', 'imagePath': image2},
      {'title': 'Banarasi Cotton Silk', 'price': '₹1,899', 'imagePath': image3},
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context); //[cite: 23]
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(initialIndex: 0),
        ),
        (route) => false,
      ); //[cite: 23]
    }
  }

  // Simple validation: search term cannot be empty or less than 2 characters
  void _navigateToProductList([String? query]) {
    final term = (query ?? _searchController.text).trim();

    setState(() {
      searchError = null;
    });

    if (term.isEmpty) {
      setState(() {
        searchError = 'Please enter a search term';
      });
      return;
    }

    if (term.length < 2) {
      setState(() {
        searchError = 'Search term must be at least 2 characters';
      });
      return;
    }

    _searchController.text = term;
    if (!recentSearches.contains(term)) {
      setState(() {
        recentSearches.insert(0, term);
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductListScreen()),
    ); //[cite: 23]
  }

  void _removeRecentSearch(int index) {
    setState(() {
      recentSearches.removeAt(index);
    });
  }

  void _clearAllRecentSearches() {
    setState(() {
      recentSearches.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, //[cite: 23]
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ), //[cite: 23]
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, //[cite: 23]
            children: [
              // ================= TOP SEARCH BAR =================[cite: 23]
              Row(
                children: [
                  AppBackButton(onTap: _handleBackNavigation), //[cite: 23]
                  const SizedBox(width: 10), //[cite: 23]
                  Expanded(
                    child: Container(
                      height: 46, //[cite: 23]
                      decoration: BoxDecoration(
                        color: AppColors.white, //[cite: 23]
                        borderRadius: BorderRadius.circular(24), //[cite: 23]
                        border: Border.all(
                          color: searchError != null
                              ? AppColors.primary
                              : AppColors.black.withOpacity(0.8), //[cite: 23]
                          width: 1.2, //[cite: 23]
                        ),
                      ),
                      child: TextField(
                        controller: _searchController, //[cite: 23]
                        textInputAction: TextInputAction.search, //[cite: 23]
                        onSubmitted: (value) => _navigateToProductList(value),
                        onChanged: (value) {
                          setState(() {
                            currentSearchQuery = value;
                            if (searchError != null) {
                              searchError = null;
                            }
                          });
                        },
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ), //[cite: 23]
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.black,
                            size: 20,
                          ), //[cite: 23]
                          suffixIcon: currentSearchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      currentSearchQuery = '';
                                      searchError = null;
                                    });
                                  },
                                  child: const Icon(
                                    Icons.cancel_outlined,
                                    color: AppColors.black,
                                    size: 18,
                                  ),
                                )
                              : null,
                          border: InputBorder.none, //[cite: 23]
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ), //[cite: 23]
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12), //[cite: 23]
                  GestureDetector(
                    onTap: _handleBackNavigation, //[cite: 23]
                    child: Text(
                      'Cancel', //[cite: 23]
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w500,
                      ), //[cite: 23]
                    ),
                  ),
                ],
              ),

              if (searchError != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 48, top: 6),
                  child: Text(
                    searchError!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 22), //[cite: 23]
              // ================= RECENT SEARCHES =================[cite: 23]
              if (recentSearches.isNotEmpty) ...[
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, //[cite: 23]
                  children: [
                    Text(
                      'Recent Searches', //[cite: 23]
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: 14,
                      ), //[cite: 23]
                    ),
                    GestureDetector(
                      onTap: _clearAllRecentSearches,
                      child: Text(
                        'Clear all', //[cite: 23]
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                          fontSize: 11,
                        ), //[cite: 23]
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), //[cite: 23]
                Wrap(
                  spacing: 8, //[cite: 23]
                  runSpacing: 10, //[cite: 23]
                  children: [
                    for (int i = 0; i < recentSearches.length; i++)
                      _buildRecentChip(
                        label: recentSearches[i],
                        onTap: () => _navigateToProductList(recentSearches[i]),
                        onDelete: () => _removeRecentSearch(i),
                      ),
                  ],
                ),
                const SizedBox(height: 24), //[cite: 23]
              ],

              // ================= TRENDING SEARCHES =================[cite: 23]
              Text(
                'Trending Searches', //[cite: 23]
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 14,
                ), //[cite: 23]
              ),

              const SizedBox(height: 14), //[cite: 23]

              for (final trending in trendingSearches) ...[
                _buildTrendingItem(
                  title: trending['title']!,
                  searches: trending['searches']!,
                  onTap: () => _navigateToProductList(trending['title']),
                ),
                const SizedBox(height: 14), //[cite: 23]
              ],

              const SizedBox(height: 10),

              // ================= SUGGESTED PRODUCTS =================[cite: 23]
              Text(
                'Suggested Products', //[cite: 23]
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 14,
                ), //[cite: 23]
              ),

              const SizedBox(height: 14), //[cite: 23]

              for (int i = 0; i < suggestedProducts.length; i++) ...[
                _buildSuggestedCard(
                  title: suggestedProducts[i]['title'] as String, //[cite: 23]
                  price: suggestedProducts[i]['price'] as String, //[cite: 23]
                  imagePath: suggestedProducts[i]['imagePath'] as String,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ProductDetailScreen(), //[cite: 23]
                      ),
                    );
                  },
                ),
                if (i != suggestedProducts.length - 1)
                  const SizedBox(height: 12), //[cite: 23]
              ],

              const SizedBox(height: 16), //[cite: 23]
            ],
          ),
        ),
      ),
    );
  }

  // ================= HELPER WIDGETS =================[cite: 23]
  Widget _buildRecentChip({
    required String label,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ), //[cite: 23]
        decoration: BoxDecoration(
          color: AppColors.white, //[cite: 23]
          borderRadius: BorderRadius.circular(20), //[cite: 23]
          border: Border.all(
            color: AppColors.black.withOpacity(0.6),
            width: 1,
          ), //[cite: 23]
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, //[cite: 23]
          children: [
            const Icon(
              Icons.access_time,
              size: 15,
              color: AppColors.black,
            ), //[cite: 23]
            const SizedBox(width: 6), //[cite: 23]
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.black,
                fontSize: 11,
              ), //[cite: 23]
            ),
            const SizedBox(width: 6), //[cite: 23]
            GestureDetector(
              onTap: onDelete,
              child: const Icon(
                Icons.close,
                size: 14,
                color: AppColors.black,
              ), //[cite: 23]
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingItem({
    required String title,
    required String searches,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 34, //[cite: 23]
            height: 34, //[cite: 23]
            decoration: const BoxDecoration(
              color: AppColors.pink, //[cite: 23]
              shape: BoxShape.circle, //[cite: 23]
            ),
            child: const Icon(
              Icons.trending_up, //[cite: 23]
              color: AppColors.primary, //[cite: 23]
              size: 18, //[cite: 23]
            ),
          ),
          const SizedBox(width: 12), //[cite: 23]
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ), //[cite: 23]
            ),
          ),
          Text(
            searches,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.muted,
              fontSize: 10,
            ), //[cite: 23]
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedCard({
    required String title,
    required String price,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap, //[cite: 23]
      child: Container(
        padding: const EdgeInsets.all(12), //[cite: 23]
        decoration: BoxDecoration(
          color: AppColors.white, //[cite: 23]
          borderRadius: BorderRadius.circular(18), //[cite: 23]
          border: Border.all(
            color: AppColors.black.withOpacity(0.6),
            width: 1,
          ), //[cite: 23]
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12), //[cite: 23]
              child: SizedBox(
                width: 54, //[cite: 23]
                height: 54, //[cite: 23]
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.muted.withOpacity(0.2),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14), //[cite: 23]
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, //[cite: 23]
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ), //[cite: 23]
                  ),
                  const SizedBox(height: 4), //[cite: 23]
                  Text(
                    price,
                    style: AppTextStyles.price.copyWith(
                      fontSize: 13,
                    ), //[cite: 23]
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.muted,
              size: 20,
            ), //[cite: 23]
          ],
        ),
      ),
    );
  }
}
