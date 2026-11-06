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
import 'MainNavigationScreen.dart';
import 'product_detail_screen.dart';
import 'product_list_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;

  // State variables for search query and validation error[cite: 23]
  String currentSearchQuery = '';
  String? searchError;

  // How many of each show before anything has been typed
  static const int trendingShown = 4;
  static const int suggestionsShown = 3;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: currentSearchQuery);
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
    setState(() {
      currentSearchQuery = term;
    });
    ref.read(recentSearchesProvider.notifier).add(term);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListScreen(searchQuery: term),
      ),
    ); //[cite: 23]
  }

  void _navigateToCategory(ShopCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListScreen(
          categoryId: category.id,
          categoryName: category.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = currentSearchQuery.trim();
    final recentSearches = ref.watch(recentSearchesProvider);

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
              // Typing swaps this and the trending list for the results
              if (query.isEmpty && recentSearches.isNotEmpty) ...[
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
                      onTap: ref.read(recentSearchesProvider.notifier).clear,
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
                    for (final term in recentSearches)
                      _buildRecentChip(
                        label: term,
                        onTap: () => _navigateToProductList(term),
                        onDelete: () => ref
                            .read(recentSearchesProvider.notifier)
                            .remove(term),
                      ),
                  ],
                ),
                const SizedBox(height: 24), //[cite: 23]
              ],

              // ================= TRENDING SEARCHES =================[cite: 23]
              // The database keeps no search history to rank by, so these are
              // the categories on offer, each with its real product count
              if (query.isEmpty) ...[
                Text(
                  'Trending Searches', //[cite: 23]
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: 14,
                  ), //[cite: 23]
                ),

                const SizedBox(height: 14), //[cite: 23]

                ShopAsyncView<List<ShopCategory>>(
                  state: ref.watch(shopCategoriesProvider),
                  placeholderHeight: 120,
                  onRetry: () => ref.invalidate(allCategoriesProvider),
                  builder: (context, categories) => Column(
                    children: [
                      for (final category in categories.take(
                        trendingShown,
                      )) ...[
                        _buildTrendingItem(
                          title: category.name,
                          searches: Formatters.items(category.productCount),
                          onTap: () => _navigateToCategory(category),
                        ),
                        const SizedBox(height: 14), //[cite: 23]
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 10),
              ],

              // ================= SUGGESTED PRODUCTS =================[cite: 23]
              Text(
                query.isEmpty ? 'Suggested Products' : 'Results', //[cite: 23]
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 14,
                ), //[cite: 23]
              ),

              const SizedBox(height: 14), //[cite: 23]

              ShopAsyncView<List<ShopProduct>>(
                state: ref.watch(shopProductsProvider),
                placeholderHeight: 120,
                onRetry: () => ref.invalidate(allProductsProvider),
                builder: (context, products) {
                  final shown = query.isEmpty
                      ? products.take(suggestionsShown).toList()
                      : products
                            .where((product) => product.matches(query))
                            .toList();

                  if (shown.isEmpty) {
                    return Text(
                      query.isEmpty
                          ? 'No products available yet'
                          : 'No products found for "$query"',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (int i = 0; i < shown.length; i++) ...[
                        _buildSuggestedCard(
                          title: shown[i].name, //[cite: 23]
                          price: Formatters.rupeesFromPaise(
                            shown[i].pricePaise,
                          ), //[cite: 23]
                          imagePath: shown[i].image,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  productDocId: shown[i].docId,
                                ), //[cite: 23]
                              ),
                            );
                          },
                        ),
                        if (i != shown.length - 1)
                          const SizedBox(height: 12), //[cite: 23]
                      ],
                    ],
                  );
                },
              ),

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
    required String? imagePath,
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
                child: ShopImage(
                  path: imagePath,
                  fallback: Container(
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
