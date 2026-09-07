import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onTap;

  const AppBottomNavBar({super.key, required this.selectedIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.muted, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(index: 0, label: 'Home', icon: Icons.home_outlined),
          _buildNavItem(
            index: 1,
            label: 'Category',
            icon: Icons.grid_view_outlined,
          ),
          _buildNavItem(
            index: 2,
            label: 'Cart',
            icon: Icons.shopping_bag_outlined,
          ),
          _buildNavItem(index: 3, label: 'Orders', icon: Icons.view_in_ar),
          _buildNavItem(index: 4, label: 'Profile', icon: Icons.person_outline),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = selectedIndex == index;
    final Color itemColor = isSelected ? AppColors.primary : AppColors.muted;

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: itemColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: itemColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
