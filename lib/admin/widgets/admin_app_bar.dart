import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// App bar shared by the admin tab screens.
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: const Text(
              'A',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
