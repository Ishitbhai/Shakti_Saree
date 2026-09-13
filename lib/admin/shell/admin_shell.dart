import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../more/more_screen.dart';
import '../customers/customers_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../orders/orders_screen.dart';
import '../products/products_screen.dart';
import '../shared/admin_tab.dart';
import 'widgets/admin_bottom_nav.dart';

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
