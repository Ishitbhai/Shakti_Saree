import 'package:flutter/material.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // State variables for cart items
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
        'swatchColor': AppColors.primary,
      },
      {
        'title': 'Kanjivaram Saree',
        'variant': 'Green | Free Size',
        'price': 3299,
        'quantity': 1,
        'swatchColor': const Color(0xFF008F11),
      },
      {
        'title': 'Cotton Daily Saree',
        'variant': 'Blue | Free Size',
        'price': 1699,
        'quantity': 1,
        'swatchColor': const Color(0xFF7A007A),
      },
    ];
  }

  int get subtotal {
    return cartItems.fold<int>(
      0,
      (sum, item) => sum + ((item['price'] as int) * (item['quantity'] as int)),
    );
  }

  int get totalAmount => subtotal;

  void _removeItem(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
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
    setState(() {
      cartItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppBackButton(
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
                  Column(
                    children: [
                      Text(
                        'My Cart',
                        style: AppTextStyles.pageTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${cartItems.length} items',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  // Delete button on top: Clears all items in the cart
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

            // ================= SCROLLABLE CONTENT =================
            Expanded(
              child: SingleChildScrollView(
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
                        swatchColor: cartItems[i]['swatchColor'] as Color,
                      ),
                      if (i != cartItems.length - 1) const SizedBox(height: 14),
                    ],

                    const SizedBox(height: 24),

                    // ================= PRICE DETAILS CARD =================
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
                            'Subtotal (${cartItems.length} Items)',
                            '₹$subtotal',
                          ),
                          const SizedBox(height: 10),
                          _buildPriceRow(
                            'Delivery Charges',
                            'FREE',
                            isHighlight: true,
                          ),
                          const SizedBox(height: 14),
                          Divider(
                            color: AppColors.muted.withOpacity(0.5),
                            height: 1,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

            // ================= PINNED BOTTOM PLACE ORDER BAR =================
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
                      onPressed: cartItems.isEmpty
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CheckoutScreen(),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
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

  // ================= HELPER WIDGETS =================
  Widget _buildCartItem({
    required int index,
    required String title,
    required String variant,
    required String price,
    required int quantity,
    required Color swatchColor,
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
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: swatchColor,
              borderRadius: BorderRadius.circular(14),
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
