import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Stand-in body for an admin screen whose design has not been supplied yet.
///
/// Replace the whole widget when the real layout is built — it is scaffolding,
/// not a reusable empty state.
class PagePlaceholder extends StatelessWidget {
  const PagePlaceholder({super.key, required this.title, required this.note});

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.design_services_outlined,
              size: 44,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              note,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
