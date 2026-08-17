import 'package:flutter/material.dart';

import 'screens/customers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/more_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/products_screen.dart';

/// One tab in the admin bottom navigation bar.
class AdminDestination {
  const AdminDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screenBuilder,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() screenBuilder;
}

/// Bottom bar tabs, in order.
///
/// Five is the practical ceiling on a phone before labels start truncating —
/// everything else belongs behind the More tab, not here.
const List<AdminDestination> adminTabs = [
  AdminDestination(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    screenBuilder: DashboardScreen.new,
  ),
  AdminDestination(
    label: 'Products',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    screenBuilder: ProductsScreen.new,
  ),
  AdminDestination(
    label: 'Orders',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    screenBuilder: OrdersScreen.new,
  ),
  AdminDestination(
    label: 'Customers',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    screenBuilder: CustomersScreen.new,
  ),
  AdminDestination(
    label: 'More',
    icon: Icons.more_horiz,
    selectedIcon: Icons.more_horiz,
    screenBuilder: MoreScreen.new,
  ),
];
