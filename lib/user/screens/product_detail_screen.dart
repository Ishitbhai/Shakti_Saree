import 'package:flutter/material.dart';

import '../resources/imagestrings.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'MainNavigationScreen.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        image: DecorationImage(
                          image: AssetImage(image1),
                          fit: BoxFit.cover,
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
                                  'Banarasi Silk Saree\nwithGolden Zari Border',
                                  style: AppTextStyles.pageTitle.copyWith(
                                    fontSize: 18,
                                    height: 1.3,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'In Stock',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Description
                          Text(
                            'A Banarasi Silk Saree with a Golden Zari Border is a masterpiece of Indian textile heritage.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.black.withOpacity(0.85),
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Price & Discount Pill
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '₹2,499',
                                style: AppTextStyles.pageTitle.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '₹4,999',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.muted,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.peachStatus,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '50% OFF',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
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
                                'Free delivery by Tue, 29 Jul',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'You will get free delivery for this order',
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
                      // Add to Cart Button (Does Nothing)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {},
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
                              'Add to Cart',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.black,
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
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MainNavigationScreen(
                                        initialIndex: 2,
                                      ),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Buy Now',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.white,
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
}
