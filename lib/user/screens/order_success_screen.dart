import 'package:flutter/material.dart';
import 'package:shakti_saree/user/screens/my_orders_screen.dart';

import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../widgets/app_back_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: AppBackButton(),
                ),
              ),

              const Spacer(),
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withOpacity(0.08),
                ),
                child: Center(
                  child: Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withOpacity(0.15),
                    ),
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text('Order Placed!', style: AppTextStyles.successTitle),

              const SizedBox(height: 8),

              Text(
                'Order successfully',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
              ),

              const SizedBox(height: 2),

              Text(
                'Thank you for shopping with Shakti Saree.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: AppColors.black, width: 1),
                ),
                child: Column(
                  children: [
                    _buildOrderDetailRow(
                      icon: Icons.view_in_ar,
                      title: 'Order ID',
                      value: '#SS20260726',
                    ),

                    const Divider(color: AppColors.muted, height: 14),

                    _buildOrderDetailRow(
                      icon: Icons.currency_rupee,
                      title: 'Amount',
                      value: '₹6,297',
                    ),

                    const Divider(color: AppColors.muted, height: 14),

                    _buildOrderDetailRow(
                      icon: Icons.local_shipping_outlined,
                      title: 'Delivery',
                      value: 'Tue, 29 Jul 2026',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyOrdersScreen(),
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
                    'Track My Order',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Continue Shopping',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.pink,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),

        const SizedBox(width: 12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),

            const SizedBox(height: 2),

            Text(
              value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
