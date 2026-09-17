import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'my_orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      // Title
                      Text(
                        'My Profile',
                        style: AppTextStyles.pageTitle.copyWith(
                          color: AppColors.white,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Avatar circle with "IV"
                      Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'IV',
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
                        'iv',
                        style: AppTextStyles.pageTitle.copyWith(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Contact row
                      Text(
                        'ishit@gmail.com • +91 12345 67890',
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

            // ================= STATS ROW (NO BOXES) =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '12',
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

                  // Center vertical divider
                  Container(
                    width: 1,
                    height: 38,
                    color: AppColors.muted.withOpacity(0.5),
                  ),

                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '08',
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
                        // Will link to EditProfileScreen
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyOrdersScreen(),
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
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'FAQ',
                      onTap: () {
                        // Will link to HelpAndSupportScreen
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            // ================= FILLED LOGOUT BUTTON =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
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

      // ================= BOTTOM NAVIGATION =================
      bottomNavigationBar: const AppBottomNavBar(selectedIndex: 4),
    );
  }

  // ================= HELPER WIDGET =================
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
