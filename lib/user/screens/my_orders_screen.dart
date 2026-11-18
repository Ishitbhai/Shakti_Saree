import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../../admin/data/firestore/firestore_schema.dart';
import '../../admin/data/providers/backend_providers.dart';
import '../data/shop_providers.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
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

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return '${dt.day.toString().padLeft(2, '0')} ${_months[dt.month - 1]} ${dt.year}';
    }
    return 'Recent';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'in transit':
      case 'shipped':
        return const Color(0xFFD49657);
      case 'cancelled':
        return const Color(0xFFDC2626);
      case 'pending':
      default:
        return AppColors.primary;
    }
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 62,
      height: 62,
      color: AppColors.muted.withOpacity(0.15),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.muted,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(customerUidProvider);
    final db = ref.watch(firestoreProvider);

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

            // ================= ORDERS STREAM =================
            Expanded(
              child: uid == null || db == null
                  ? const Center(
                      child: Text('Please log in to view your orders.'),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: db
                          .collection(Fs.orders)
                          .where(Fs.userId, isEqualTo: uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                'Failed to load orders: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }

                        // Local sort descending avoids composite index requirements
                        final orderDocs =
                            List<QueryDocumentSnapshot>.from(
                              snapshot.data?.docs ?? [],
                            )..sort((a, b) {
                              final dataA = a.data() as Map<String, dynamic>?;
                              final dataB = b.data() as Map<String, dynamic>?;
                              final tA = dataA?['created_at'];
                              final tB = dataB?['created_at'];
                              if (tA is Timestamp && tB is Timestamp) {
                                return tB.compareTo(tA);
                              }
                              return 0;
                            });

                        if (orderDocs.isEmpty) {
                          return Center(
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
                                  'No orders placed yet',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          itemCount: orderDocs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final orderData =
                                (orderDocs[index].data()
                                    as Map<String, dynamic>?) ??
                                {};
                            final String orderId = Fs.stringOf(
                              orderData[Fs.orderId],
                            );
                            final String status =
                                Fs.stringOf(orderData['order_status']).isEmpty
                                ? 'Pending'
                                : Fs.stringOf(orderData['order_status']);
                            final num totalAmount =
                                orderData[Fs.totalAmount] ?? 0;
                            final String formattedDate = _formatDate(
                              orderData['created_at'],
                            );

                            return _buildOrderCard(
                              db: db,
                              orderId: orderId,
                              status: status,
                              price: '₹$totalAmount',
                              date: formattedDate,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required FirebaseFirestore db,
    required String orderId,
    required String status,
    required String price,
    required String date,
  }) {
    final statusColor = _getStatusColor(status);

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('order_items')
          .where('order_id', isEqualTo: orderId)
          .snapshots(),
      builder: (context, snapshot) {
        final items = snapshot.data?.docs ?? [];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.black.withOpacity(0.65),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Order ID and Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    orderId.startsWith('#') ? orderId : '#$orderId',
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

              // Items List
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Loading items...',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      Builder(
                        builder: (context) {
                          final itemData =
                              items[i].data() as Map<String, dynamic>?;
                          final productId = Fs.stringOf(
                            itemData?['product_id'],
                          );
                          final quantity = itemData?['quantity'] ?? 1;
                          final priceValue = itemData?['price'];
                          final itemPrice = priceValue != null
                              ? '₹$priceValue'
                              : price;

                          return FutureBuilder<QuerySnapshot>(
                            future: db
                                .collection('products')
                                .where('product_id', isEqualTo: productId)
                                .limit(1)
                                .get(),
                            builder: (context, prodSnapshot) {
                              String title = 'Product: $productId';
                              String imagePath = '';

                              if (prodSnapshot.hasData &&
                                  prodSnapshot.data!.docs.isNotEmpty) {
                                final prodData =
                                    prodSnapshot.data!.docs.first.data()
                                        as Map<String, dynamic>?;
                                title = Fs.stringOf(prodData?['product_name']);
                                if (title.isEmpty) {
                                  title = 'Product: $productId';
                                }
                                imagePath = Fs.stringOf(prodData?['image']);
                              }

                              return Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 62,
                                      height: 62,
                                      child: imagePath.isNotEmpty
                                          ? (imagePath.startsWith('http')
                                                ? Image.network(
                                                    imagePath,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) =>
                                                            _buildFallbackImage(),
                                                  )
                                                : Image.asset(
                                                    imagePath,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) =>
                                                            _buildFallbackImage(),
                                                  ))
                                          : _buildFallbackImage(),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Qty: $quantity • $date',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          itemPrice,
                                          style: AppTextStyles.price.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      if (i != items.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: AppColors.muted, height: 1),
                        ),
                    ],
                  ],
                ),

              // Total Order summary when multiple items are present
              if (items.length > 1) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Total Order: ',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      price,
                      style: AppTextStyles.price.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
