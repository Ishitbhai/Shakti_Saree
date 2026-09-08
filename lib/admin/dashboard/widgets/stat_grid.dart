import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../dashboard_stats.dart';
import 'brand_plate.dart';
import 'stat_card.dart';

/// The 2x2 block of KPI tiles under the header.
///
/// Built from [Row] + [Expanded] rather than a [GridView] so each tile sizes
/// to its own content; [IntrinsicHeight] then squares up the pair in a row.
///
/// The figures are given, not declared here — they are counted from what the
/// app holds, so the tiles cannot go on claiming a number after the thing
/// they were counting has changed.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.stats});

  final DashboardStats stats;

  static const double _gutter = AppSpacing.x3;
  static const double _rowGap = AppSpacing.x3;
  static const double _screenPadding = AppSpacing.x5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _screenPadding),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.receipt_long,
                    value: stats.totalOrders,
                    label: 'Total Orders',
                  ),
                ),
                const SizedBox(width: _gutter),
                const Expanded(child: BrandPlate()),
              ],
            ),
          ),
          const SizedBox(height: _rowGap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.inventory_2,
                    value: stats.products,
                    label: 'Products',
                    iconBackground: AppColors.infoBg,
                    iconColor: AppColors.info,
                  ),
                ),
                const SizedBox(width: _gutter),
                Expanded(
                  child: StatCard(
                    icon: Icons.group,
                    value: stats.customers,
                    label: 'Customers',
                    iconBackground: AppColors.warningBg,
                    iconColor: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
