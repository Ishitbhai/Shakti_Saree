import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../../admin/data/api_exception.dart';
import '../../admin/utils/formatters.dart';
import '../data/shop_providers.dart';
import '../data/shop_repository.dart';
import '../models/shop_models.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../widgets/shop_async_view.dart';
import '../widgets/shop_image.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  // State variables for screen titles, labels, delivery rules, and items[cite: 23]
  final String pageTitle = 'My Cart';
  final String deliveryChargeLabel = 'FREE';
  final int deliveryThreshold =
      0; // Free delivery for all active items[cite: 23]

  // The signed-in customer's cart as last read; build keeps it up to date
  List<CartEntry> cartItems = const [];

  ShopRepository get _repository => ref.read(shopRepositoryProvider);

  // A line whose product has gone is not counted or charged for
  int get totalItemCount {
    return cartItems.fold<int>(
      0,
      (sum, item) => sum + (item.product == null ? 0 : item.line.quantity),
    );
  }

  int get subtotal {
    return cartItems.fold<int>(0, (sum, item) => sum + item.lineTotalPaise);
  }

  int get totalAmount => subtotal;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  // Runs a cart write and reports whether it worked. The list itself needs no
  // updating here: Firestore's stream delivers the change, even offline.
  Future<bool> _write(Future<void> Function() change) async {
    try {
      await change();
      return true;
    } on ApiException catch (error) {
      _showMessage(error.message);
      return false;
    }
  }

  Future<void> _removeItem(int index) async {
    final item = cartItems[index];
    final removedTitle = item.product?.name ?? 'Item';
    if (await _write(() => _repository.removeLine(item.line))) {
      _showMessage('$removedTitle removed from cart');
    }
  }

  Future<void> _updateQuantity(int index, int delta) async {
    final item = cartItems[index];
    final product = item.product;
    final newQty = item.line.quantity + delta;
    if (product == null || newQty <= 0) return;

    await _write(() => _repository.setQuantity(item.line, product, newQty));
  }

  Future<void> _clearCart() async {
    if (cartItems.isEmpty) return;

    final lines = [for (final item in cartItems) item.line];
    if (await _write(() => _repository.clearCart(lines))) {
      _showMessage('Cart cleared');
    }
  }

  void _handleBackNavigation() {
    final tabController = DefaultTabController.maybeOf(context);
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else if (tabController != null) {
      tabController.animateTo(0);
    }
  }

  void _handlePlaceOrder() {
    if (cartItems.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final categoryNames = ref.watch(categoryNamesByIdProvider);
    cartItems = cart.value ?? const [];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================[cite: 23]
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppBackButton(onTap: _handleBackNavigation),
                  Column(
                    children: [
                      Text(
                        pageTitle,
                        style: AppTextStyles.pageTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalItemCount items',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  // Delete button on top: Clears all items in the cart[cite: 23]
                  GestureDetector(
                    onTap: _clearCart,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.black.withOpacity(0.65),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================= SCROLLABLE CONTENT =================[cite: 23]
            Expanded(
              child: ShopAsyncView<List<CartEntry>>(
                state: cart,
                onRetry: () => ref.invalidate(cartLinesProvider),
                builder: (context, _) => cartItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: AppColors.muted.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your cart is empty',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < cartItems.length; i++) ...[
                              _buildCartItem(
                                index: i,
                                title:
                                    cartItems[i].product?.name ??
                                    'No longer available',
                                // The database holds no colour or size to show
                                variant:
                                    categoryNames[cartItems[i]
                                        .product
                                        ?.categoryId] ??
                                    '',
                                price: Formatters.rupeesFromPaise(
                                  cartItems[i].product?.pricePaise ?? 0,
                                ),
                                quantity: cartItems[i].line.quantity,
                                imagePath: cartItems[i].product?.image,
                              ),
                              if (i != cartItems.length - 1)
                                const SizedBox(height: 14),
                            ],

                            const SizedBox(height: 24),

                            // ================= PRICE DETAILS CARD =================[cite: 23]
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
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
                                  Text(
                                    'Price Details',
                                    style: AppTextStyles.sectionTitle.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildPriceRow(
                                    'Subtotal ($totalItemCount Items)',
                                    Formatters.rupeesFromPaise(subtotal),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildPriceRow(
                                    'Delivery Charges',
                                    deliveryChargeLabel,
                                    isHighlight: true,
                                  ),
                                  const SizedBox(height: 14),
                                  Divider(
                                    color: AppColors.muted.withOpacity(0.5),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Amount',
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        Formatters.rupeesFromPaise(totalAmount),
                                        style: AppTextStyles.price.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
              ),
            ),

            // ================= PINNED BOTTOM PLACE ORDER BAR =================[cite: 23]
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(
                    color: AppColors.muted.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.rupeesFromPaise(totalAmount),
                          style: AppTextStyles.pageTitle.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    width: 180,
                    child: ElevatedButton(
                      onPressed: cartItems.isEmpty ? null : _handlePlaceOrder,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.muted.withOpacity(
                          0.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Place Order',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPER WIDGETS =================[cite: 23]
  Widget _buildCartItem({
    required int index,
    required String title,
    required String variant,
    required String price,
    required int quantity,
    required String? imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.black.withOpacity(0.75), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 74,
              height: 74,
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
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeItem(index),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  variant,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.muted,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: AppTextStyles.price.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.black.withOpacity(0.65),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _updateQuantity(index, -1),
                            child: const Text(
                              '-',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$quantity',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _updateQuantity(index, 1),
                            child: const Text(
                              '+',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String amount, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.muted,
            fontSize: 11.5,
          ),
        ),
        Text(
          amount,
          style: AppTextStyles.bodySmall.copyWith(
            color: isHighlight ? AppColors.success : AppColors.black,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}
