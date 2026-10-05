import 'package:flutter/material.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../resources/imagestrings.dart'; // Import your image strings file
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  // State variables for orders list
  late final List<Map<String, dynamic>> orders;

  @override
  void initState() {
    super.initState();
    orders = [
      {
        'orderId': '#ORD-89421',
        'title': 'Banarasi Silk Saree',
        'date': '12 Oct 2026',
        'price': '₹2,499',
        'status': 'Delivered',
        'statusColor': AppColors.success,
        'imagePath': image2,
      },
      {
        'orderId': '#ORD-89310',
        'title': 'Kanjivaram Saree',
        'date': '28 Sep 2026',
        'price': '₹3,299',
        'status': 'In Transit',
        'statusColor': const Color(0xFFD49657),
        'imagePath': image3,
      },
      {
        'orderId': '#ORD-88902',
        'title': 'Cotton Daily Saree',
        'date': '15 Sep 2026',
        'price': '₹1,699',
        'status': 'Delivered',
        'statusColor': AppColors.success,
        'imagePath': image4,
      },
      {
        'orderId': '#ORD-87114',
        'title': 'Banarasi Zari Border',
        'date': '02 Aug 2026',
        'price': '₹3,150',
        'status': 'Cancelled',
        'statusColor': const Color(0xFFDC2626),
        'imagePath': image5,
      },
    ];
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
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: SizedBox(
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text('My Orders', style: AppTextStyles.pageTitle),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(
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
                    ),
                  ],
                ),
              ),
            ),

            // ================= ORDERS LIST =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < orders.length; i++) ...[
                      _buildOrderItem(
                        orderId: orders[i]['orderId'],
                        title: orders[i]['title'],
                        date: orders[i]['date'],
                        price: orders[i]['price'],
                        status: orders[i]['status'],
                        statusColor: orders[i]['statusColor'],
                        imagePath: orders[i]['imagePath'],
                      ),
                      if (i != orders.length - 1) const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem({
    required String orderId,
    required String title,
    required String date,
    required String price,
    required String status,
    required Color statusColor,
    required String imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.black.withOpacity(0.65), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderId,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Product Image Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  width: 62,
                  height: 62,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 62,
                      height: 62,
                      color: AppColors.muted.withOpacity(0.2),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.muted,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: AppTextStyles.price.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
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
