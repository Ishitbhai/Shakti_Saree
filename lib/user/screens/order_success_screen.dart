import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakti_saree/user/screens/MainNavigationScreen.dart';

import '../../admin/data/firestore/firestore_schema.dart';
import '../../admin/data/providers/backend_providers.dart';
import '../data/shop_providers.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../widgets/app_back_button.dart';

class OrderSuccessScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final String? amount;
  final String? deliveryDate;

  const OrderSuccessScreen({
    super.key,
    this.orderId,
    this.amount,
    this.deliveryDate,
  });

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen> {
  late String orderId;
  late String amount;
  late String deliveryDate;

  final List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(DateTime dt) {
    final weekday = _weekdays[dt.weekday - 1];
    final month = _months[dt.month - 1];
    return '$weekday, ${dt.day} $month ${dt.year}';
  }

  @override
  void initState() {
    super.initState();
    // Default 4 days standard delivery from placement
    final estimatedDelivery = DateTime.now().add(const Duration(days: 4));

    orderId = widget.orderId ?? '#ORD_PENDING';
    amount = widget.amount ?? '₹0';
    deliveryDate = widget.deliveryDate ?? _formatDate(estimatedDelivery);
  }

  @override
  Widget build(BuildContext context) {
    // If orderId was not passed directly, fetch the latest order placed by current user
    if (widget.orderId == null) {
      final uid = ref.watch(customerUidProvider);
      final db = ref.watch(firestoreProvider);

      if (uid != null && db != null) {
        db
            .collection(Fs.orders)
            .where(Fs.userId, isEqualTo: uid)
            .orderBy(Fs.createdAt, descending: true)
            .limit(1)
            .snapshots()
            .listen((snapshot) {
              if (snapshot.docs.isNotEmpty && mounted) {
                final data = snapshot.docs.first.data();
                final String fetchedId = Fs.stringOf(data[Fs.orderId]);
                final num fetchedAmount = data[Fs.totalAmount] ?? 0;
                final dynamic createdTimestamp = data[Fs.createdAt];

                DateTime baseDate = DateTime.now();
                if (createdTimestamp is Timestamp) {
                  baseDate = createdTimestamp.toDate();
                }

                setState(() {
                  if (fetchedId.isNotEmpty) orderId = '#$fetchedId';
                  amount = '₹$fetchedAmount';
                  deliveryDate = _formatDate(
                    baseDate.add(const Duration(days: 4)),
                  );
                });
              }
            });
      }
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: AppBackButton(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MainNavigationScreen(initialIndex: 0),
                        ),
                        (route) => false,
                      );
                    },
                  ),
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
                      value: orderId,
                    ),

                    const Divider(color: AppColors.muted, height: 14),

                    _buildOrderDetailRow(
                      icon: Icons.currency_rupee,
                      title: 'Amount',
                      value: amount,
                    ),

                    const Divider(color: AppColors.muted, height: 14),

                    _buildOrderDetailRow(
                      icon: Icons.local_shipping_outlined,
                      title: 'Delivery',
                      value: deliveryDate,
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
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MainNavigationScreen(initialIndex: 3),
                      ),
                      (route) => false,
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
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MainNavigationScreen(initialIndex: 0),
                      ),
                      (route) => false,
                    );
                  },
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
          decoration: const BoxDecoration(
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
