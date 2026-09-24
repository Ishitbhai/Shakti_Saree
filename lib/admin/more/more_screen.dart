import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../mock/category_store.dart';
import '../../mock/faq_store.dart';
import '../../mock/order_store.dart';
import '../../mock/product_store.dart';
import '../../mock/profile_store.dart';
import '../categories/categories_screen.dart';
import '../shared/admin_tab.dart';
import '../shared/widgets/brand_monogram.dart';
import '../support/help_support_screen.dart';
import 'edit_profile_screen.dart';
import 'widgets/menu_section.dart';
import 'widgets/more_header.dart';

/// The More tab: who is signed in, where the rest of the admin lives, and the
/// way out.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static const double _screenPadding = AppSpacing.x5;

  /// Shown under the logout button.
  static const String version = 'v1.0.0';

  void _back(BuildContext context, WidgetRef ref) {
    if (Navigator.canPop(context)) {
      Navigator.maybePop(context);
      return;
    }
    ref.read(adminTabProvider.notifier).back();
  }

  /// Signs out by throwing away the session.
  ///
  /// There is no sign-in to return to, and nothing is stored anywhere but in
  /// memory — so the session *is* the stores, and discarding them is
  /// the honest meaning of logging out here. Everything returns to the seed
  /// data, exactly as a restart would leave it.
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: Text(
          'There is no sign-in yet, so this clears everything back to the '
          'sample data — the same as restarting the app.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    ref
      ..invalidate(orderStoreProvider)
      ..invalidate(productStoreProvider)
      ..invalidate(categoryStoreProvider)
      ..invalidate(profileStoreProvider)
      ..invalidate(faqStoreProvider)
      ..read(adminTabProvider.notifier).select(AdminTab.home);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Back to the sample data')));
  }

  /// Says plainly that a screen has not been built rather than doing nothing.
  void _notBuilt(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what has not been built yet')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileStoreProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MoreHeader(profile: profile, onBack: () => _back(context, ref)),
            const SizedBox(height: AppSpacing.x6),
            BrandMonogram(initials: profile.initials),
            const SizedBox(height: AppSpacing.x8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MenuSection(
                    caption: 'STORE',
                    entries: [
                      MenuEntry(
                        icon: Icons.settings_outlined,
                        title: 'Admin Edit Profile',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                      ),
                      MenuEntry(
                        icon: Icons.people_outline,
                        title: 'Staff & Roles',
                        onTap: () => _notBuilt(context, 'Staff & Roles'),
                      ),
                      // Not on the settings mock, but the categories screen
                      // is reached from this tab and would otherwise have no
                      // way in at all.
                      MenuEntry(
                        icon: Icons.category_outlined,
                        title: 'Manage Categories',
                        subtitle: 'Groupings in the catalogue',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CategoriesScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  MenuSection(
                    caption: 'SYSTEM',
                    entries: [
                      MenuEntry(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Guides for managing your panel',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const HelpSupportScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x8),
                  FilledButton.icon(
                    onPressed: () => _logout(context, ref),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Logout'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.errorBg,
                      foregroundColor: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Text(
                    'Shakti Saree Admin • $version',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption,
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
