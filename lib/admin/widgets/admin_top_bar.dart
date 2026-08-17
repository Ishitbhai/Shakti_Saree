import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Header strip above the active admin screen.
class AdminTopBar extends StatelessWidget {
  const AdminTopBar({
    super.key,
    required this.title,
    required this.showMenuButton,
  });

  final String title;
  final bool showMenuButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
              'A',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
