import 'package:flutter/material.dart';

import '../widgets/page_placeholder.dart';

/// Pushed from the More tab, so it carries its own app bar.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: const PagePlaceholder(
        title: 'Categories',
        note: 'Category list with create, rename and delete actions goes here.',
      ),
    );
  }
}
