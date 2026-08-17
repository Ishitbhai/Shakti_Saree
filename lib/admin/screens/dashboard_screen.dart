import 'package:flutter/material.dart';

import '../widgets/page_placeholder.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PagePlaceholder(
      title: 'Dashboard',
      note: 'Stat cards, sales chart and recent orders go here.',
    );
  }
}
