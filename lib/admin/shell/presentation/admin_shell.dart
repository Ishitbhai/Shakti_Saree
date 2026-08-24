import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../products/presentation/products_screen.dart';
import 'widgets/admin_bottom_nav.dart';

/// Holds the admin tabs and the bar that switches between them.
///
/// An [IndexedStack] keeps each tab alive, so scroll position and any
/// half-typed input survive switching away and back. Replaced by go_router
/// once real navigation lands.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          ProductsScreen(),
          _NotBuiltYet(title: 'Orders'),
          _NotBuiltYet(title: 'Users'),
          _NotBuiltYet(title: 'More'),
        ],
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: _index,
        onSelect: (index) => setState(() => _index = index),
      ),
    );
  }
}

/// Stand-in for a tab whose screen has not been designed yet.
class _NotBuiltYet extends StatelessWidget {
  const _NotBuiltYet({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text(title, style: AppTypography.sectionTitle)),
    );
  }
}
