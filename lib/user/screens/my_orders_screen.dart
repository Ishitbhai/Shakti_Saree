import 'package:flutter/material.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../widgets/app_bottom_nav_bar.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: SizedBox(
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text('My Orders', style: AppTextStyles.pageTitle),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(),
                    ),
                  ],
                ),
              ),
            ),
            // ================= ORDERS LIST =================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                children: [
                  _buildOrderCard(
                    orderNumber: '#1',
                    statusText: 'Out for delivery',
                    statusBgColor: AppColors.peachStatus,
                    statusTextColor: AppColors.black,
                    productTitle: 'Banarasi Silk Saree',
                    imageBgColor: AppColors.primary,
                    quantity: 'Qty 1',
                    price: '₹2,499',
                    orderDate: 'Ordered on 26 Jul 2026',
                  ),
                  const SizedBox(height: 16),
                  _buildOrderCard(
                    orderNumber: '#2',
                    statusText: 'Delivered',
                    statusBgColor: AppColors.greenStatus,
                    statusTextColor: AppColors.black,
                    productTitle: 'Kanjivaram Pure Silk',
                    imageBgColor: AppColors.yellowStatus,
                    quantity: 'Qty 1',
                    price: '₹3,299',
                    orderDate: 'Ordered on 26 Jul 2026',
                  ),
                  const SizedBox(height: 16),
                  _buildOrderCard(
                    orderNumber: '#3',
                    statusText: 'Delivered',
                    statusBgColor: AppColors.greenStatus,
                    statusTextColor: AppColors.black,
                    productTitle: 'Cotton Daily Saree',
                    imageBgColor: AppColors.greenStatus,
                    quantity: 'Qty 2',
                    price: '₹3,398',
                    orderDate: 'Ordered on 26 Jul 2026',
                  ),
                  const SizedBox(height: 16),
                  _buildOrderCard(
                    orderNumber: '#4',
                    statusText: 'Cancelled',
                    statusBgColor: AppColors.pinkLight,
                    statusTextColor: AppColors.primary,
                    productTitle: 'Georgette Party Saree',
                    imageBgColor: AppColors.blueStatus,
                    quantity: 'Qty 1',
                    price: '₹1,899',
                    orderDate: 'Ordered on 26 Jul 2026',
                  ),
                  const SizedBox(height: 16),
                  _buildOrderCard(
                    orderNumber: '#5',
                    statusText: 'Out for delivery',
                    statusBgColor: AppColors.peachStatus,
                    statusTextColor: AppColors.black,
                    productTitle: 'Banarasi Silk Saree',
                    imageBgColor: AppColors.primary,
                    quantity: 'Qty 1',
                    price: '₹2,499',
                    orderDate: 'Ordered on 26 Jul 2026',
                  ),
                  const SizedBox(height: 16),
                  _buildOrderCard(
                    orderNumber: '#6',
                    statusText: 'Delivered',
                    statusBgColor: AppColors.greenStatus,
                    statusTextColor: AppColors.black,
                    productTitle: 'Kanjivaram Pure Silk',
                    imageBgColor: AppColors.yellowStatus,
                    quantity: 'Qty 1',
                    price: '₹3,299',
                    orderDate: 'Ordered on 26 Jul 2026',
                  ),
                  const SizedBox(height: 16),
                  _buildOrderCard(
                    orderNumber: '#7',
                    statusText: 'Delivered',
                    statusBgColor: AppColors.greenStatus,
                    statusTextColor: AppColors.black,
                    productTitle: 'Cotton Daily Saree',
                    imageBgColor: AppColors.greenStatus,
                    quantity: 'Qty 2',
                    price: '₹3,398',
                    orderDate: 'Ordered on 26 Jul 2026',
                  ),
                  const SizedBox(height: 16),
                  _buildOrderCard(
                    orderNumber: '#8',
                    statusText: 'Cancelled',
                    statusBgColor: AppColors.pinkLight,
                    statusTextColor: AppColors.primary,
                    productTitle: 'Georgette Party Saree',
                    imageBgColor: AppColors.blueStatus,
                    quantity: 'Qty 1',
                    price: '₹1,899',
                    orderDate: 'Ordered on 26 Jul 2026',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),

      // ================= BOTTOM NAVIGATION =================
      bottomNavigationBar: const AppBottomNavBar(selectedIndex: 3),
    );
  }

  // ================= HELPER WIDGETS =================
  Widget _buildOrderCard({
    required String orderNumber,
    required String statusText,
    required Color statusBgColor,
    required Color statusTextColor,
    required String productTitle,
    required Color imageBgColor,
    required String quantity,
    required String price,
    required String orderDate,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.black, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Order Index & Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderNumber,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  statusText,
                  style: AppTextStyles.caption.copyWith(
                    color: statusTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: AppColors.muted, height: 1),
          const SizedBox(height: 12),

          // Product Details Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product Preview Square
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: imageBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              const SizedBox(width: 12),

              // Product Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productTitle,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$quantity • $price',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      orderDate,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
