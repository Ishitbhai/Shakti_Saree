import 'package:flutter/material.dart';

import '../widgets/page_placeholder.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PagePlaceholder(
      title: 'Orders',
      note: 'Order table, status filters and the order detail view go here.',
    );
  }
}
