import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';

/// Overflow tab holding everything that does not earn a bottom bar slot.
///
/// Entries push a full page with its own back button rather than swapping the
/// tab body, so the phone's back gesture returns here as expected.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _MoreTile(
          icon: Icons.category_outlined,
          label: 'Categories',
          onTap: () => _open(context, const CategoriesScreen()),
        ),
        _MoreTile(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () => _open(context, const SettingsScreen()),
        ),
        const Divider(height: 24),
        _MoreTile(
          icon: Icons.logout,
          label: 'Logout',
          // Wired up once the auth flow exists.
          onTap: () {},
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
