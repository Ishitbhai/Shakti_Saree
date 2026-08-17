import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/stat_grid.dart';

/// First assembly of the admin dashboard: header with the stat grid riding up
/// over its rounded bottom edge.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// How far the grid is lifted into the header.
  static const double _overlap = 56;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DashboardHeader(),
            // Transform paints the lift without changing layout, so the
            // scroll extent stays correct and nothing is clipped — a Stack
            // would have to size itself to the header and let the grid spill
            // over whatever follows.
            //
            // Everything below the header belongs inside this one Transform:
            // the lift is then applied once, so later sections cannot
            // double-space. The _overlap of slack it leaves at the very
            // bottom serves as the screen's bottom padding.
            Transform.translate(
              offset: const Offset(0, -_overlap),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatGrid(),
                  // Phase 4+ sections go here.
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
