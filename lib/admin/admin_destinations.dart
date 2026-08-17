import 'package:flutter/material.dart';

import 'screens/categories_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/products_screen.dart';
import 'screens/settings_screen.dart';

/// One entry in the admin sidebar.
class AdminDestination {
  const AdminDestination({
    required this.label,
    required this.icon,
    required this.screenBuilder,
  });

  final String label;
  final IconData icon;
  final Widget Function() screenBuilder;
}

/// Sidebar order. Add, remove or reorder entries here — the shell and the
/// sidebar both read from this one list.
const List<AdminDestination> adminDestinations = [
  AdminDestination(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    screenBuilder: DashboardScreen.new,
  ),
  AdminDestination(
    label: 'Products',
    icon: Icons.inventory_2_outlined,
    screenBuilder: ProductsScreen.new,
  ),
  AdminDestination(
    label: 'Categories',
    icon: Icons.category_outlined,
    screenBuilder: CategoriesScreen.new,
  ),
  AdminDestination(
    label: 'Orders',
    icon: Icons.receipt_long_outlined,
    screenBuilder: OrdersScreen.new,
  ),
  AdminDestination(
    label: 'Customers',
    icon: Icons.people_outline,
    screenBuilder: CustomersScreen.new,
  ),
  AdminDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    screenBuilder: SettingsScreen.new,
  ),
];
