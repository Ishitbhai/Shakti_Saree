import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/widgets/admin_bottom_nav.dart';
import '../domain/dashboard_order.dart';
import 'widgets/brand_monogram.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/recent_orders_section.dart';
import 'widgets/stat_grid.dart';

/// The admin dashboard: header, stat grid, brand monogram and recent orders.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  /// Exact height of the maroon block.
  ///
  /// Sized so the text (which starts at the status-bar inset + 16) always
  /// clears the cards by at least [minCardGap], including on a notched phone
  /// at a 1.3 text scale — the worst case measured needs 214.
  static const double headerHeight = 220;

  /// How far the cards hang past the header's bottom edge.
  static const double cardOverlap = 40;

  /// Required clearance between the date line and the top card.
  static const double minCardGap = 12;

  /// Where the grid starts, measured from the top of the stack.
  static const double gridTop = headerHeight - cardOverlap;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  /// Hardcoded until the repository lands in Phase 6.
  static const List<DashboardOrder> _recentOrders = [
    DashboardOrder(
      id: '#SS20260726',
      customer: 'Priyanshu K.',
      itemCount: 3,
      amountPaise: 629700,
      status: OrderStatus.isNew,
    ),
    DashboardOrder(
      id: '#SS20260725',
      customer: 'Vivek M.',
      itemCount: 3,
      amountPaise: 249900,
      status: OrderStatus.packed,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Stack(
          // The cards and their shadows extend past the header; nothing may
          // be trimmed.
          clipBehavior: Clip.none,
          children: [
            // First child paints underneath.
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: DashboardHeader(height: DashboardScreen.headerHeight),
            ),
            // Unpositioned, so this is what gives the Stack its height — the
            // offset is real layout, not a paint-time translation, and the
            // scroll extent covers everything below.
            Padding(
              padding: const EdgeInsets.only(top: DashboardScreen.gridTop),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatGrid(),
                  SizedBox(height: AppSpacing.x6),
                  BrandMonogram(),
                  // Wider than the gap above it — the design lets the
                  // monogram breathe before the list starts.
                  SizedBox(height: AppSpacing.x16),
                  RecentOrdersSection(orders: _recentOrders),
                  SizedBox(height: AppSpacing.x6),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: _navIndex,
        // Tabs are inert until the router lands.
        onSelect: (index) => setState(() => _navIndex = index),
      ),
    );
  }
}
