import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../user/screens/login_screen.dart';
import '../styles/app_colors.dart';
import '../styles/app_spacing.dart';
import '../styles/app_typography.dart';
import '../data/mock/category_store.dart';
import '../data/mock/faq_store.dart';
import '../data/mock/order_store.dart';
import '../data/mock/product_store.dart';
import '../data/mock/profile_store.dart';
import 'categories_screen.dart';
import '../data/admin_tab.dart';
import '../widgets/common/brand_monogram.dart';
import 'help_support_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/more/menu_section.dart';
import '../widgets/more/more_header.dart';

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

  /// Invalidates stores and redirects immediately to LoginScreen without a confirmation dialog.
  void _logout(BuildContext context, WidgetRef ref) {
    ref
      ..invalidate(orderStoreProvider)
      ..invalidate(productStoreProvider)
      ..invalidate(categoryStoreProvider)
      ..invalidate(profileStoreProvider)
      ..invalidate(faqStoreProvider)
      ..read(adminTabProvider.notifier).select(AdminTab.home);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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
