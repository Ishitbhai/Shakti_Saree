import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'MainNavigationScreen.dart';

import '../../admin/data/firestore/firestore_schema.dart';
import '../data/shop_providers.dart';
import '../models/shop_models.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'edit_profile_screen.dart';
import 'help_and_support_screen.dart';
import 'login_screen.dart';
// import 'my_orders_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'IV';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(customerProfileProvider);
    final orderCountAsync = ref.watch(customerOrderCountProvider);
    // Watch cart to obtain the list of distinct product items
    final cartAsync = ref.watch(cartProvider);

    final profile = profileAsync.value ?? <String, dynamic>{};
    final String name = Fs.stringOf(profile[Fs.name]).isEmpty
        ? 'Customer'
        : Fs.stringOf(profile[Fs.name]);
    final String email = Fs.stringOf(profile[Fs.email]).isEmpty
        ? 'No email registered'
        : Fs.stringOf(profile[Fs.email]);
    final String phone = Fs.stringOf(profile[Fs.phone]).isEmpty
        ? 'No mobile registered'
        : Fs.stringOf(profile[Fs.phone]);
    final String initials = _getInitials(name);
    final int ordersCount = orderCountAsync.value ?? 0;

    // Distinct product count in cart (e.g. 2 items with quantities 2 & 4 results in 2)
    final cartList = cartAsync.value ?? <CartEntry>[];
    final int distinctProductsCount = cartList.length;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= FULL-WIDTH MAROON HEADER =================
            Container(
              width: double.infinity,
              color: AppColors.primary,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: Column(
                    children: [
                      Text(
                        'My Profile',
                        style: AppTextStyles.pageTitle.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Avatar circle with Initials
                      Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: AppTextStyles.pageTitle.copyWith(
                              color: AppColors.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Username
                      Text(
                        name,
                        style: AppTextStyles.pageTitle.copyWith(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Contact row
                      Text(
                        '$email • $phone',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ================= STATS ROW =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          ordersCount.toString().padLeft(2, '0'),
                          style: GoogleFonts.lora(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Orders',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 38,
                    color: AppColors.muted.withOpacity(0.5),
                  ),

                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          distinctProductsCount.toString().padLeft(2, '0'),
                          style: GoogleFonts.lora(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Wishlist',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ================= MENU OPTIONS CARD =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.black.withOpacity(0.7),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      subtitle: 'Profile Saved',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfileScreen(initialData: profile),
                          ),
                        );
                      },
                    ),
                    Divider(
                      color: AppColors.muted.withOpacity(0.35),
                      height: 1,
                      indent: 75,
                      endIndent: 25,
                    ),
                    _buildMenuItem(
                      icon: Icons.view_in_ar,
                      title: 'My Orders',
                      subtitle: 'Track orders',
                      onTap: () {
                        final tabController = DefaultTabController.maybeOf(
                          context,
                        );
                        if (tabController != null) {
                          // Switch directly to the Orders tab (Tab index 3)
                          tabController.animateTo(3);
                        } else {
                          // Fallback if opened outside of MainNavigationScreen
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MainNavigationScreen(initialIndex: 3),
                            ),
                            (route) => false,
                          );
                        }
                      },
                    ),
                    Divider(
                      color: AppColors.muted.withOpacity(0.35),
                      height: 1,
                      indent: 75,
                      endIndent: 25,
                    ),
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'FAQ, chat, call',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpAndSupportScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            // ================= LOGOUT BUTTON =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final authRepo = ref.read(customerAuthRepositoryProvider);
                    if (authRepo != null) {
                      await authRepo.signOut();
                    }
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.pink,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.primary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.pink,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: AppTextStyles.body.copyWith(fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.muted,
          fontSize: 11,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.muted,
        size: 20,
      ),
    );
  }
}
