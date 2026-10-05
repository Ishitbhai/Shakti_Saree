import 'package:flutter/material.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../resources/imagestrings.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // State variables for screen titles, labels, delivery rules, and items[cite: 23]
  final String pageTitle = 'My Cart';
  final String deliveryChargeLabel = 'FREE';
  final int deliveryThreshold =
      0; // Free delivery for all active items[cite: 23]

  late List<Map<String, dynamic>> cartItems;

  @override
  void initState() {
    super.initState();
    cartItems = [
      {
        'title': 'Banarasi Silk Saree',
        'variant': 'Maroon | Free Size',
        'price': 2499,
        'quantity': 1,
        'imagePath': image1,
      },
      {
        'title': 'Kanjivaram Saree',
        'variant': 'Green | Free Size',
        'price': 3299,
        'quantity': 1,
        'imagePath': image2,
      },
      {
        'title': 'Cotton Daily Saree',
        'variant': 'Blue | Free Size',
        'price': 1699,
        'quantity': 1,
        'imagePath': image3,
      },
    ];
  }

  int get totalItemCount {
    return cartItems.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );
  }

  int get subtotal {
    return cartItems.fold<int>(
      0,
      (sum, item) => sum + ((item['price'] as int) * (item['quantity'] as int)),
    );
  }

  int get totalAmount => subtotal;

  void _removeItem(int index) {
    final removedTitle = cartItems[index]['title'];
    setState(() {
      cartItems.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$removedTitle removed from cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQty = (cartItems[index]['quantity'] as int) + delta;
      if (newQty > 0) {
        cartItems[index]['quantity'] = newQty;
      }
    });
  }

  void _clearCart() {
    if (cartItems.isEmpty) return;

    setState(() {
      cartItems.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cart cleared'),
        duration: const Duration(seconds: 1),
      ),
    );
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
              child: cartItems.isEmpty
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
                              title: cartItems[i]['title'] as String,
                              variant: cartItems[i]['variant'] as String,
                              price: '₹${cartItems[i]['price']}',
                              quantity: cartItems[i]['quantity'] as int,
                              imagePath: cartItems[i]['imagePath'] as String,
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
                                  '₹$subtotal',
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
                                      '₹$totalAmount',
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
                          '₹$totalAmount',
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
    required String imagePath,
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
