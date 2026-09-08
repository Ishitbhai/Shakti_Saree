import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../shared/models/order.dart';
import '../shared/widgets/async_content.dart';
import 'dashboard_providers.dart';
import 'widgets/brand_monogram.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/recent_orders_section.dart';
import 'widgets/stat_grid.dart';

/// The admin dashboard: header, stat grid, brand monogram and recent orders.
///
/// The bottom bar belongs to the shell that hosts this tab, not here.
class DashboardScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final recentOrders = ref.watch(recentOrdersProvider);

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
              child: DashboardHeader(height: headerHeight),
            ),
            // Unpositioned, so this is what gives the Stack its height — the
            // offset is real layout, not a paint-time translation, and the
            // scroll extent covers everything below.
            Padding(
              padding: const EdgeInsets.only(top: gridTop),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StatGrid(),
                  const SizedBox(height: AppSpacing.x6),
                  const BrandMonogram(),
                  // Wider than the gap above it — the design lets the
                  // monogram breathe before the list starts.
                  const SizedBox(height: AppSpacing.x16),
                  AsyncContent<List<Order>>(
                    state: recentOrders,
                    onRetry: () => ref.invalidate(recentOrdersProvider),
                    isEmpty: (loaded) => loaded.isEmpty,
                    emptyMessage: 'No recent orders.',
                    builder: (context, loaded) =>
                        RecentOrdersSection(orders: loaded),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
