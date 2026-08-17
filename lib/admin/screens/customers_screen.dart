import 'package:flutter/material.dart';

import '../widgets/page_placeholder.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PagePlaceholder(
      title: 'Customers',
      note: 'Customer list and per-customer order history go here.',
    );
  }
}
