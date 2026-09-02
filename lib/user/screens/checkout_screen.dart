import 'package:flutter/material.dart';

import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../widgets/app_back_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String selectedPayment = 'UPI';

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
                    Text('Checkout', style: AppTextStyles.pageTitle),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            // ================= PROGRESS INDICATOR =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              child: Column(
                children: [
                  // Circles and connecting lines
                  SizedBox(
                    height: 25,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Lines behind circles
                        Positioned(
                          left: 55,
                          right: 55,
                          top: 12,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1.5,
                                  color: AppColors.primary,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Circles
                        Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: _buildStepCircle(
                                  icon: Icons.check,
                                  isActive: true,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: _buildStepCircle(
                                  number: '2',
                                  isActive: true,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: _buildStepCircle(
                                  number: '3',
                                  isActive: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Labels - EXACTLY CENTERED BELOW CIRCLES
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            'Address',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Center(
                          child: Text(
                            'Payment',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Center(
                          child: Text(
                            'Confirm',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ================= SCROLLABLE CONTENT =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= DELIVERY ADDRESS =================
                    Text('Delivery Address', style: AppTextStyles.sectionTitle),

                    const SizedBox(height: 10),

                    // Address Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selected Radio
                          _buildRadioButton(true),

                          const SizedBox(width: 12),

                          // Address Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Ishit Kumar',
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.pink,
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Text(
                                        'HOME',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),

                                    const Spacer(),

                                    const Icon(
                                      Icons.edit_outlined,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  '301, Shakti Complex, Kalawad Road,\n'
                                  'Rajkot, Gujarat - 360005',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  '+91 12345 67890',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ================= ADD NEW ADDRESS =================
                    GestureDetector(
                      onTap: () {},
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add,
                            size: 20,
                            color: AppColors.black,
                          ),

                          const SizedBox(width: 5),

                          Text(
                            'Add New Address',
                            style: AppTextStyles.action.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ================= PAYMENT METHOD =================
                    Text('Payment Method', style: AppTextStyles.sectionTitle),

                    const SizedBox(height: 10),

                    // UPI
                    _buildPaymentOption(
                      title: 'UPI / GPay / PhonePe',
                      value: 'UPI',
                      icon: Icons.phone_outlined,
                    ),

                    const SizedBox(height: 12),

                    // COD
                    _buildPaymentOption(
                      title: 'Cash on Delivery',
                      value: 'COD',
                      icon: Icons.view_in_ar,
                    ),
                  ],
                ),
              ),
            ),

            // ================= BOTTOM PAYMENT =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.muted, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Total Amount
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Payable',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text('₹6,297', style: AppTextStyles.price),
                      ],
                    ),
                  ),

                  // Pay Button
                  SizedBox(
                    width: 180,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigation will be added later
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Pay Now', style: AppTextStyles.payNow),
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

  // ================= STEP CIRCLE =================

  Widget _buildStepCircle({
    IconData? icon,
    String? number,
    required bool isActive,
  }) {
    return Container(
      width: 25,
      height: 25,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.muted,
        shape: BoxShape.circle,
      ),
      child: icon != null
          ? const Icon(Icons.check, color: AppColors.white, size: 15)
          : Text(
              number ?? '',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  // ================= RADIO BUTTON =================

  Widget _buildRadioButton(bool isSelected) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.muted,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }

  // ================= PAYMENT OPTION =================

  Widget _buildPaymentOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final bool isSelected = selectedPayment == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPayment = value;
        });
      },
      child: Container(
        width: double.infinity,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.muted,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _buildRadioButton(isSelected),

            const SizedBox(width: 14),

            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.muted,
              size: 20,
            ),

            const SizedBox(width: 14),

            Text(title, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
