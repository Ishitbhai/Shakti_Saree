import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../../admin/data/api_exception.dart';
import '../../admin/utils/formatters.dart';
import '../data/shop_providers.dart';
import '../models/shop_models.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../widgets/shop_async_view.dart';
import '../widgets/shop_image.dart';
import 'MainNavigationScreen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productDocId});

  /// The product's document id in the `products` collection.
  final String productDocId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  // State variables for delivery and cart state. Delivery is free on every
  // order, but the database holds no dates to promise one by.
  final String deliveryDateText = 'Free delivery';
  final String deliverySubtext = 'You will get free delivery for this order';

  // True while a cart write is in flight, to disable the buttons
  bool _cartBusy = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Adds the product, or takes it back out if it is already in the cart
  Future<void> _handleAddToCart(ShopProduct product, CartEntry? inCart) async {
    setState(() => _cartBusy = true);
    String message;
    try {
      final repository = ref.read(shopRepositoryProvider);
      if (inCart == null) {
        await repository.addToCart(product);
        message = 'Added to Cart';
      } else {
        await repository.removeLine(inCart.line);
        message = 'Removed from Cart';
      }
    } on ApiException catch (error) {
      message = error.message;
    }
    if (!mounted) return;

    setState(() => _cartBusy = false);
    _showMessage(message);
  }

  // Makes sure the product is in the cart, then opens the cart
  Future<void> _handleBuyNow(ShopProduct product, CartEntry? inCart) async {
    if (inCart == null) {
      setState(() => _cartBusy = true);
      try {
        await ref.read(shopRepositoryProvider).addToCart(product);
      } on ApiException catch (error) {
        if (mounted) _showMessage(error.message);
        return;
      } finally {
        if (mounted) setState(() => _cartBusy = false);
      }
    }
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(initialIndex: 2),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider(widget.productDocId));
    final product = state.value;
    if (product == null) return _buildUnavailable(state);

    final productImage = ShopImage.providerFor(product.image);
    final title = product.name;
    final isInStock = product.inStock;
    final stockStatus = isInStock ? 'In Stock' : 'Out of Stock';
    final description = product.description;
    final price = Formatters.rupeesFromPaise(product.pricePaise);

    final inCart = ref
        .watch(cartProvider)
        .value
        ?.where((entry) => entry.line.productId == product.productId)
        .firstOrNull;
    final isAddedToCart = inCart != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // ================= SCROLLABLE CONTENT (IMAGE + DETAILS) =================
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Product Image Preview
                    Container(
                      width: double.infinity,
                      height: 380,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        image: productImage == null
                            ? null
                            : DecorationImage(
                                image: productImage,
                                fit: BoxFit.cover,
                                // A file that will not load leaves the colour
                                onError: (error, stackTrace) {},
                              ),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, top: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppColors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Details Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & In Stock
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: AppTextStyles.pageTitle.copyWith(
                                    fontSize: 18,
                                    height: 1.3,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                stockStatus,
                                style: AppTextStyles.caption.copyWith(
                                  color: isInStock
                                      ? AppColors.black
                                      : AppColors.muted,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Description
                          Text(
                            description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.black.withOpacity(0.85),
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Price
                          Text(
                            price,
                            style: AppTextStyles.pageTitle.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================= PINNED BOTTOM SECTION =================
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              decoration: const BoxDecoration(color: AppColors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Free Delivery Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.black.withOpacity(0.75),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deliveryDateText,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                deliverySubtext,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.muted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      // Add to Cart Button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed:
                                _cartBusy || !(isInStock || isAddedToCart)
                                ? null
                                : () => _handleAddToCart(product, inCart),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              isAddedToCart ? 'Added' : 'Add to Cart',
                              style: AppTextStyles.button.copyWith(
                                color: isInStock || isAddedToCart
                                    ? AppColors.black
                                    : AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Buy Now Button (Redirects to Cart inside MainNavigationScreen)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _cartBusy || !isInStock
                                ? null
                                : () => _handleBuyNow(product, inCart),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor: AppColors.muted
                                  .withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Buy Now',
                              style: AppTextStyles.button.copyWith(
                                color: isInStock
                                    ? AppColors.white
                                    : AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading, failed, or the listing has gone. With no picture on screen to
  // carry the back button, it sits at the top on its own.
  Widget _buildUnavailable(AsyncValue<ShopProduct?> state) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppBackButton(),
              ),
            ),
            Expanded(
              child: ShopAsyncView<ShopProduct?>(
                state: state,
                onRetry: () =>
                    ref.invalidate(productProvider(widget.productDocId)),
                builder: (context, _) => Center(
                  child: Text(
                    'This product is no longer available',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
