import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../shared/models/order.dart';
import '../shared/widgets/async_content.dart';
import 'dashboard_repository.dart';
import 'widgets/brand_monogram.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/recent_orders_section.dart';
import 'widgets/stat_grid.dart';

/// The admin dashboard: header, stat grid, brand monogram and recent orders.
///
/// The bottom bar belongs to the shell that hosts this tab, not here.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.repository});

  /// Injectable so tests can supply their own orders or a failing source.
  final DashboardRepository? repository;

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
  late final DashboardRepository _repository =
      widget.repository ?? const InMemoryDashboardRepository();

  List<Order>? _recentOrders;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await _repository.fetchRecentOrders();
      if (!mounted) return;
      setState(() {
        _recentOrders = orders;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

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
                    value: _recentOrders,
                    error: _error,
                    onRetry: _load,
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
