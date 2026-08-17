import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/stat_grid.dart';

/// First assembly of the admin dashboard: header with the stat grid riding up
/// over its rounded bottom edge.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
            // double-space. The slack it leaves at the very bottom serves as
            // the screen's bottom padding.
            //
            // The offset lives on DashboardHeader because the header sizes
            // its own bottom padding from it; duplicating the number here
            // would let the two drift apart.
            Transform.translate(
              offset: const Offset(0, -DashboardHeader.cardOverlap),
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
