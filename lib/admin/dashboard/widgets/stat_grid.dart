import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'brand_plate.dart';
import 'stat_card.dart';

/// The 2x2 block of KPI tiles under the header.
///
/// Built from [Row] + [Expanded] rather than a [GridView] so each tile sizes
/// to its own content; [IntrinsicHeight] then squares up the pair in a row.
///
/// Values are hardcoded until the repository lands in Phase 6.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key});

  static const double _gutter = AppSpacing.x3;
  static const double _rowGap = AppSpacing.x3;
  static const double _screenPadding = AppSpacing.x5;

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: _screenPadding),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.receipt_long,
                    value: 1248,
                    label: 'Total Orders',
                  ),
                ),
                SizedBox(width: _gutter),
                Expanded(child: BrandPlate()),
              ],
            ),
          ),
          SizedBox(height: _rowGap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.inventory_2,
                    value: 320,
                    label: 'Products',
                    iconBackground: AppColors.infoBg,
                    iconColor: AppColors.info,
                  ),
                ),
                SizedBox(width: _gutter),
                Expanded(
                  child: StatCard(
                    icon: Icons.group,
                    value: 2150,
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
