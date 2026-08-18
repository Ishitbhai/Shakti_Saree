import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/stat_grid.dart';

/// First assembly of the admin dashboard: header with the stat grid hanging
/// past its rounded bottom edge.
class DashboardScreen extends StatelessWidget {
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
  static const double _gridTop = headerHeight - cardOverlap;

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
              child: DashboardHeader(height: headerHeight),
            ),
            // Unpositioned, so this is what gives the Stack its height — the
            // offset is real layout, not a paint-time translation, and the
            // scroll extent covers the grid.
            Padding(
              padding: const EdgeInsets.only(top: _gridTop),
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
