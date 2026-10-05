import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../styles/app_colors.dart';
import 'more_screen.dart';
import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'products_screen.dart';
import '../data/admin_tab.dart';
import '../widgets/navigation/admin_bottom_nav.dart';

/// Holds the admin tabs and the bar that switches between them.
///
/// An [IndexedStack] keeps each tab alive, so scroll position and any
/// half-typed input survive switching away and back. Replaced by go_router
/// once real navigation lands.
///
/// Which tab is showing lives in [adminTabProvider] rather than here, so the
/// screens inside a tab can move between them too.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(adminTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: index,
        children: const [
          DashboardScreen(),
          ProductsScreen(),
          OrdersScreen(),
          CustomersScreen(),
          MoreScreen(),
        ],
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: index,
        onSelect: ref.read(adminTabProvider.notifier).select,
      ),
    );
  }
}
