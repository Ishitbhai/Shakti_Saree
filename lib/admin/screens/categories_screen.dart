import 'package:flutter/material.dart';

import '../widgets/page_placeholder.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PagePlaceholder(
      title: 'Categories',
      note: 'Category list with create, rename and delete actions goes here.',
    );
  }
}
