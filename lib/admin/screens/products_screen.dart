import 'package:flutter/material.dart';

import '../widgets/page_placeholder.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PagePlaceholder(
      title: 'Products',
      note: 'Saree listing, search/filter and the add-product form go here.',
    );
  }
}
